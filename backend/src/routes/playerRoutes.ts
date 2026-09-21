import { Router } from "express";
import { z } from "zod";
import { asyncHandler } from "../http/asyncHandler.js";
import { readPlayerId } from "../http/playerId.js";
import { getGodotSave, getPlayerState, replaceGodotSave } from "../services/playerService.js";

const router = Router();

router.get("/state", asyncHandler(async (req, res) => {
  res.json({ state: await getPlayerState(readPlayerId(req)) });
}));

router.get("/save-data", asyncHandler(async (req, res) => {
  res.json({ saveData: await getGodotSave(readPlayerId(req)) });
}));

router.put("/save-data", asyncHandler(async (req, res) => {
  const body = z.object({ saveData: z.record(z.unknown()) }).parse(req.body);
  res.json({ saveData: await replaceGodotSave(readPlayerId(req), body.saveData) });
}));

export { router as playerRoutes };
