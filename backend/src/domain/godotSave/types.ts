export type GodotSave = Record<string, unknown>;
export type CommandPayload = Record<string, unknown>;
export type CommandResult = { success: boolean; reason?: string; [key: string]: unknown };
