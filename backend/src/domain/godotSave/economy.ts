import { randomUUID } from "node:crypto";
import { artifactIds, artifactUpgradeCost, equipmentIds, equipmentUnlockCosts, equipmentUpgradeCost, getEchoMultiplier, getEquipmentDiscount, getEssenceMultiplier, getGoldMultiplier } from "./rules.js";
import type { GodotSave } from "./types.js";
import { intValue, isRecord, numberValue, requireId } from "./value.js";

const adBoostDurations: Record<string, number> = {
  gold_rush: 180,
  essence_surge: 180,
  battle_focus: 120,
  haste_spark: 120,
  echo_magnet: 180,
  second_wind: 0,
  game_speed: 180
};

const randomAdBoostPool = ["gold_rush", "essence_surge", "battle_focus", "haste_spark", "echo_magnet", "second_wind"] as const;
const adOfferVisibleMs = 16_600;
const adOfferCooldownMs = 180_000;

export function unlockEquipment(save: GodotSave, equipmentId: string) {
  requireId(equipmentId, equipmentIds, "equipmentId");
  if (equipmentId === "weapon") return { success: false, reason: "weapon_already_unlocked" };
  const unlocked = save.equipment_unlocked as Record<string, boolean>;
  if (unlocked[equipmentId]) return { success: false, reason: "already_unlocked" };
  const cost = Math.max(1, Math.round((equipmentUnlockCosts[equipmentId] ?? 0) * (1 - getEquipmentDiscount(save))));
  if (intValue(save.gold, 0) < cost) return { success: false, reason: "not_enough_gold", cost };
  const levels = save.equipment_levels as Record<string, number>;
  save.gold = intValue(save.gold, 0) - cost;
  unlocked[equipmentId] = true;
  levels[equipmentId] = Math.max(1, intValue(levels[equipmentId], 0));
  return { success: true, cost, level: levels[equipmentId] };
}

export function upgradeEquipment(save: GodotSave, equipmentId: string) {
  requireId(equipmentId, equipmentIds, "equipmentId");
  const unlocked = save.equipment_unlocked as Record<string, boolean>;
  if (!unlocked[equipmentId]) return { success: false, reason: "locked" };
  const levels = save.equipment_levels as Record<string, number>;
  const oldLevel = intValue(levels[equipmentId], 0);
  const cost = equipmentUpgradeCost(equipmentId, oldLevel, getEquipmentDiscount(save));
  if (intValue(save.gold, 0) < cost) return { success: false, reason: "not_enough_gold", cost };
  save.gold = intValue(save.gold, 0) - cost;
  levels[equipmentId] = oldLevel + 1;
  return { success: true, cost, oldLevel, level: levels[equipmentId] };
}

export function upgradeArtifact(save: GodotSave, artifactId: string) {
  requireId(artifactId, artifactIds, "artifactId");
  const owned = save.owned_artifacts as string[];
  if (!owned.includes(artifactId)) return { success: false, reason: "not_owned" };
  const levels = save.artifact_levels as Record<string, number>;
  const oldLevel = intValue(levels[artifactId], 0);
  const cost = artifactUpgradeCost(oldLevel);
  if (intValue(save.essence, 0) < cost) return { success: false, reason: "not_enough_essence", cost };
  save.essence = intValue(save.essence, 0) - cost;
  levels[artifactId] = oldLevel + 1;
  return { success: true, cost, oldLevel, level: levels[artifactId] };
}

export function grantApexArtifactReward(save: GodotSave, waveValue: number) {
  const wave = Math.max(1, Math.floor(waveValue));
  const defeated = Array.isArray(save.defeated_apex_wave_rewards)
    ? save.defeated_apex_wave_rewards.map((value) => intValue(value, 0))
    : [];
  if (wave % 100 !== 0 || defeated.includes(wave)) return { success: false, reason: "not_available" };
  defeated.push(wave);
  save.defeated_apex_wave_rewards = defeated;

  const owned = save.owned_artifacts as string[];
  const available = artifactIds.filter((artifactId) => !owned.includes(artifactId));
  if (available.length <= 0) return { success: true, wave, artifactGranted: false };
  const artifactId = available[Math.floor(Math.random() * available.length)];
  const levels = save.artifact_levels as Record<string, number>;
  owned.push(artifactId);
  levels[artifactId] = Math.max(1, intValue(levels[artifactId], 0));
  return {
    success: true,
    wave,
    artifactGranted: true,
    artifactId,
    artifactLevel: levels[artifactId],
    eventKey: `apex_reward_${wave}`
  };
}

