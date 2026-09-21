import { createHmac, timingSafeEqual } from "node:crypto";
import { env } from "../config/env.js";
import { badRequest } from "./errors.js";

const TOKEN_VERSION = "v1";

export function createAuthToken(playerId: string) {
  const payload = base64UrlEncode(JSON.stringify({ playerId, v: TOKEN_VERSION }));
  const signature = sign(payload);
  return `${payload}.${signature}`;
}

export function readPlayerIdFromAuthToken(token: string) {
  const [payload, signature, extra] = token.split(".");
  if (!payload || !signature || extra !== undefined) throw badRequest("Invalid auth token");
  const expected = sign(payload);
  if (!safeEqual(signature, expected)) throw badRequest("Invalid auth token");

  const parsed = JSON.parse(Buffer.from(payload, "base64url").toString("utf8")) as unknown;
  if (!isTokenPayload(parsed)) throw badRequest("Invalid auth token");
  return parsed.playerId;
}

function sign(payload: string) {
  return createHmac("sha256", env.AUTH_TOKEN_SECRET).update(payload).digest("base64url");
}

function base64UrlEncode(value: string) {
  return Buffer.from(value, "utf8").toString("base64url");
}

function safeEqual(left: string, right: string) {
  const leftBuffer = Buffer.from(left);
  const rightBuffer = Buffer.from(right);
  return leftBuffer.length === rightBuffer.length && timingSafeEqual(leftBuffer, rightBuffer);
}

function isTokenPayload(value: unknown): value is { playerId: string; v: string } {
  return typeof value === "object"
    && value !== null
    && typeof (value as { playerId?: unknown }).playerId === "string"
    && (value as { playerId: string }).playerId.length > 0
    && (value as { v?: unknown }).v === TOKEN_VERSION;
}
