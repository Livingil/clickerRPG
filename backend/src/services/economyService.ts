import { artifactIds, artifactUpgradeCost, equipmentIds, equipmentUnlockCost, equipmentUpgradeCost, prestigeMultiplier } from "../domain/balance.js";
import { badRequest } from "../http/errors.js";
import type { EquipmentId, PlayerState } from "../types.js";

export function unlockEquipment(state: PlayerState, equipmentId: EquipmentId): void {
  assertEquipment(equipmentId);
  if (state.equipmentUnlocked[equipmentId]) return;
  const cost = equipmentUnlockCost(equipmentId);
  if (state.gold < cost) throw badRequest("Not enough gold");
  state.gold -= cost;
  state.equipmentUnlocked[equipmentId] = true;
}

export function upgradeEquipment(state: PlayerState, equipmentId: EquipmentId): void {
  assertEquipment(equipmentId);
  if (!state.equipmentUnlocked[equipmentId]) throw badRequest("Equipment is locked");
  const level = state.equipmentLevels[equipmentId] ?? 0;
  const discount = prestigeMultiplier(state, "craft") - 1;
  const cost = equipmentUpgradeCost(level, discount);
  if (state.gold < cost) throw badRequest("Not enough gold");
  state.gold -= cost;
  state.equipmentLevels[equipmentId] = level + 1;
}

export function upgradeArtifact(state: PlayerState, artifactId: string): void {
  if (!state.ownedArtifacts.includes(artifactId)) throw badRequest("Artifact is not owned");
  const level = state.artifactLevels[artifactId] ?? 0;
  const cost = artifactUpgradeCost(level);
  if (state.essence < cost) throw badRequest("Not enough essence");
  state.essence -= cost;
  state.artifactLevels[artifactId] = level + 1;
}

export function grantApexArtifact(state: PlayerState, wave: number): string | null {
  if (wave % 100 !== 0 || state.defeatedApexWaveRewards.includes(wave)) return null;
  state.defeatedApexWaveRewards.push(wave);
  const unowned = artifactIds.filter((id) => !state.ownedArtifacts.includes(id));
  if (unowned.length === 0) return null;
  const artifactId = unowned[Math.floor(Math.random() * unowned.length)];
  state.ownedArtifacts.push(artifactId);
  state.artifactLevels[artifactId] = Math.max(1, state.artifactLevels[artifactId] ?? 0);
  return artifactId;
}

function assertEquipment(equipmentId: EquipmentId): void {
  if (!equipmentIds.includes(equipmentId)) throw badRequest("Unknown equipment id");
}
