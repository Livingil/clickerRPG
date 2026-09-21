import { Router } from "express";
import { z } from "zod";
import { asyncHandler } from "../http/asyncHandler.js";
import { readPlayerId } from "../http/playerId.js";
import { savePlayerState } from "../services/playerService.js";
import { addSkillUseXp, equipSkill, setActiveSchool } from "../services/progressService.js";
import type { SchoolId } from "../types.js";

const router = Router();
const schoolSchema = z.object({ schoolId: z.enum(["fire", "water", "earth", "air", "lightning"]) });
const skillUseSchema = schoolSchema.extend({ skillId: z.string().min(1).max(80) });
const equipSkillSchema = z.object({
  slotIndex: z.coerce.number().int().min(0).max(4),
  skillId: z.string().min(1).max(80)
});

router.post("/set-active", asyncHandler(async (req, res) => {
  const body = schoolSchema.parse(req.body);
  const state = await savePlayerState(readPlayerId(req), (state) => setActiveSchool(state, body.schoolId as SchoolId));
  res.json({ state });
}));

router.post("/skill-used", asyncHandler(async (req, res) => {
  const body = skillUseSchema.parse(req.body);
  let xpGained = 0;
  const state = await savePlayerState(readPlayerId(req), (state) => {
    xpGained = addSkillUseXp(state, body.schoolId as SchoolId, body.skillId);
  });
  res.json({ xpGained, state });
}));

router.post("/equip-skill", asyncHandler(async (req, res) => {
  const body = equipSkillSchema.parse(req.body);
  const state = await savePlayerState(readPlayerId(req), (state) => equipSkill(state, body.slotIndex, body.skillId));
  res.json({ state });
}));

export { router as schoolRoutes };
