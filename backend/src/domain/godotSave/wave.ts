import type { GodotSave } from "./types.js";
import { intValue } from "./value.js";
import { buildEnemyConfig } from "./enemyPlan.js";
import { claimRunRewards, grantApexArtifactReward } from "./economy.js";
import { echoGainForEnemy } from "./rewardRules.js";
import { randomUUID } from "node:crypto";

const baseNormalEnemiesPerWave = 4;
const normalEnemyWaveGrowth = 0.58;
const monoWaveChance = 0.10;

export function startWave(save: GodotSave, waveValue: number, options: { includeMilestone?: boolean } = {}) {
  const wave = Math.max(1, Math.floor(waveValue));
  const currentWave = intValue(save.current_run_wave, 1);
  const highestWave = intValue(save.highest_wave_reached, 1);
  const maxAllowedWave = Math.max(currentWave, highestWave + 1);
  if (wave > maxAllowedWave) return { success: false, reason: "wave_jump_rejected", maxAllowedWave };

  save.current_run_wave = wave;
  const monoType = rollMonoNormalEnemyType(wave);
  const normalCount = normalEnemyCountForWave(wave);
  const session = createWaveSession(save, wave);
  const normalEnemies = buildNormalEnemyPlan(wave, normalCount, monoType, session);
  const bosses = buildBossPlan(wave, session, options.includeMilestone ?? true);
  save.active_wave_session = session;
  return {
    success: true,
    waveSessionId: session.id,
    wave,
    highestWave: save.highest_wave_reached,
    plan: {
      normalCount,
      monoType,
      normalEnemies,
      bosses
    }
  };
}

export function completeWave(save: GodotSave, waveValue: number, waveSessionId = "") {
  const session = readActiveWaveSession(save);
  if (!session) return { success: false, reason: "missing_wave_session" };
  const wave = Math.max(1, Math.floor(waveValue));
  if (session.wave !== wave || intValue(save.current_run_wave, 1) !== wave) {
    return { success: false, reason: "wave_mismatch", currentWave: save.current_run_wave, sessionWave: session.wave };
  }
  if (waveSessionId && session.id !== waveSessionId) return { success: false, reason: "wave_session_mismatch" };

  const missingEnemyIds = session.requiredEnemyIds.filter((enemyId) => !session.enemyRewards[enemyId]?.claimed);
  if (missingEnemyIds.length > 0) {
    return { success: false, reason: "wave_not_cleared", missingCount: missingEnemyIds.length };
  }
  const clearTiming = validateWaveClearTiming(session);
  if (!clearTiming.success) return clearTiming;

  const nextWave = wave + 1;
  save.current_run_wave = nextWave;
  save.highest_wave_reached = Math.max(intValue(save.highest_wave_reached, 1), nextWave);
  save.active_wave_session = { ...session, completedAt: new Date().toISOString() };
  return { success: true, wave, nextWave, highestWave: save.highest_wave_reached };
}

export function claimEnemyKill(save: GodotSave, enemyInstanceId: string) {
  const session = readActiveWaveSession(save);
  if (!session) return { success: false, reason: "missing_wave_session" };
  const reward = session.enemyRewards[enemyInstanceId];
  if (!reward) return { success: false, reason: "unknown_enemy" };
  if (reward.claimed) return { success: true, duplicate: true, goldGain: 0, essenceGain: 0, echoGain: 0 };
  const speedCheck = validateKillTiming(session, reward);
  if (!speedCheck.success) return speedCheck;

  reward.claimed = true;
  session.claimedCount = intValue(session.claimedCount, 0) + 1;
  const result = claimRunRewards(save, {
    gold: reward.gold,
    essence: reward.essence,
    echo: reward.echo
  });
  const artifactReward = reward.bossKind === "apex" ? grantApexArtifactReward(save, session.wave) : null;
  return { ...result, enemyInstanceId, wave: session.wave, bossKind: reward.bossKind, artifactReward };
}

