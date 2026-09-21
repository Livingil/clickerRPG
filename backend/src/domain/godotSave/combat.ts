import type { CommandPayload, GodotSave } from "./types.js";
import { isRecord, numberValue, readNumber } from "./value.js";

const HIT_CHANCE_BASE = 0.6;
const HIT_CHANCE_STAT_SCALE = 0.004;
const HIT_CHANCE_MIN = 0.15;
const HIT_CHANCE_MAX = 0.98;

export function resolveHeroAttack(save: GodotSave, payload: CommandPayload) {
  return resolveSingleHeroAttack(save, payload);
}

export function resolveHeroAttackBatch(save: GodotSave, payload: CommandPayload) {
  const hits = Array.isArray(payload.hits) ? payload.hits : [];
  return {
    success: true,
    hits: hits.map((entry, index) => ({ ...resolveSingleHeroAttack(save, isRecord(entry) ? entry : {}), index }))
  };
}

function resolveSingleHeroAttack(save: GodotSave, payload: CommandPayload) {
  const baseDamage = readNumber(payload, "damage", 0);
  const critChance = clamp(readNumber(payload, "critChance", 0), 0, 1);
  const critMultiplier = Math.max(1, readNumber(payload, "critMultiplier", 1));
  const attackerAccuracy = readNumber(payload, "accuracy", 0);
  const targetEvasion = readNumber(payload, "targetEvasion", 0);
  const targetDefense = readNumber(payload, "targetDefense", 0);
  const vulnerabilityMultiplier = Math.max(0, readNumber(payload, "vulnerabilityMultiplier", 1));
  const extraScale = Math.max(0, readNumber(payload, "extraScale", 0));
  const isBoss = Boolean(payload.isBoss);

  const hitChance = computeHitChance(attackerAccuracy, targetEvasion);
  const hit = Math.random() <= hitChance;
  const isCrit = hit && Math.random() < critChance;
  let rawDamage = baseDamage;
  if (isCrit) rawDamage *= critMultiplier;
  if (extraScale > 0) rawDamage *= 1 + extraScale;
  if (isBoss) rawDamage *= getBossDamageMultiplier(save);

  const schoolDamage = rawDamage * vulnerabilityMultiplier;
  const damageTaken = hit ? applyDefense(schoolDamage, targetDefense) : 0;

  return {
    success: true,
    hit,
    isCrit,
    hitChance,
    rawDamage,
    schoolDamage,
    damageTaken,
    masteryXp: hit ? 1 : 0
  };
}

export function resolveEnemyAttack(save: GodotSave, payload: CommandPayload) {
  const blocked = shouldBlockIncomingHit(save);
  const isBoss = Boolean(payload.isBoss);
  const rawDamage = readNumber(payload, "damage", 0) * (isBoss ? getBossIncomingDamageMultiplier(save) : 1);
  const attackerAccuracy = readNumber(payload, "accuracy", 0);
  const targetEvasion = readNumber(payload, "targetEvasion", 0);
  const targetDefense = readNumber(payload, "targetDefense", 0);
  const hitChance = blocked ? 0 : computeHitChance(attackerAccuracy, targetEvasion);
  const hit = !blocked && Math.random() <= hitChance;
  const damageTaken = hit ? applyDefense(rawDamage, targetDefense) : 0;

  return {
    success: true,
    blocked,
    hit,
    hitChance,
    rawDamage,
    damageTaken
  };
}

function computeHitChance(accuracy: number, evasion: number) {
  return clamp(HIT_CHANCE_BASE + (accuracy - evasion) * HIT_CHANCE_STAT_SCALE, HIT_CHANCE_MIN, HIT_CHANCE_MAX);
}

function applyDefense(rawDamage: number, defense: number) {
  return rawDamage * (100 / (100 + Math.max(0, defense)));
}

function getBossDamageMultiplier(save: GodotSave) {
  return 1 + artifactBonus(save, "execution_mark", 0.0008);
}

function getBossIncomingDamageMultiplier(save: GodotSave) {
  return 1 - Math.min(0.35, artifactBonus(save, "guardian_oath", 0.0007));
}

function shouldBlockIncomingHit(save: GodotSave) {
  const owned = save.owned_artifacts as string[] | undefined;
  if (!owned?.includes("guardian_oath")) return false;
  const levels = save.artifact_levels as Record<string, unknown> | undefined;
  const chance = numberValue(levels?.guardian_oath, 0) * 0.0005;
  return Math.random() < chance;
}

function artifactBonus(save: GodotSave, artifactId: string, coefficient: number) {
  const owned = save.owned_artifacts as string[] | undefined;
  if (!owned?.includes(artifactId)) return 0;
  const levels = save.artifact_levels as Record<string, unknown> | undefined;
  return numberValue(levels?.[artifactId], 0) * coefficient;
}

function clamp(value: number, min: number, max: number) {
  return Math.min(max, Math.max(min, value));
}
