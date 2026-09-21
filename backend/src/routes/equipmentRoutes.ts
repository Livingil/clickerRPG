import { Router } from "express";
import { z } from "zod";
import { asyncHandler } from "../http/asyncHandler.js";
import { readPlayerId } from "../http/playerId.js";
import { savePlayerState } from "../services/playerService.js";
import { unlockEquipment, upgradeEquipment } from "../services/economyService.js";
import type { EquipmentId } from "../types.js";

const router = Router();
const equipmentSchema = z.object({
  equipmentId: z.enum(["weapon", "helm", "chest", "gloves", "boots", "ring", "amulet", "relic"])
});

router.post("/unlock", asyncHandler(async (req, res) => {
  const body = equipmentSchema.parse(req.body);
  const state = await savePlayerState(readPlayerId(req), (state) => unlockEquipment(state, body.equipmentId as EquipmentId));
  res.json({ state });
}));

router.post("/upgrade", asyncHandler(async (req, res) => {
  const body = equipmentSchema.parse(req.body);
  const state = await savePlayerState(readPlayerId(req), (state) => upgradeEquipment(state, body.equipmentId as EquipmentId));
  res.json({ state });
}));

export { router as equipmentRoutes };
