import { normalizeSave } from "../domain/godotSave/codec.js";
import { resolveEnemyAttack, resolveHeroAttack, resolveHeroAttackBatch } from "../domain/godotSave/combat.js";
import { activateOfferedAdBoost, activateSpeedAdBoost, requestAdBoostOffer, unlockEquipment, upgradeArtifact, upgradeEquipment } from "../domain/godotSave/economy.js";
import { claimOfflineRewards } from "../domain/godotSave/offline.js";
import { activateEcho, applyRunDeath, performPrestige, resetAll, upgradePrestige } from "../domain/godotSave/progress.js";
import { addSchoolXp, addSchoolXpBatch, applyWeaponSchoolOffer, equipSkill, setActiveSchool } from "../domain/godotSave/school.js";
import type { CommandPayload, GodotSave } from "../domain/godotSave/types.js";
import { readNumber, readString } from "../domain/godotSave/value.js";
import { claimEnemyKill, claimEnemyKillBatch, startWave } from "../domain/godotSave/wave.js";
import { env } from "../config/env.js";
import { badRequest } from "../http/errors.js";
import { getPlayerOrThrow } from "./playerService.js";

export async function executeGodotSaveCommand(playerId: string, command: string, payload: CommandPayload) {
  const player = await getPlayerOrThrow(playerId);
  const saveData = normalizeSave(player.godotSave ?? {});
  const before = JSON.stringify(saveData);
  const result = applyCommand(saveData, command, payload);
  const changed = before !== JSON.stringify(saveData);

  if (changed) {
    saveData.server_saved_at = new Date().toISOString();
    player.godotSave = saveData;
    player.markModified("godotSave");
    await player.save();
  }

  return { success: result.success, changed, result, saveData };
}

function applyCommand(save: GodotSave, command: string, payload: CommandPayload) {
  switch (command) {
    case "equipment.unlock":
      return unlockEquipment(save, readString(payload, "equipmentId"));
    case "equipment.upgrade":
      return upgradeEquipment(save, readString(payload, "equipmentId"));
    case "artifact.upgrade":
      return upgradeArtifact(save, readString(payload, "artifactId"));
    case "artifact.grantApexReward":
      return { success: false, reason: "apex_rewards_are_claimed_by_enemy_kill" };
    case "echo.activate":
      return activateEcho(save);
    case "prestige.perform":
      return performPrestige(save);
    case "prestige.upgrade":
      return upgradePrestige(save, readString(payload, "upgradeId"));
    case "school.setActive":
      return setActiveSchool(save, readString(payload, "schoolId"));
    case "school.addXp":
      return addSchoolXp(save, readString(payload, "schoolId"), readNumber(payload, "amount", 0));
    case "school.addXpBatch":
      return addSchoolXpBatch(save, payload.batch);
    case "school.equipSkill":
      return equipSkill(save, readNumber(payload, "slotIndex", -1), readString(payload, "skillId"));
    case "school.clearSkill":
      return equipSkill(save, readNumber(payload, "slotIndex", -1), "");
    case "weapon.applySchoolOffer":
      return applyWeaponSchoolOffer(save, readNumber(payload, "offerIndex", -1));
    case "run.enemyKilled":
      return claimEnemyKill(save, readString(payload, "enemyInstanceId"));
    case "run.enemyKilledBatch":
      return claimEnemyKillBatch(save, payload.enemyInstanceIds);
    case "run.claimRewards":
      return { success: false, reason: "client_reward_claims_disabled" };
    case "run.waveChanged":
      return { success: false, reason: "wave_changes_must_use_wave_start" };
    case "wave.start":
      return startWave(save, readNumber(payload, "wave", 1));
    case "combat.heroAttack":
      return resolveHeroAttack(save, payload);
    case "combat.heroAttackBatch":
      return resolveHeroAttackBatch(save, payload);
    case "combat.enemyAttack":
      return resolveEnemyAttack(save, payload);
    case "run.death":
      return applyRunDeath(save, readNumber(payload, "runTimeSec", 0));
    case "offline.claim":
      return claimOfflineRewards(save);
    case "ad.requestOffer":
      return requestAdBoostOffer(save);
    case "ad.activateSpeed":
      return activateSpeedAdBoost(save);
    case "ad.activateBoost":
      return activateOfferedAdBoost(save, readString(payload, "offerId"));
    case "dev.resetAll":
      if (env.NODE_ENV === "production") return { success: false, reason: "dev_command_disabled" };
      return resetAll(save);
    default:
      throw badRequest(`Unknown Godot command: ${command}`);
  }
}
