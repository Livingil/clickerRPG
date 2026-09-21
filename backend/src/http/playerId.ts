import type { Request } from "express";
import { z } from "zod";
import { env } from "../config/env.js";
import { readPlayerIdFromAuthToken } from "./authToken.js";
import { badRequest } from "./errors.js";

export function readPlayerId(req: Request): string {
  const token = readBearerToken(req) ?? req.header("x-session-token");
  if (token) return readPlayerIdFromAuthToken(token);

  if (env.NODE_ENV !== "production" || env.ALLOW_INSECURE_PLAYER_ID_HEADER) {
    const value = req.header("x-player-id") ?? req.query.playerId;
    const parsed = z.string().min(1).safeParse(value);
    if (parsed.success) return parsed.data;
  }

  throw badRequest("Missing auth token");
}

function readBearerToken(req: Request) {
  const value = req.header("authorization");
  if (!value?.startsWith("Bearer ")) return null;
  return value.slice("Bearer ".length).trim();
}
