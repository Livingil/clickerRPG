import type { GodotSave } from "./types.js";
import { intValue } from "./value.js";
import { buildEnemyConfig } from "./enemyPlan.js";
import { claimRunRewards } from "./economy.js";
import { echoGainForEnemy } from "./rewardRules.js";
import { randomUUID } from "node:crypto";

const baseNormalEnemiesPerWave = 4;
const normalEnemyWaveGrowth = 0.58;
const monoWaveChance = 0.10;

export function startWave(save: GodotSave, waveValue: number) {
  const wave = Math.max(1, Math.floor(waveValue));
  const currentWave = intValue(save.current_run_wave, 1);
  const highestWave = intValue(save.highest_wave_reached, 1);
  const maxAllowedWave = Math.max(currentWave, highestWave + 1);
  if (wave > maxAllowedWave) return { success: false, reason: "wave_jump_rejected", maxAllowedWave };

  save.current_run_wave = wave;
  save.highest_wave_reached = Math.max(intValue(save.highest_wave_reached, 1), wave);
  const monoType = rollMonoNormalEnemyType(wave);
  const normalCount = normalEnemyCountForWave(wave);
  const session = createWaveSession(wave);
  const normalEnemies = buildNormalEnemyPlan(wave, normalCount, monoType, session);
  const bosses = buildBossPlan(wave, session);
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

export function claimEnemyKill(save: GodotSave, enemyInstanceId: string) {
  const session = readActiveWaveSession(save);
  if (!session) return { success: false, reason: "missing_wave_session" };
  const reward = session.enemyRewards[enemyInstanceId];
  if (!reward) return { success: false, reason: "unknown_enemy" };
  if (reward.claimed) return { success: true, duplicate: true, goldGain: 0, essenceGain: 0, echoGain: 0 };

  reward.claimed = true;
  const result = claimRunRewards(save, {
    gold: reward.gold,
    essence: reward.essence,
    echo: reward.echo
  });
  return { ...result, enemyInstanceId, wave: session.wave, bossKind: reward.bossKind };
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

function buildBossPlan(wave: number, session: WaveSession) {
  const bosses: Record<string, ReturnType<typeof buildEnemyConfig>> = {
    wave_boss: registerPlannedEnemy(session, buildEnemyConfig("wave_boss", wave))
  };
  if (wave % 100 === 0) bosses.apex_boss = registerPlannedEnemy(session, buildEnemyConfig("apex_boss", wave));
  else if (wave % 10 === 0) bosses.grand_boss = registerPlannedEnemy(session, buildEnemyConfig("grand_boss", wave));
  else if (wave % 5 === 0) bosses.mini_boss = registerPlannedEnemy(session, buildEnemyConfig("mini_boss", wave));
  return bosses;
}

function createWaveSession(wave: number): WaveSession {
  return {
    id: randomUUID(),
    wave,
    startedAt: new Date().toISOString(),
    enemyRewards: {}
  };
}

function registerPlannedEnemy(session: WaveSession, config: ReturnType<typeof buildEnemyConfig>) {
  const instanceId = randomUUID();
  const plannedConfig = { ...config, instanceId };
  const bossKind = String(plannedConfig.bossKind ?? "none");
  session.enemyRewards[instanceId] = {
    gold: Math.max(0, Math.round(Number(plannedConfig.rewardGold) || 0)),
    essence: Math.max(0, Math.round(Number(plannedConfig.rewardEssence) || 0)),
    echo: echoGainForEnemy(bossKind, session.wave),
    bossKind,
    claimed: false
  };
  return plannedConfig;
}

function readActiveWaveSession(save: GodotSave): WaveSession | null {
  const raw = save.active_wave_session;
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) return null;
  const session = raw as Partial<WaveSession>;
  if (typeof session.id !== "string" || !Number.isInteger(session.wave)) return null;
  if (!session.enemyRewards || typeof session.enemyRewards !== "object" || Array.isArray(session.enemyRewards)) return null;
  return session as WaveSession;
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
  enemyRewards: Record<string, {
    gold: number;
    essence: number;
    echo: number;
    bossKind: string;
    claimed: boolean;
  }>;
};
