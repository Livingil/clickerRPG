import type { EnemyKind, EquipmentId, PlayerState, PrestigeUpgradeId, RewardResult, SchoolId } from "../types.js";

export const schools: SchoolId[] = ["fire", "water", "earth", "air", "lightning"];
export const equipmentIds: EquipmentId[] = ["weapon", "helm", "chest", "gloves", "boots", "ring", "amulet", "relic"];
export const artifactIds = [
  "ember_heart", "crystal_lung", "warhorn_shard", "stone_eye", "storm_compass", "moon_pin", "glass_tooth",
  "sun_thread", "warden_coin", "ashen_tome", "tide_knot", "gale_lock", "thunder_nail", "cinder_seal",
  "deep_scale", "oak_charm", "spark_relic", "frost_sigil", "void_feather", "hourglass_core", "king_mint",
  "echo_lantern", "essence_vial", "guardian_oath", "execution_mark", "school_prism", "merchant_seal"
];
export const prestigeUpgradeIds: PrestigeUpgradeId[] = ["attack", "hp", "defense", "crit", "gold", "school_xp", "craft"];

export function equipmentUnlockCost(id: EquipmentId): number {
  const order = equipmentIds.indexOf(id);
  return order <= 0 ? 0 : Math.round(1600 * Math.pow(2.65, order - 1));
}

export function equipmentUpgradeCost(level: number, discount: number): number {
  const raw = 12 * Math.pow(1.135, Math.max(0, level));
  return Math.max(1, Math.round(raw * Math.max(0.05, 1 - discount)));
}

export function artifactUpgradeCost(level: number): number {
  return Math.max(1, Math.round(45 * Math.pow(1.18, Math.max(0, level))));
}

export function prestigeShardsForWave(wave: number): number {
  if (wave < 50) return 0;
  return Math.max(1, Math.floor(Math.pow((wave - 40) / 20, 1.16)));
}

export function prestigeUpgradeCost(level: number): number {
  return Math.max(1, 1 + level * 2);
}

export function prestigeMultiplier(state: PlayerState, id: PrestigeUpgradeId): number {
  const level = state.prestigeUpgrades[id] ?? 0;
  if (id === "crit") return level * 0.0015;
  if (id === "craft") return Math.min(0.7, level * 0.003);
  return 1 + level * 0.006;
}

export function schoolXpMultiplier(state: PlayerState): number {
  return 1 + Math.sqrt(Math.max(0, state.prestigeShardsEarnedTotal)) * 0.01 + ((state.prestigeUpgrades.school_xp ?? 0) * 0.006);
}

export function rewardForEnemy(kind: EnemyKind, wave: number, state: PlayerState): RewardResult {
  const waveMult = Math.pow(1.045, Math.max(0, wave - 1));
  const kindMult = enemyRewardMultiplier(kind);
  const goldMult = prestigeMultiplier(state, "gold");
  return {
    gold: Math.max(1, Math.round(4 * waveMult * kindMult * goldMult)),
    essence: Math.max(1, Math.round(2 * waveMult * kindMult)),
    echo: Math.max(1, Math.round(Math.pow(waveMult, 0.72) * kindMult * 0.42))
  };
}

export function rewardForWave(wave: number, state: PlayerState): RewardResult {
  const normalCount = normalEnemyCountForWave(wave);
  const bossKind = bossKindForWave(wave);
  const normal = rewardForEnemy("normal", wave, state);
  const total = {
    gold: normal.gold * normalCount,
    essence: normal.essence * normalCount,
    echo: normal.echo * normalCount
  };
  if (bossKind) {
    const boss = rewardForEnemy(bossKind, wave, state);
    total.gold += boss.gold;
    total.essence += boss.essence;
    total.echo += boss.echo;
  }
  return total;
}

export function normalEnemyCountForWave(wave: number): number {
  return Math.max(3, 3 + Math.floor(Math.max(0, wave - 1) / 4));
}

function bossKindForWave(wave: number): EnemyKind | null {
  if (wave % 100 === 0) return "apex";
  if (wave % 10 === 0) return "grand";
  if (wave % 5 === 0) return "mini";
  return null;
}

function enemyRewardMultiplier(kind: EnemyKind): number {
  if (kind === "apex") return 9;
  if (kind === "grand") return 5.5;
  if (kind === "mini") return 3.2;
  if (kind === "wave") return 1.6;
  if (kind === "tank") return 1.35;
  if (kind === "ranged") return 1.25;
  if (kind === "fast") return 1.15;
  return 1;
}
