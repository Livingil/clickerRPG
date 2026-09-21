import { Router } from "express";
import { z } from "zod";
import { asyncHandler } from "../http/asyncHandler.js";
import { devLogin } from "../services/playerService.js";

const router = Router();
const devLoginSchema = z.object({
  deviceId: z.string().min(1).max(120),
  name: z.string().min(1).max(80).optional()
});

router.post("/dev-login", asyncHandler(async (req, res) => {
  const body = devLoginSchema.parse(req.body);
  res.json(await devLogin(body.deviceId, body.name));
}));

export { router as authRoutes };
