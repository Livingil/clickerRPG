const echoTiers = [
  { start: 0, step: 30, bonuses: { damage: 0.36, max_hp: 2.4, accuracy: 0.12 } },
  { start: 4000, step: 180, bonuses: { damage: 0.34, max_hp: 1.2, defense: 0.03, attack_speed: 0.00025, crit_chance: 0.00004 } },
  { start: 40000, step: 1400, bonuses: { damage: 0.14, max_hp: 2.0, defense: 0.05, evasion: 0.035, crit_multiplier: 0.00018 } },
  { start: 300000, step: 9000, bonuses: { damage: 0.06, max_hp: 1.0, defense: 0.02, evasion: 0.016, crit_chance: 0.00001, crit_multiplier: 0.00006 } }
];

export function getEchoProgressInfo(echoValue: number) {
  const value = Math.max(0, Math.floor(echoValue));
  let currentIndex = 0;
  for (let i = 0; i < echoTiers.length; i += 1) {
    if (echoTiers[i].start <= value) currentIndex = i;
    else break;
  }

  const currentStep = Math.round(echoTiers[currentIndex].step);
  let nextTarget = Number.MAX_SAFE_INTEGER;
  let nextStep = 0;

  for (let i = 0; i < echoTiers.length; i += 1) {
    const tier = echoTiers[i];
    const nextStart = i + 1 < echoTiers.length ? echoTiers[i + 1].start : Number.MAX_SAFE_INTEGER;
    let candidate = Number.MAX_SAFE_INTEGER;
    if (value < tier.start) {
      candidate = tier.start + tier.step;
    } else {
      const ticksNow = Math.floor((value - tier.start) / tier.step);
      candidate = tier.start + (ticksNow + 1) * tier.step;
      if (nextStart < Number.MAX_SAFE_INTEGER && candidate > nextStart) {
        candidate = tier.start + (ticksNow + 2) * tier.step;
      }
    }
    if (nextStart < Number.MAX_SAFE_INTEGER && candidate > nextStart) continue;
    if (candidate > value && candidate < nextTarget) {
      nextTarget = candidate;
      nextStep = tier.step;
    }
  }

  if (nextTarget === Number.MAX_SAFE_INTEGER) nextTarget = value;
  return {
    current_step: currentStep,
    next_step: nextStep > 0 ? Math.round(nextStep) : currentStep,
    required_echo: Math.round(nextTarget),
    remaining_to_next: Math.max(0, Math.round(nextTarget) - value)
  };
}
