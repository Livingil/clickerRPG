import { Router } from "express";
import { asyncHandler } from "../http/asyncHandler.js";
import { readPlayerId } from "../http/playerId.js";
import { savePlayerState } from "../services/playerService.js";
import { activateEcho } from "../services/progressService.js";

const router = Router();

router.post("/activate", asyncHandler(async (req, res) => {
  let activated = 0;
  const state = await savePlayerState(readPlayerId(req), (state) => {
    activated = activateEcho(state);
  });
  res.json({ activated, state });
}));

export { router as echoRoutes };