export function claimEnemyKillBatch(save: GodotSave, enemyInstanceIds: unknown) {
  if (!Array.isArray(enemyInstanceIds)) return { success: false, reason: "invalid_batch" };
  const results = [];
  let goldGain = 0;
  let essenceGain = 0;
  let echoGain = 0;
  let requiresFullSync = false;
  let retryable = false;
  for (const rawId of enemyInstanceIds.slice(0, 200)) {
    const result = claimEnemyKill(save, String(rawId));
    results.push(result);
    if (result.success) {
      const successResult = result as Record<string, unknown>;
      goldGain += intValue(successResult.goldGain, 0);
      essenceGain += intValue(successResult.essenceGain, 0);
      echoGain += intValue(successResult.echoGain, 0);
      requiresFullSync = requiresFullSync || Boolean(successResult.artifactReward);
    } else if (result.reason === "kill_too_fast") {
      retryable = true;
    }
  }
  return {
    success: results.every((result) => Boolean(result.success)),
    retryable,
    goldGain,
    essenceGain,
    echoGain,
    requiresFullSync,
    results
  };
}

function normalEnemyCountForWave(wave: number) {
  return baseNormalEnemiesPerWave + Math.floor(Math.max(0, wave - 1) * normalEnemyWaveGrowth);
}

function rollMonoNormalEnemyType(wave: number) {
  const available = getAvailableNormalEnemyTypes(wave);
  if (available.length < 2 || Math.random() >= monoWaveChance) return "";
  return available[Math.floor(Math.random() * available.length)];
}

function buildNormalEnemyPlan(wave: number, count: number, monoType: string, session: WaveSession) {
  const out = [];
  for (let i = 0; i < count; i += 1) {
    const normalType = monoType || rollWeightedNormalEnemyType(wave);
    out.push(registerPlannedEnemy(session, buildEnemyConfig("normal", wave, normalType)));
  }
  return out;
}

function buildBossPlan(wave: number, session: WaveSession, includeMilestone: boolean) {
  const bosses: Record<string, ReturnType<typeof buildEnemyConfig>> = {
    wave_boss: registerPlannedEnemy(session, buildEnemyConfig("wave_boss", wave), true)
  };
  if (!includeMilestone) return bosses;
  if (wave % 100 === 0) bosses.apex_boss = registerPlannedEnemy(session, buildEnemyConfig("apex_boss", wave), true);
  else if (wave % 10 === 0) bosses.grand_boss = registerPlannedEnemy(session, buildEnemyConfig("grand_boss", wave), true);
  else if (wave % 5 === 0) bosses.mini_boss = registerPlannedEnemy(session, buildEnemyConfig("mini_boss", wave), true);
  return bosses;
}

function createWaveSession(save: GodotSave, wave: number): WaveSession {
  const estimatedPlayerDps = estimatePlayerDps(save);
  return {
    id: randomUUID(),
    wave,
    startedAt: new Date().toISOString(),
    claimedCount: 0,
    minClearSec: estimateMinimumClearSecForHp(0, estimatedPlayerDps),
    totalRequiredHp: 0,
    estimatedPlayerDps,
    requiredEnemyIds: [],
    enemyRewards: {}
  };
}

function registerPlannedEnemy(session: WaveSession, config: ReturnType<typeof buildEnemyConfig>, requiredForCompletion = true) {
  const instanceId = randomUUID();
  const plannedConfig = { ...config, instanceId };
  const bossKind = String(plannedConfig.bossKind ?? "none");
  session.enemyRewards[instanceId] = {
    gold: Math.max(0, Math.round(Number(plannedConfig.rewardGold) || 0)),
    essence: Math.max(0, Math.round(Number(plannedConfig.rewardEssence) || 0)),
    echo: echoGainForEnemy(bossKind, session.wave),
    hp: Math.max(0, Number(plannedConfig.maxHp) || 0),
    bossKind,
    claimed: false
  };
  if (requiredForCompletion) {
    session.requiredEnemyIds.push(instanceId);
    session.totalRequiredHp = Math.max(0, session.totalRequiredHp) + Math.max(0, Number(plannedConfig.maxHp) || 0);
    session.minClearSec = estimateMinimumClearSecForHp(session.totalRequiredHp, session.estimatedPlayerDps);
  }
  return plannedConfig;
}

function readActiveWaveSession(save: GodotSave): WaveSession | null {
  const raw = save.active_wave_session;
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) return null;
  const session = raw as Partial<WaveSession>;
  if (typeof session.id !== "string" || !Number.isInteger(session.wave)) return null;
  if (!session.enemyRewards || typeof session.enemyRewards !== "object" || Array.isArray(session.enemyRewards)) return null;
  if (!Array.isArray(session.requiredEnemyIds)) {
    session.requiredEnemyIds = Object.keys(session.enemyRewards);
  }
  session.minClearSec = Math.max(0, Number(session.minClearSec) || 0);
  return session as WaveSession;
}

