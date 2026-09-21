import { Schema, model } from "mongoose";
import type { PlayerState } from "../types.js";

export interface PlayerDocument {
  deviceId: string;
  name?: string;
  state: PlayerState;
  godotSave?: Record<string, unknown>;
}

const playerSchema = new Schema<PlayerDocument>(
  {
    deviceId: { type: String, required: true, unique: true, index: true },
    name: { type: String },
    state: { type: Schema.Types.Mixed, required: true },
    godotSave: { type: Schema.Types.Mixed }
  },
  { timestamps: true, minimize: false }
);

export const PlayerModel = model<PlayerDocument>("Player", playerSchema);
