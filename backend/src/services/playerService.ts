import { PlayerModel } from "../models/player.model.js";
import { createDefaultState } from "../domain/defaultState.js";
import { normalizeSave } from "../domain/godotSave/codec.js";
import { claimOfflineRewards } from "../domain/godotSave/offline.js";
import { env } from "../config/env.js";
import { createAuthToken } from "../http/authToken.js";
import { badRequest, notFound } from "../http/errors.js";

export async function devLogin(deviceId: string, name?: string) {
  const player = await PlayerModel.findOneAndUpdate(
    { deviceId },
    { $setOnInsert: { deviceId, state: createDefaultState() }, $set: { name } },
    { upsert: true, new: true }
  );
  if (player.godotSave) {
    player.godotSave = normalizeSave(player.godotSave);
    claimOfflineRewards(player.godotSave);
    player.godotSave.server_saved_at = new Date().toISOString();
    player.markModified("godotSave");
    await player.save();
  } else {
    player.godotSave = normalizeSave({});
    player.godotSave.server_saved_at = new Date().toISOString();
    player.markModified("godotSave");
    await player.save();
  }
  const playerId = String(player._id);
  return { playerId, sessionToken: createAuthToken(playerId), deviceId: player.deviceId, state: player.state, saveData: player.godotSave ?? null };
}

export async function getPlayerOrThrow(playerId: string) {
  const player = await PlayerModel.findById(playerId);
  if (!player) throw notFound("Player not found");
  return player;
}

export async function getPlayerState(playerId: string) {
  const player = await getPlayerOrThrow(playerId);
  return player.state;
}

export async function getGodotSave(playerId: string) {
  const player = await getPlayerOrThrow(playerId);
  return player.godotSave ?? null;
}

export async function replaceGodotSave(playerId: string, saveData: Record<string, unknown>) {
  if (env.NODE_ENV === "production") throw badRequest("Direct save replacement is disabled");
  const player = await getPlayerOrThrow(playerId);
  player.godotSave = { ...saveData, server_authoritative: true, server_saved_at: new Date().toISOString() };
  player.markModified("godotSave");
  await player.save();
  return player.godotSave;
}

export async function savePlayerState(playerId: string, mutate: (state: any) => void) {
  const player = await getPlayerOrThrow(playerId);
  mutate(player.state);
  player.state.updatedAt = new Date().toISOString();
  player.markModified("state");
  await player.save();
  return player.state;
}
