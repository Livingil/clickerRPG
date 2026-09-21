import { normalizeEquippedSkills } from "./codec.js";
import { consumeActionBudget, rememberEventOnce } from "./actionLimits.js";
import { getSchoolCoreLevelFromXp, getSchoolXpMultiplier, getSkillSlotCount, schoolIds, skillDefs } from "./rules.js";
import type { GodotSave } from "./types.js";
import { intValue, isRecord, requireId } from "./value.js";

const maxSchoolXpEvent = 5;
const maxSchoolXpPerMinute = 240;

export function setActiveSchool(save: GodotSave, schoolId: string) {
  requireId(schoolId, schoolIds, "schoolId");
  save.active_school = schoolId;
  return { success: true, schoolId };
}

export function addSchoolXp(save: GodotSave, schoolId: string, amount: number) {
  requireId(schoolId, schoolIds, "schoolId");
  const budget = consumeActionBudget(save, `school_xp:${schoolId}`, Math.min(maxSchoolXpEvent, amount), maxSchoolXpPerMinute, 60_000);
  const xp = save.school_mastery_xp as Record<string, number>;
  const appliedAmount = Math.max(0, Math.round(budget.allowed * getSchoolXpMultiplier(save)));
  xp[schoolId] = Math.max(0, intValue(xp[schoolId], 0) + appliedAmount);
  return { success: true, schoolId, amount: appliedAmount, xp: xp[schoolId], limited: budget.limited };
}

export function addSchoolXpBatch(save: GodotSave, batch: unknown) {
  if (typeof batch !== "object" || batch === null || Array.isArray(batch)) {
    return { success: false, reason: "invalid_batch" };
  }
  const applied: Record<string, number> = {};
  for (const [schoolId, rawAmount] of Object.entries(batch)) {
    requireId(schoolId, schoolIds, "schoolId");
    const eventId = isRecord(rawAmount) ? String(rawAmount.eventId ?? "") : "";
    if (!rememberEventOnce(save, "school_xp", eventId).fresh) continue;
    const amountSource = isRecord(rawAmount) ? rawAmount.amount : rawAmount;
    const amount = Math.min(maxSchoolXpEvent, Math.max(0, Math.floor(Number(amountSource) || 0)));
    if (amount <= 0) continue;
    const result = addSchoolXp(save, schoolId, amount);
    applied[schoolId] = (applied[schoolId] ?? 0) + intValue(result.amount, 0);
  }
  return { success: true, applied };
}

export function equipSkill(save: GodotSave, slotIndexValue: number, skillId: string) {
  const slotIndex = Math.floor(slotIndexValue);
  const allowedSlots = getSkillSlotCount(intValue(save.highest_wave_reached, 1));
  if (slotIndex < 0 || slotIndex >= allowedSlots) return { success: false, reason: "slot_locked" };
  if (skillId !== "" && !canEquipSkill(save, skillId)) return { success: false, reason: "skill_locked" };
  const equipped = normalizeEquippedSkills(save.equipped_skill_ids, allowedSlots);
  equipped[slotIndex] = skillId;
  save.equipped_skill_ids = equipped;
  return { success: true, slotIndex, skillId };
}

function canEquipSkill(save: GodotSave, skillId: string) {
  const skill = skillDefs[skillId];
  if (!skill) return false;
  if (String(save.active_school ?? "fire") !== skill.school) return false;
  const schoolXp = save.school_mastery_xp as Record<string, number>;
  return getSchoolCoreLevelFromXp(intValue(schoolXp?.[skill.school], 0)) >= skill.unlockLevel;
}

export function applyWeaponSchoolOffer(save: GodotSave, offerIndexValue: number) {
  const offerIndex = Math.floor(offerIndexValue);
  const offers = Array.isArray(save.pending_weapon_skill_offer_schools)
    ? save.pending_weapon_skill_offer_schools.map(String)
    : [];
  if (offerIndex < 0 || offerIndex >= offers.length) return { success: false, reason: "missing_offer" };
  const schoolId = offers[offerIndex];
  requireId(schoolId, schoolIds, "schoolId");
  const levels = save.weapon_school_upgrade_levels as Record<string, number>;
  levels[schoolId] = intValue(levels[schoolId], 0) + 1;
  save.pending_weapon_skill_offer_schools = [];
  return { success: true, schoolId, level: levels[schoolId] };
}
