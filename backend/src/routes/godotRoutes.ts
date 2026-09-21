import { Router } from "express";
import { z } from "zod";
import { asyncHandler } from "../http/asyncHandler.js";
import { readPlayerId } from "../http/playerId.js";
import { executeGodotSaveCommand } from "../services/godotSaveCommandService.js";

const router = Router();

const commandSchema = z.object({
  command: z.string().min(1).max(80),
  payload: z.record(z.string(), z.unknown()).default({})
});

router.post("/command", asyncHandler(async (req, res) => {
  const body = commandSchema.parse(req.body);
  const result = await executeGodotSaveCommand(readPlayerId(req), body.command, body.payload);
  res.json({
    success: result.success,
    changed: result.changed,
    result: result.result,
    saveData: result.saveData
  });
}));

export { router as godotRoutes };