export function claimRunRewards(save: GodotSave, reward: { gold: number; essence: number; echo: number }) {
  const goldGain = applyRewardMultiplier(Math.max(0, Math.round(reward.gold)), getGoldMultiplier(save), save, "gold_rush");
  const essenceGain = applyRewardMultiplier(Math.max(0, Math.round(reward.essence)), getEssenceMultiplier(save), save, "essence_surge");
  const echoGain = applyRewardMultiplier(Math.max(0, Math.round(reward.echo)), getEchoMultiplier(save), save, "echo_magnet");
  save.gold = intValue(save.gold, 0) + goldGain;
  save.essence = intValue(save.essence, 0) + essenceGain;
  save.echo_collected = intValue(save.echo_collected, 0) + echoGain;
  return { success: true, goldGain, essenceGain, echoGain };
}

export function activateAdBoost(save: GodotSave, boostId: string, durationSec: number) {
  if (!isKnownAdBoost(boostId)) return { success: false, reason: "invalid_boost" };
  const active = save.active_ad_boosts as Record<string, number>;
  active[boostId] = Math.max(numberValue(active[boostId], 0), durationSec);
  return { success: true, boostId, durationSec };
}

export function requestAdBoostOffer(save: GodotSave) {
  const now = Date.now();
  const existing = readPendingAdOffer(save);
  if (existing && existing.expiresAtMs > now) return { success: true, offer: publicAdOffer(existing, now) };
  const cooldownUntilMs = numberValue(save.server_next_ad_offer_at_ms, 0);
  if (cooldownUntilMs > now) return { success: false, reason: "cooldown", cooldownMs: cooldownUntilMs - now };

  const boostId = randomAdBoostPool[Math.floor(Math.random() * randomAdBoostPool.length)];
  const offer = {
    id: randomUUID(),
    boostId,
    expiresAtMs: now + adOfferVisibleMs
  };
  save.pending_ad_boost_offer = offer;
  return { success: true, offer: publicAdOffer(offer, now) };
}

export function activateOfferedAdBoost(save: GodotSave, offerId: string, fallbackBoostId = "") {
  const now = Date.now();
  const offer = readPendingAdOffer(save);
  if (offer) {
    if (offer.id !== offerId) return { success: false, reason: "offer_mismatch" };
    if (offer.expiresAtMs < now) return { success: false, reason: "offer_expired" };
    save.pending_ad_boost_offer = {};
    save.server_next_ad_offer_at_ms = now + adOfferCooldownMs;
    return activateAdBoost(save, offer.boostId, adBoostDurations[offer.boostId] ?? 0);
  }

  // Transitional path for the current Godot HUD. Still server-limited and allow-listed.
  if (!isKnownAdBoost(fallbackBoostId)) return { success: false, reason: "missing_offer" };
  const cooldownUntilMs = numberValue(save.server_next_ad_offer_at_ms, 0);
  if (cooldownUntilMs > now) return { success: false, reason: "cooldown", cooldownMs: cooldownUntilMs - now };
  save.server_next_ad_offer_at_ms = now + adOfferCooldownMs;
  return activateAdBoost(save, fallbackBoostId, adBoostDurations[fallbackBoostId] ?? 0);
}

export function activateSpeedAdBoost(save: GodotSave) {
  const now = Date.now();
  const key = "server_next_speed_ad_at_ms";
  const cooldownUntilMs = numberValue(save[key], 0);
  if (cooldownUntilMs > now) return { success: false, reason: "cooldown", cooldownMs: cooldownUntilMs - now };
  save[key] = now + adOfferCooldownMs;
  return activateAdBoost(save, "game_speed", adBoostDurations.game_speed);
}

function applyRewardMultiplier(baseValue: number, economyMultiplier: number, save: GodotSave, adBoostId: string) {
  let value = Math.max(0, Math.round(baseValue * economyMultiplier));
  const activeBoosts = save.active_ad_boosts as Record<string, number>;
  if (numberValue(activeBoosts[adBoostId], 0) > 0) value *= 2;
  return value;
}

function isKnownAdBoost(boostId: string) {
  return Object.hasOwn(adBoostDurations, boostId);
}

function readPendingAdOffer(save: GodotSave) {
  const raw = save.pending_ad_boost_offer;
  if (!isRecord(raw)) return null;
  const id = String(raw.id ?? "");
  const boostId = String(raw.boostId ?? "");
  const expiresAtMs = numberValue(raw.expiresAtMs, 0);
  if (!id || !isKnownAdBoost(boostId) || expiresAtMs <= 0) return null;
  return { id, boostId, expiresAtMs };
}

function publicAdOffer(offer: { id: string; boostId: string; expiresAtMs: number }, now: number) {
  return {
    offerId: offer.id,
    id: offer.boostId,
    time_left: Math.max(0, (offer.expiresAtMs - now) / 1000),
    duration: adBoostDurations[offer.boostId] ?? 0
  };
}
