import { Router } from "express";
import { z } from "zod";
import { readPlayerId } from "../http/playerId.js";
import { asyncHandler } from "../http/asyncHandler.js";
import { savePlayerState } from "../services/playerService.js";
import { completeWave, killEnemy, registerDeath, startRun } from "../services/progressService.js";
import type { EnemyKind } from "../types.js";

const router = Router();
const waveSchema = z.object({ wave: z.coerce.number().int().positive() });
const deathSchema = z.object({ runTimeSec: z.coerce.number().nonnegative() });
const killSchema = z.object({
  enemyKind: z.enum(["normal", "tank", "fast", "ranged", "wave", "mini", "grand", "apex"]),
  wave: z.coerce.number().int().positive()
});

router.post("/start", asyncHandler(async (req, res) => {
  const state = await savePlayerState(readPlayerId(req), startRun);
  res.json({ state });
}));

router.post("/wave-complete", asyncHandler(async (req, res) => {
  const body = waveSchema.parse(req.body);
  let rewards;
  const state = await savePlayerState(readPlayerId(req), (state) => {
    rewards = completeWave(state, body.wave);
  });
  res.json({ rewards, state });
}));

router.post("/enemy-killed", asyncHandler(async (req, res) => {
  const body = killSchema.parse(req.body);
  let rewards;
  const state = await savePlayerState(readPlayerId(req), (state) => {
    rewards = killEnemy(state, body.enemyKind as EnemyKind, body.wave);
  });
  res.json({ rewards, state });
}));

router.post("/death", asyncHandler(async (req, res) => {
  const body = deathSchema.parse(req.body);
  const state = await savePlayerState(readPlayerId(req), (state) => registerDeath(state, body.runTimeSec));
  res.json({ state });
}));

export { router as runRoutes };
