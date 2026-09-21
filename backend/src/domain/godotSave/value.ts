import { badRequest } from "../../http/errors.js";

export function readString(payload: Record<string, unknown>, key: string): string {
  return String(payload[key] ?? "");
}

export function readNumber(payload: Record<string, unknown>, key: string, fallback: number): number {
  return numberValue(payload[key], fallback);
}

export function intValue(value: unknown, fallback: number): number {
  const parsed = Math.floor(numberValue(value, fallback));
  return Number.isFinite(parsed) ? parsed : fallback;
}

export function numberValue(value: unknown, fallback: number): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

export function requireId<T extends readonly string[]>(value: string, allowed: T, field: string): void {
  if (!allowed.includes(value)) throw badRequest(`Invalid ${field}: ${value}`);
}

export function hasValue<T extends readonly string[]>(allowed: T, value: string): boolean {
  return allowed.includes(value);
}

export function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
