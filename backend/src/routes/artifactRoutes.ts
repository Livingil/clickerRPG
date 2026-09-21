import { Router } from "express";
import { z } from "zod";
import { asyncHandler } from "../http/asyncHandler.js";
import { readPlayerId } from "../http/playerId.js";
import { savePlayerState } from "../services/playerService.js";
import { upgradeArtifact } from "../services/economyService.js";

const router = Router();
const artifactSchema = z.object({ artifactId: z.string().min(1).max(80) });

router.post("/upgrade", asyncHandler(async (req, res) => {
  const body = artifactSchema.parse(req.body);
  const state = await savePlayerState(readPlayerId(req), (state) => upgradeArtifact(state, body.artifactId));
  res.json({ state });
}));

export { router as artifactRoutes };
