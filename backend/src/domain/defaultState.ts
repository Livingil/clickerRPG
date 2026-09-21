import { artifactIds, equipmentIds, prestigeUpgradeIds, schools } from "./balance.js";
import type { PlayerState } from "../types.js";

export function createDefaultState(now = new Date()): PlayerState {
  const equipmentLevels = Object.fromEntries(equipmentIds.map((id) => [id, 0]));
  const equipmentUnlocked = Object.fromEntries(equipmentIds.map((id) => [id, id === "weapon"]));
  return {
    gold: 0,
    essence: 0,
    echoCollected: 0,
    echoPower: 0,
    currentRunWave: 1,
    highestWaveReached: 1,
    totalDeaths: 0,
    bestRunTimeSec: 0,
    prestigeCount: 0,
    prestigeShards: 0,
    prestigeShardsEarnedTotal: 0,
    prestigeUpgrades: Object.fromEntries(prestigeUpgradeIds.map((id) => [id, 0])),
    activeSchool: "fire",
    schoolXp: Object.fromEntries(schools.map((id) => [id, 0])),
    equippedSkills: [],
    equipmentLevels,
    equipmentUnlocked,
    artifactLevels: Object.fromEntries(artifactIds.map((id) => [id, 0])),
    ownedArtifacts: [],
    defeatedApexWaveRewards: [],
    activeBoosts: [],
    lastSeenAt: now.toISOString(),
    createdAt: now.toISOString(),
    updatedAt: now.toISOString()
  };
}
