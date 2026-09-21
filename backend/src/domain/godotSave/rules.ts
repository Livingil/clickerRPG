import type { GodotSave } from "./types.js";
import { intValue } from "./value.js";

export const equipmentIds = ["weapon", "helm", "chest", "gloves", "boots", "ring", "amulet", "relic"] as const;
export const artifactIds = [
  "ember_heart", "crystal_lung", "warhorn_shard", "stone_eye", "storm_compass", "iron_leaf", "moon_pin",
  "glass_tooth", "sun_thread", "warden_coin", "ashen_tome", "tide_knot", "gale_lock", "thunder_nail",
  "cinder_seal", "deep_scale", "oak_charm", "spark_relic", "frost_sigil", "void_feather", "hourglass_core",
  "king_mint", "echo_lantern", "essence_vial", "guardian_oath", "execution_mark", "school_prism", "merchant_seal"
] as const;
export const schoolIds = ["fire", "water", "earth", "air", "lightning"] as const;
export const prestigeUpgradeIds = ["attack", "hp", "defense", "crit", "school_xp", "gold", "craft"] as const;
export const schoolXpThresholds = [20, 200, 1000, 3000, 7000, 15000, 30000, 60000, 120000, 240000] as const;
export const post10XpPerLevel = 120000;

export const skillDefs: Record<string, { school: string; unlockLevel: number }> = {
  ember_chain: { school: "fire", unlockLevel: 1 },
  cinder_burst: { school: "fire", unlockLevel: 3 },
  ash_storm: { school: "fire", unlockLevel: 5 },
  frost_orb: { school: "water", unlockLevel: 1 },
  tidal_pulse: { school: "water", unlockLevel: 3 },
  glacial_field: { school: "water", unlockLevel: 5 },
  stone_spike: { school: "earth", unlockLevel: 1 },
  quake_ring: { school: "earth", unlockLevel: 3 },
  bastion_crash: { school: "earth", unlockLevel: 5 },
  razor_gust: { school: "air", unlockLevel: 1 },
  cyclone_arc: { school: "air", unlockLevel: 3 },
  sky_flurry: { school: "air", unlockLevel: 5 },
  spark_jump: { school: "lightning", unlockLevel: 1 },
  volt_lance: { school: "lightning", unlockLevel: 3 },
  thunder_crown: { school: "lightning", unlockLevel: 5 }
};

const equipmentBaseCosts: Record<string, number> = {
  weapon: 50,
  helm: 40,
  chest: 55,
  gloves: 42,
  boots: 42,
  ring: 48,
  amulet: 50,
  relic: 60
};

export const equipmentUnlockCosts: Record<string, number> = {
  helm: 2000,
  chest: 9600,
  gloves: 32000,
  boots: 80000,
  ring: 176000,
  amulet: 360000,
  relic: 720000
};

export function equipmentUpgradeCost(equipmentId: string, level: number, discount: number) {
  const idx = equipmentIds.indexOf(equipmentId as typeof equipmentIds[number]);
  let baseCost = equipmentBaseCosts[equipmentId] ?? 50;
  if (idx > 0) baseCost = Math.max(baseCost, (equipmentUnlockCosts[equipmentId] ?? 0) * 0.3);
  const raw = progressiveCost(baseCost, Math.max(0, level));
  return Math.max(1, Math.round(raw * (1 - discount)));
}

export function artifactUpgradeCost(level: number) {
  return 35 + Math.max(0, level) * 20;
}

export function prestigeShardsForWave(highestWave: number) {
  if (highestWave < 50) return 0;
  return Math.max(1, Math.floor((highestWave - 50) / 25) + 1);
}

export function prestigeUpgradeCost(upgradeId: string, level: number) {
  return (upgradeId === "crit" || upgradeId === "craft" ? 2 : 1) + Math.max(0, level) * 2;
}

export function getSkillSlotCount(highestWave: number) {
  if (highestWave >= 40) return 4;
  if (highestWave >= 10) return 3;
  if (highestWave >= 5) return 2;
  return 1;
}

export function getSchoolCoreLevelFromXp(xp: number) {
  let level = 0;
  for (const threshold of schoolXpThresholds) {
    if (xp >= threshold) level += 1;
    else break;
  }
  return level;
}

export function getSchoolTotalLevelFromXp(xp: number) {
  const coreLevel = getSchoolCoreLevelFromXp(xp);
  if (coreLevel < 10) return coreLevel;
  return 10 + Math.floor(Math.max(0, xp - schoolXpThresholds[schoolXpThresholds.length - 1]) / post10XpPerLevel);
}

export function getEquipmentDiscount(save: GodotSave) {
  const levels = save.prestige_upgrade_levels as Record<string, number>;
  return Math.min(0.12, intValue(levels?.craft, 0) * 0.003);
}

export function getGoldMultiplier(save: GodotSave) {
  return getPrestigeStatMultiplier(save, "gold") + getArtifactBonus(save, "king_mint", 0.0008);
}

export function getEssenceMultiplier(save: GodotSave) {
  return 1 + getArtifactBonus(save, "essence_vial", 0.0007);
}

export function getEchoMultiplier(save: GodotSave) {
  return 1 + getArtifactBonus(save, "echo_lantern", 0.0007);
}

export function getSchoolXpMultiplier(save: GodotSave) {
  const totalShards = intValue(save.prestige_shards_earned_total, 0);
  const firstChunk = Math.min(Math.max(0, totalShards), 100);
  const overflow = Math.max(0, totalShards - 100);
  const shardBonus = firstChunk * 0.002 + overflow * 0.0005;
  const levels = save.prestige_upgrade_levels as Record<string, number>;
  const branchBonus = intValue(levels?.school_xp, 0) * 0.006;
  return 1 + shardBonus + branchBonus + getArtifactBonus(save, "school_prism", 0.0006);
}

function progressiveCost(baseCost: number, level: number) {
  const l0 = Math.min(level, 250);
  const l1 = Math.min(Math.max(0, level - 250), 750);
  const l2 = Math.max(0, level - 1000);
  return Math.round(baseCost * Math.pow(1.12, l0) * Math.pow(1.075, l1) * Math.pow(1.025, l2));
}

function getPrestigeStatMultiplier(save: GodotSave, upgradeId: string) {
  const levels = save.prestige_upgrade_levels as Record<string, number>;
  return 1 + intValue(levels?.[upgradeId], 0) * 0.006;
}

function getArtifactBonus(save: GodotSave, artifactId: string, coef: number) {
  const owned = save.owned_artifacts as string[];
  if (!owned?.includes(artifactId)) return 0;
  const levels = save.artifact_levels as Record<string, number>;
  return intValue(levels?.[artifactId], 0) * coef;
}
