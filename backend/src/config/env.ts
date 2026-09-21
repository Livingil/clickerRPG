import "dotenv/config";
import { z } from "zod";

const envSchema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  PORT: z.coerce.number().int().positive().default(3000),
  MONGO_URI: z.string().min(1).default("mongodb://127.0.0.1:27017/clicker_rpg"),
  CORS_ORIGIN: z.string().default("*"),
  AUTH_TOKEN_SECRET: z.string().min(16).default("clicker-rpg-local-dev-secret"),
  ALLOW_INSECURE_PLAYER_ID_HEADER: z.coerce.boolean().default(false),
  ALLOW_LEGACY_STATE_ROUTES: z.coerce.boolean().default(false)
});

export const env = envSchema.parse(process.env);
