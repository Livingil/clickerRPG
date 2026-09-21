import { prestigeShardsForWave, prestigeUpgradeCost, rewardForEnemy, rewardForWave, schoolXpMultiplier } from "../domain/balance.js";
import { badRequest } from "../http/errors.js";
import type { EnemyKind, PlayerState, PrestigeUpgradeId, RewardResult, SchoolId } from "../types.js";
import { grantApexArtifact } from "./economyService.js";

export function startRun(state: PlayerState): void {
  state.currentRunWave = Math.max(1, state.currentRunWave);
  state.lastSeenAt = new Date().toISOString();
}

export function completeWave(state: PlayerState, wave: number): RewardResult & { artifactGranted: string | null } {
  if (wave < 1) throw badRequest("Invalid wave");
  const rewards = rewardForWave(wave, state);
  applyRewards(state, rewards);
  state.currentRunWave = Math.max(state.currentRunWave, wave + 1);
  state.highestWaveReached = Math.max(state.highestWaveReached, wave);
  const artifactGranted = grantApexArtifact(state, wave);
  return { ...rewards, artifactGranted };
}

export function killEnemy(state: PlayerState, kind: EnemyKind, wave: number): RewardResult {
  const rewards = rewardForEnemy(kind, wave, state);
  applyRewards(state, rewards);
  return rewards;
}

export function registerDeath(state: PlayerState, runTimeSec: number): void {
  state.totalDeaths += 1;
  state.bestRunTimeSec = Math.max(state.bestRunTimeSec, runTimeSec);
  state.echoPower += state.echoCollected;
  state.echoCollected = 0;
  state.currentRunWave = 1;
}

export function activateEcho(state: PlayerState): number {
  const activated = state.echoCollected;
  state.echoPower += activated;
  state.echoCollected = 0;
  return activated;
}

export function performPrestige(state: PlayerState): number {
  const gained = prestigeShardsForWave(state.highestWaveReached);
  if (gained <= 0) throw badRequest("Prestige is not available");
  state.prestigeCount += 1;
  state.prestigeShards += gained;
  state.prestigeShardsEarnedTotal += gained;
  state.gold = 0;
  state.essence = 0;
  state.echoCollected = 0;
  state.currentRunWave = 1;
  return gained;
}

export function upgradePrestige(state: PlayerState, upgradeId: PrestigeUpgradeId): void {
  const level = state.prestigeUpgrades[upgradeId] ?? 0;
  const cost = prestigeUpgradeCost(level);
  if (state.prestigeShards < cost) throw badRequest("Not enough prestige shards");
  state.prestigeShards -= cost;
  state.prestigeUpgrades[upgradeId] = level + 1;
}

export function setActiveSchool(state: PlayerState, schoolId: SchoolId): void {
  state.activeSchool = schoolId;
}

export function addSkillUseXp(state: PlayerState, schoolId: SchoolId, skillId: string): number {
  const baseXp = skillId === "basic_attack" ? 1 : 2;
  const gained = Math.max(1, Math.round(baseXp * schoolXpMultiplier(state)));
  state.schoolXp[schoolId] = (state.schoolXp[schoolId] ?? 0) + gained;
  return gained;
}

export function equipSkill(state: PlayerState, slotIndex: number, skillId: string): void {
  if (slotIndex < 0 || slotIndex > 4) throw badRequest("Invalid slot index");
  state.equippedSkills[slotIndex] = skillId;
}

export function claimAdBoost(state: PlayerState, boostId: string): void {
  const expiresAt = new Date(Date.now() + 180_000).toISOString();
  state.activeBoosts = state.activeBoosts.filter((boost) => boost.id !== boostId);
  state.activeBoosts.push({ id: boostId, expiresAt });
}

export function claimOffline(state: PlayerState): RewardResult & { elapsedSec: number } {
  const now = Date.now();
  const lastSeen = Date.parse(state.lastSeenAt || state.updatedAt || new Date().toISOString());
  const elapsedSec = Math.max(0, Math.floor((now - lastSeen) / 1000));
  const cappedSec = Math.min(elapsedSec, 8 * 60 * 60);
  const waves = Math.max(0, cappedSec / 60) * 0.35;
  const base = rewardForWave(Math.max(1, state.highestWaveReached), state);
  const rewards = {
    gold: Math.round(base.gold * waves),
    essence: Math.round(base.essence * waves),
    echo: Math.round(base.echo * waves)
  };
  applyRewards(state, rewards);
  state.lastSeenAt = new Date(now).toISOString();
  return { ...rewards, elapsedSec };
}

function applyRewards(state: PlayerState, rewards: RewardResult): void {
  state.gold += Math.max(0, rewards.gold);
  state.essence += Math.max(0, rewards.essence);
  state.echoCollected += Math.max(0, rewards.echo);
}
