import { artifactIds, equipmentIds, prestigeUpgradeIds, schoolIds } from "./rules.js";
import type { GodotSave } from "./types.js";
import { hasValue, intValue, isRecord, numberValue } from "./value.js";

export function normalizeSave(input: GodotSave): GodotSave {
  const save = { ...input };
  save.version = Math.max(1, intValue(save.version, 1));
  save.gold = Math.max(0, intValue(save.gold, 0));
  save.essence = Math.max(0, intValue(save.essence, 0));
  save.echo_collected = Math.max(0, intValue(save.echo_collected, 0));
  save.echo_power = Math.max(0, intValue(save.echo_power, 0));
  save.current_run_wave = Math.max(1, intValue(save.current_run_wave, 1));
  save.highest_wave_reached = Math.max(intValue(save.current_run_wave, 1), intValue(save.highest_wave_reached, 1));
  save.total_deaths = Math.max(0, intValue(save.total_deaths, 0));
  save.best_run_time_sec = Math.max(0, numberValue(save.best_run_time_sec, 0));
  save.prestige_count = Math.max(0, intValue(save.prestige_count, 0));
  save.prestige_shards = Math.max(0, intValue(save.prestige_shards, 0));
  save.prestige_shards_earned_total = Math.max(intValue(save.prestige_shards, 0), intValue(save.prestige_shards_earned_total, 0));
  save.active_school = hasValue(schoolIds, String(save.active_school ?? "")) ? save.active_school : "fire";
  save.equipment_levels = normalizeNumberMap(save.equipment_levels, equipmentIds);
  save.equipment_unlocked = normalizeBoolMap(save.equipment_unlocked, equipmentIds, { weapon: true });
  save.artifact_levels = normalizeNumberMap(save.artifact_levels, artifactIds);
  save.owned_artifacts = normalizeStringList(save.owned_artifacts, artifactIds);
  save.prestige_upgrade_levels = normalizeNumberMap(save.prestige_upgrade_levels, prestigeUpgradeIds);
  save.school_mastery_xp = normalizeNumberMap(save.school_mastery_xp, schoolIds);
  save.weapon_school_upgrade_levels = normalizeNumberMap(save.weapon_school_upgrade_levels, schoolIds);
  save.pending_weapon_skill_offer_schools = normalizeStringList(save.pending_weapon_skill_offer_schools, schoolIds);
  save.active_ad_boosts = normalizeActiveAdBoosts(save.active_ad_boosts, elapsedSecSinceLastServerSave(input));
  save.server_authoritative = true;
  save.last_save_unix = Math.floor(Date.now() / 1000);
  return save;
}

export function normalizeNumberMap(source: unknown, ids: readonly string[]) {
  const out: Record<string, number> = {};
  const raw = isRecord(source) ? source : {};
  for (const id of ids) out[id] = Math.max(0, intValue(raw[id], 0));
  return out;
}

export function normalizeBoolMap(source: unknown, ids: readonly string[], defaults: Record<string, boolean>) {
  const out: Record<string, boolean> = {};
  const raw = isRecord(source) ? source : {};
  for (const id of ids) out[id] = Boolean(raw[id] ?? defaults[id] ?? false);
  return out;
}

export function normalizeStringList(source: unknown, allowed: readonly string[]) {
  if (!Array.isArray(source)) return [];
  return source.map(String).filter((value, index, self) => allowed.includes(value) && self.indexOf(value) === index);
}

export function normalizeEquippedSkills(source: unknown, allowedSlots: number) {
  const out = Array.isArray(source) ? source.map(String) : [];
  while (out.length < allowedSlots) out.push("");
  return out.slice(0, allowedSlots);
}

function normalizeActiveAdBoosts(source: unknown, elapsedSec: number) {
  const out: Record<string, number> = {};
  const raw = isRecord(source) ? source : {};
  for (const [boostId, value] of Object.entries(raw)) {
    const remaining = Math.max(0, numberValue(value, 0) - elapsedSec);
    if (remaining > 0) out[boostId] = remaining;
  }
  return out;
}

function elapsedSecSinceLastServerSave(input: GodotSave) {
  const parsed = Date.parse(String(input.server_saved_at ?? ""));
  if (!Number.isFinite(parsed)) return 0;
  return Math.max(0, Math.floor((Date.now() - parsed) / 1000));
}
