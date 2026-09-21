import { normalizeBoolMap, normalizeNumberMap } from "./codec.js";
import { getEchoProgressInfo } from "./echo.js";
import { artifactIds, equipmentIds, prestigeShardsForWave, prestigeUpgradeCost, prestigeUpgradeIds, schoolIds } from "./rules.js";
import type { GodotSave } from "./types.js";
import { intValue, numberValue, requireId } from "./value.js";

export function activateEcho(save: GodotSave) {
  const collected = intValue(save.echo_collected, 0);
  if (collected <= 0) return { success: false, reason: "no_echo" };
  save.echo_power = intValue(save.echo_power, 0) + collected;
  save.echo_collected = 0;
  return { success: true, activated: collected, echoPower: save.echo_power };
}

export function performPrestige(save: GodotSave) {
  const highestWave = intValue(save.highest_wave_reached, 1);
  const gainedShards = prestigeShardsForWave(highestWave);
  if (gainedShards <= 0) return { success: false, reason: "locked" };
  save.prestige_count = intValue(save.prestige_count, 0) + 1;
  save.prestige_shards = intValue(save.prestige_shards, 0) + gainedShards;
  save.prestige_shards_earned_total = intValue(save.prestige_shards_earned_total, 0) + gainedShards;
  resetRun(save);
  return { success: true, gainedShards, prestigeCount: save.prestige_count };
}

export function upgradePrestige(save: GodotSave, upgradeId: string) {
  requireId(upgradeId, prestigeUpgradeIds, "upgradeId");
  const levels = save.prestige_upgrade_levels as Record<string, number>;
  const oldLevel = intValue(levels[upgradeId], 0);
  const cost = prestigeUpgradeCost(upgradeId, oldLevel);
  if (intValue(save.prestige_shards, 0) < cost) return { success: false, reason: "not_enough_shards", cost };
  save.prestige_shards = intValue(save.prestige_shards, 0) - cost;
  levels[upgradeId] = oldLevel + 1;
  return { success: true, cost, oldLevel, level: levels[upgradeId] };
}

export function applyWaveChanged(save: GodotSave, waveValue: number) {
  const wave = Math.max(1, Math.floor(waveValue));
  save.current_run_wave = wave;
  save.highest_wave_reached = Math.max(intValue(save.highest_wave_reached, 1), wave);
  return { success: true, wave, highestWave: save.highest_wave_reached };
}

export function applyRunDeath(save: GodotSave, runTimeSec: number) {
  const collected = intValue(save.echo_collected, 0);
  const echoBefore = intValue(save.echo_power, 0);
  save.total_deaths = intValue(save.total_deaths, 0) + 1;
  save.best_run_time_sec = Math.max(numberValue(save.best_run_time_sec, 0), Math.max(0, runTimeSec));
  save.echo_power = echoBefore + collected;
  save.echo_collected = 0;
  const report = buildRunDeathReport(Math.max(0, runTimeSec), echoBefore, intValue(save.echo_power, 0), collected);
  return {
    success: true,
    runTimeSec: Math.max(0, runTimeSec),
    collectedEcho: collected,
    echoBefore,
    echoAfter: save.echo_power,
    report
  };
}

function buildRunDeathReport(runTimeSec: number, echoBefore: number, echoAfter: number, collectedEcho: number) {
  const nextEchoInfo = getEchoProgressInfo(echoAfter);
  return {
    run_time_sec: runTimeSec,
    collected_echo: collectedEcho,
    echo_before: echoBefore,
    echo_after: echoAfter,
    echo_delta: Math.max(0, echoAfter - echoBefore),
    remaining_to_next_echo_bonus: nextEchoInfo.remaining_to_next,
    next_echo_bonus_at: nextEchoInfo.required_echo
  };
}

export function resetAll(save: GodotSave) {
  resetRun(save);
  save.prestige_count = 0;
  save.prestige_shards = 0;
  save.prestige_shards_earned_total = 0;
  save.prestige_upgrade_levels = normalizeNumberMap({}, prestigeUpgradeIds);
  save.school_mastery_xp = normalizeNumberMap({}, schoolIds);
  save.weapon_school_upgrade_levels = normalizeNumberMap({}, schoolIds);
  save.pending_weapon_skill_offer_schools = [];
  save.active_school = "fire";
  save.owned_artifacts = [];
  save.artifact_levels = normalizeNumberMap({}, artifactIds);
  save.defeated_apex_wave_rewards = [];
  return { success: true };
}

export function resetRun(save: GodotSave) {
  save.gold = 0;
  save.essence = 0;
  save.echo_collected = 0;
  save.echo_power = 0;
  save.current_run_wave = 1;
  save.highest_wave_reached = 1;
  save.total_deaths = 0;
  save.best_run_time_sec = 0;
  save.equipment_levels = normalizeNumberMap({}, equipmentIds);
  save.equipment_unlocked = normalizeBoolMap({}, equipmentIds, { weapon: true });
  save.pending_weapon_skill_offer_schools = [];
  save.active_ad_boosts = {};
}
