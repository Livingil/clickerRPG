import { Router } from "express";
import { asyncHandler } from "../http/asyncHandler.js";
import { readPlayerId } from "../http/playerId.js";
import { savePlayerState } from "../services/playerService.js";
import { claimOffline } from "../services/progressService.js";

const router = Router();

router.post("/claim", asyncHandler(async (req, res) => {
  let rewards;
  const state = await savePlayerState(readPlayerId(req), (state) => {
    rewards = claimOffline(state);
  });
  res.json({ rewards, state });
}));

export { router as offlineRoutes };