function validateKillTiming(session: WaveSession, reward: WaveEnemyReward) {
  const startedAtMs = Date.parse(session.startedAt);
  if (!Number.isFinite(startedAtMs)) return { success: false, reason: "invalid_wave_session_time" };
  const elapsedSec = Math.max(0, (Date.now() - startedAtMs) / 1000);
  const nextClaimIndex = intValue(session.claimedCount, 0) + 1;
  const claimedHp = Object.values(session.enemyRewards)
    .filter((entry) => entry.claimed)
    .reduce((sum, entry) => sum + Math.max(0, Number(entry.hp) || 0), 0);
  const claimedPerfectClearSec = (claimedHp + Math.max(0, Number(reward.hp) || 0)) / Math.max(1, Number(session.estimatedPlayerDps) || 10);
  const minElapsedSec = Math.min(12, Math.max(nextClaimIndex * 0.05, claimedPerfectClearSec * 0.04));
  if (elapsedSec < minElapsedSec) {
    return { success: false, reason: "kill_too_fast", elapsedSec, minElapsedSec };
  }
  return { success: true };
}

function validateWaveClearTiming(session: WaveSession) {
  const startedAtMs = Date.parse(session.startedAt);
  if (!Number.isFinite(startedAtMs)) return { success: false, reason: "invalid_wave_session_time" };
  const elapsedSec = Math.max(0, (Date.now() - startedAtMs) / 1000);
  const minClearSec = Math.max(0, Number(session.minClearSec) || 0);
  if (elapsedSec < minClearSec) {
    return { success: false, reason: "wave_cleared_too_fast", elapsedSec, minClearSec };
  }
  return { success: true };
}

function estimateMinimumClearSecForHp(totalHp: number, estimatedPlayerDps = 10) {
  if (totalHp <= 0) return 0;
  const perfectClearSec = totalHp / Math.max(1, estimatedPlayerDps);
  return Math.min(12, Math.max(0.25, perfectClearSec * 0.05));
}

function estimatePlayerDps(save: GodotSave) {
  const equipment = save.equipment_levels as Record<string, number> | undefined;
  const prestige = save.prestige_upgrade_levels as Record<string, number> | undefined;
  const weaponLevel = intValue(equipment?.weapon, 0);
  const glovesLevel = intValue(equipment?.gloves, 0);
  const attackPrestige = intValue(prestige?.attack, 0);
  return (10 + weaponLevel * 1.8 + glovesLevel * 0.6) * (1 + attackPrestige * 0.006);
}

function rollWeightedNormalEnemyType(wave: number) {
  const weighted = getWeightedNormalEnemyTypes(wave);
  const totalWeight = weighted.reduce((sum, entry) => sum + entry.weight, 0);
  let roll = Math.floor(Math.random() * totalWeight) + 1;
  for (const entry of weighted) {
    roll -= entry.weight;
    if (roll <= 0) return entry.type;
  }
  return "basic";
}

function getAvailableNormalEnemyTypes(wave: number) {
  const types = ["basic"];
  if (wave >= 10) types.push("tank");
  if (wave >= 30) types.push("fast");
  if (wave >= 50) types.push("ranged");
  return types;
}

function getWeightedNormalEnemyTypes(wave: number) {
  if (wave >= 50) {
    return [
      { type: "basic", weight: 45 },
      { type: "tank", weight: 25 },
      { type: "fast", weight: 20 },
      { type: "ranged", weight: 10 }
    ];
  }
  if (wave >= 30) {
    return [
      { type: "basic", weight: 55 },
      { type: "tank", weight: 25 },
      { type: "fast", weight: 20 }
    ];
  }
  if (wave >= 10) {
    return [
      { type: "basic", weight: 70 },
      { type: "tank", weight: 30 }
    ];
  }
  return [{ type: "basic", weight: 100 }];
}

type WaveSession = {
  id: string;
  wave: number;
  startedAt: string;
  completedAt?: string;
  claimedCount: number;
  minClearSec: number;
  totalRequiredHp: number;
  estimatedPlayerDps?: number;
  requiredEnemyIds: string[];
  enemyRewards: Record<string, WaveEnemyReward>;
};

type WaveEnemyReward = {
  gold: number;
  essence: number;
  echo: number;
  hp: number;
  bossKind: string;
  claimed: boolean;
};
