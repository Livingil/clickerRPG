import { buildEnemyConfig } from "./enemyPlan.js";
import { claimRunRewards } from "./economy.js";
import { echoGainForEnemy } from "./rewardRules.js";
import type { GodotSave } from "./types.js";
import { intValue } from "./value.js";

const minOfflineSec = 60;
const maxOfflineSec = 8 * 60 * 60;
const offlineEfficiency = 0.35;
const minWaveClearSec = 8;

export function claimOfflineRewards(save: GodotSave) {
  const nowMs = Date.now();
  const lastMs = readLastServerSeenMs(save);
  const elapsedSec = Math.max(0, Math.floor((nowMs - lastMs) / 1000));
  save.server_last_seen_at = new Date(nowMs).toISOString();
  if (elapsedSec < minOfflineSec) return { success: true, claimed: false, elapsedSec };

  const cappedSec = Math.min(elapsedSec, maxOfflineSec);
  const wave = Math.max(1, intValue(save.highest_wave_reached, 1));
  const estimated = estimateWaveRewards(wave);
  const clearTimeSec = Math.max(minWaveClearSec, estimated.clearTimeSec);
  const effectiveWaves = cappedSec / clearTimeSec * offlineEfficiency;
  const reward = {
    gold: Math.round(estimated.gold * effectiveWaves),
    essence: Math.round(estimated.essence * effectiveWaves),
    echo: Math.round(estimated.echo * effectiveWaves)
  };
  const applied = claimRunRewards(save, reward);
  const report = {
    elapsed_sec: elapsedSec,
    capped_sec: cappedSec,
    wave,
    effective_waves: effectiveWaves,
    gold: applied.goldGain,
    essence: applied.essenceGain,
    echo: applied.echoGain,
    capped: elapsedSec > cappedSec
  };
  save.pending_offline_reward_report = report;
  return { success: true, claimed: true, ...report };
}

function readLastServerSeenMs(save: GodotSave) {
  const iso = String(save.server_last_seen_at ?? save.server_saved_at ?? "");
  const parsed = Date.parse(iso);
  if (Number.isFinite(parsed)) return parsed;
  const unix = intValue(save.last_save_unix, 0);
  return unix > 0 ? unix * 1000 : Date.now();
}

function estimateWaveRewards(wave: number) {
  const normalCount = 4 + Math.floor(Math.max(0, wave - 1) * 0.58);
  const normal = buildEnemyConfig("normal", wave);
  let gold = Number(normal.rewardGold) * normalCount;
  let essence = Number(normal.rewardEssence) * normalCount;
  let echo = echoGainForEnemy("none", wave) * normalCount;
  let hp = Number(normal.maxHp) * normalCount;

  for (const kind of bossKindsForWave(wave)) {
    const config = buildEnemyConfig(kind, wave);
    gold += Number(config.rewardGold);
    essence += Number(config.rewardEssence);
    echo += echoGainForEnemy(String(config.bossKind ?? "none"), wave);
    hp += Number(config.maxHp);
  }

  return {
    gold,
    essence,
    echo,
    clearTimeSec: hp / 100 + (normalCount + bossKindsForWave(wave).length) * 0.35
  };
}

function bossKindsForWave(wave: number) {
  const kinds = ["wave_boss"];
  if (wave % 100 === 0) kinds.push("apex_boss");
  else if (wave % 10 === 0) kinds.push("grand_boss");
  else if (wave % 5 === 0) kinds.push("mini_boss");
  return kinds;
}
