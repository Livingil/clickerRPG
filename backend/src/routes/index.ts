import { Router } from "express";
import { env } from "../config/env.js";
import { adRoutes } from "./adRoutes.js";
import { artifactRoutes } from "./artifactRoutes.js";
import { authRoutes } from "./authRoutes.js";
import { echoRoutes } from "./echoRoutes.js";
import { equipmentRoutes } from "./equipmentRoutes.js";
import { godotRoutes } from "./godotRoutes.js";
import { offlineRoutes } from "./offlineRoutes.js";
import { playerRoutes } from "./playerRoutes.js";
import { prestigeRoutes } from "./prestigeRoutes.js";
import { runRoutes } from "./runRoutes.js";
import { schoolRoutes } from "./schoolRoutes.js";

export const apiRouter = Router();

apiRouter.use("/auth", authRoutes);
apiRouter.use("/player", playerRoutes);
apiRouter.use("/godot", godotRoutes);

if (env.NODE_ENV !== "production" && env.ALLOW_LEGACY_STATE_ROUTES) {
  apiRouter.use("/run", runRoutes);
  apiRouter.use("/equipment", equipmentRoutes);
  apiRouter.use("/artifact", artifactRoutes);
  apiRouter.use("/echo", echoRoutes);
  apiRouter.use("/prestige", prestigeRoutes);
  apiRouter.use("/school", schoolRoutes);
  apiRouter.use("/ad", adRoutes);
  apiRouter.use("/offline", offlineRoutes);
}
