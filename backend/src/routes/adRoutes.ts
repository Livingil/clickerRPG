import { Router } from "express";
import { z } from "zod";
import { asyncHandler } from "../http/asyncHandler.js";
import { readPlayerId } from "../http/playerId.js";
import { savePlayerState } from "../services/playerService.js";
import { claimAdBoost } from "../services/progressService.js";

const router = Router();
const boostSchema = z.object({ boostId: z.string().min(1).max(80) });

router.post("/claim-boost", asyncHandler(async (req, res) => {
  const body = boostSchema.parse(req.body);
  const state = await savePlayerState(readPlayerId(req), (state) => claimAdBoost(state, body.boostId));
  res.json({ state });
}));

export { router as adRoutes };
