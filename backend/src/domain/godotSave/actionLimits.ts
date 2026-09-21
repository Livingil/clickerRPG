import type { GodotSave } from "./types.js";
import { intValue, isRecord } from "./value.js";

type Budget = {
  windowStartMs: number;
  used: number;
};

export function consumeActionBudget(save: GodotSave, key: string, amount: number, limit: number, windowMs: number) {
  const requested = Math.max(0, Math.floor(amount));
  if (requested <= 0) return { allowed: 0, limited: false };

  const now = Date.now();
  const budgets = getBudgetMap(save);
  const current = readBudget(budgets[key]);
  const budget = now - current.windowStartMs >= windowMs ? { windowStartMs: now, used: 0 } : current;
  const remaining = Math.max(0, limit - budget.used);
  const allowed = Math.min(requested, remaining);
  budget.used += allowed;
  budgets[key] = budget;
  save.server_action_budgets = budgets;
  return { allowed, limited: allowed < requested };
}

export function rememberEventOnce(save: GodotSave, namespace: string, eventId: string, maxStored = 300) {
  if (!eventId) return { fresh: true };
  const key = `${namespace}:${eventId}`;
  const raw = Array.isArray(save.server_seen_event_ids) ? save.server_seen_event_ids.map(String) : [];
  if (raw.includes(key)) return { fresh: false };
  raw.push(key);
  save.server_seen_event_ids = raw.slice(-maxStored);
  return { fresh: true };
}

function getBudgetMap(save: GodotSave) {
  return isRecord(save.server_action_budgets) ? save.server_action_budgets as Record<string, unknown> : {};
}

function readBudget(value: unknown): Budget {
  if (!isRecord(value)) return { windowStartMs: 0, used: 0 };
  return {
    windowStartMs: intValue(value.windowStartMs, 0),
    used: intValue(value.used, 0)
  };
}
