export type SchoolId = "fire" | "water" | "earth" | "air" | "lightning";
export type EnemyKind = "normal" | "tank" | "fast" | "ranged" | "wave" | "mini" | "grand" | "apex";
export type EquipmentId = "weapon" | "helm" | "chest" | "gloves" | "boots" | "ring" | "amulet" | "relic";
export type PrestigeUpgradeId = "attack" | "hp" | "defense" | "crit" | "gold" | "school_xp" | "craft";

export interface ActiveBoost {
  id: string;
  expiresAt: string;
}

export interface PlayerState {
  gold: number;
  essence: number;
  echoCollected: number;
  echoPower: number;
  currentRunWave: number;
  highestWaveReached: number;
  totalDeaths: number;
  bestRunTimeSec: number;
  prestigeCount: number;
  prestigeShards: number;
  prestigeShardsEarnedTotal: number;
  prestigeUpgrades: Record<string, number>;
  activeSchool: SchoolId;
  schoolXp: Record<string, number>;
  equippedSkills: string[];
  equipmentLevels: Record<string, number>;
  equipmentUnlocked: Record<string, boolean>;
  artifactLevels: Record<string, number>;
  ownedArtifacts: string[];
  defeatedApexWaveRewards: number[];
  activeBoosts: ActiveBoost[];
  lastSeenAt: string;
  createdAt: string;
  updatedAt: string;
}

export interface RewardResult {
  gold: number;
  essence: number;
  echo: number;
}
