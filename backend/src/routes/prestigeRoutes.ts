import { Router } from "express";
import { z } from "zod";
import { asyncHandler } from "../http/asyncHandler.js";
import { readPlayerId } from "../http/playerId.js";
import { savePlayerState } from "../services/playerService.js";
import { performPrestige, upgradePrestige } from "../services/progressService.js";
import type { PrestigeUpgradeId } from "../types.js";

const router = Router();
const upgradeSchema = z.object({
  upgradeId: z.enum(["attack", "hp", "defense", "crit", "gold", "school_xp", "craft"])
});

router.post("/perform", asyncHandler(async (req, res) => {
  let gainedShards = 0;
  const state = await savePlayerState(readPlayerId(req), (state) => {
    gainedShards = performPrestige(state);
  });
  res.json({ gainedShards, state });
}));

router.post("/upgrade", asyncHandler(async (req, res) => {
  const body = upgradeSchema.parse(req.body);
  const state = await savePlayerState(readPlayerId(req), (state) => upgradePrestige(state, body.upgradeId as PrestigeUpgradeId));
  res.json({ state });
}));

export { router as prestigeRoutes };
