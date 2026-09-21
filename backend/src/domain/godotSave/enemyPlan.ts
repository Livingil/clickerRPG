const enemyBase = {
  maxHp: 30,
  speed: 90,
  attackDamage: 2.6,
  defense: 3,
  evasion: 4,
  accuracy: 80,
  attackRange: 66,
  attackCooldown: 0.9,
  rewardGold: 5,
  rewardEssence: 1
};

const enemyMaxEvasion = 160;
const balanceEarlyCap = 120;
const balanceMidCap = 1200;

const waveRates = {
  hp: [1.010, 1.018, 1.008],
  speed: [1.003, 1.0035, 1.0012],
  damage: [1.006, 1.012, 1.006],
  defense: [1.008, 1.005, 1.0018],
  evasion: [1.004, 1.004, 1.0015],
  accuracy: [1.004, 1.004, 1.0015],
  reward: [1.020, 1.008, 1.002]
};

const post50EnemyPressure = {
  hp: 0.006,
  damage: 0.004,
  defense: 0.004,
  speed: 0.0015,
  evasion: 0.0025,
  accuracy: 0.0025
};

const post50BossPressure = {
  hp: 0.060,
  damage: 0.010,
  defense: 0.020,
  speed: 0.003,
  evasion: 0.005,
  accuracy: 0.005
};

const bossDefs: Record<string, { bossKind: string; hp: number; speed: number; damage: number; gold: number; essence: number }> = {
  wave_boss: { bossKind: "wave", hp: 5.6, speed: 1.04, damage: 1.13, gold: 3.5, essence: 2.0 },
  mini_boss: { bossKind: "mini", hp: 12.8, speed: 1.01, damage: 2.56, gold: 7.0, essence: 4.0 },
  grand_boss: { bossKind: "grand", hp: 30.4, speed: 1.06, damage: 5.40, gold: 12.0, essence: 7.0 },
  apex_boss: { bossKind: "apex", hp: 35.2, speed: 1.21, damage: 6.32, gold: 22.0, essence: 14.0 }
};

const normalTypeMods: Record<string, Record<string, number>> = {
  basic: { bodyRadius: 18 },
  tank: { maxHp: 1.8, speed: 0.65, attackDamage: 1.15, defense: 3.0, evasion: 0.55, rewardGold: 1.5, rewardEssence: 1.2, bodyRadius: 22 },
  fast: { maxHp: 0.65, speed: 1.65, attackDamage: 0.75, evasion: 1.6, rewardGold: 0.9, bodyRadius: 15 },
  ranged: { maxHp: 0.75, speed: 0.9, attackDamage: 0.8, attackRange: 420, attackCooldown: 1.35, rewardGold: 1.2, bodyRadius: 16 }
};

export function buildEnemyConfig(spawnKind: string, wave: number, normalType = "basic") {
  const stats = buildScaledBase(wave);
  const bossDef = bossDefs[spawnKind];
  if (bossDef) return applyBoss(stats, wave, bossDef);
  return applyNormalType(stats, normalType);
}

function buildScaledBase(wave: number) {
  const waveOffset = Math.max(0, wave - 1);
  const stats = {
    maxHp: enemyBase.maxHp * progressiveWaveMultiplier(waveOffset, waveRates.hp) * pressure(wave, post50EnemyPressure.hp),
    speed: enemyBase.speed * progressiveWaveMultiplier(waveOffset, waveRates.speed) * pressure(wave, post50EnemyPressure.speed),
    attackDamage: enemyBase.attackDamage * progressiveWaveMultiplier(waveOffset, waveRates.damage) * pressure(wave, post50EnemyPressure.damage),
    defense: enemyBase.defense * progressiveWaveMultiplier(waveOffset, waveRates.defense) * pressure(wave, post50EnemyPressure.defense),
    evasion: enemyBase.evasion * progressiveWaveMultiplier(waveOffset, waveRates.evasion) * pressure(wave, post50EnemyPressure.evasion),
    accuracy: enemyBase.accuracy * progressiveWaveMultiplier(waveOffset, waveRates.accuracy) * pressure(wave, post50EnemyPressure.accuracy),
    attackRange: enemyBase.attackRange,
    attackCooldown: enemyBase.attackCooldown,
    rewardGold: Math.max(1, Math.round(enemyBase.rewardGold * progressiveWaveMultiplier(waveOffset, waveRates.reward))),
    rewardEssence: Math.round(enemyBase.rewardEssence * progressiveWaveMultiplier(waveOffset, waveRates.reward)),
    waveNumber: wave,
    bodyRadius: 18,
    normalEnemyType: "basic",
    bossKind: "none",
    isBoss: false
  };
  stats.evasion = Math.min(stats.evasion, enemyMaxEvasion);
  return stats;
}

function applyNormalType(stats: ReturnType<typeof buildScaledBase>, normalType: string) {
  const mod = normalTypeMods[normalType] ?? normalTypeMods.basic;
  stats.normalEnemyType = normalTypeMods[normalType] ? normalType : "basic";
  stats.maxHp *= mod.maxHp ?? 1;
  stats.speed *= mod.speed ?? 1;
  stats.attackDamage *= mod.attackDamage ?? 1;
  stats.defense *= mod.defense ?? 1;
  stats.evasion *= mod.evasion ?? 1;
  stats.attackRange *= mod.attackRange ?? 1;
  stats.attackCooldown *= mod.attackCooldown ?? 1;
  stats.rewardGold = Math.max(1, Math.round(stats.rewardGold * (mod.rewardGold ?? 1)));
  stats.rewardEssence = Math.max(1, Math.round(stats.rewardEssence * (mod.rewardEssence ?? 1)));
  stats.bodyRadius = mod.bodyRadius ?? 18;
  return stats;
}

function applyBoss(stats: ReturnType<typeof buildScaledBase>, wave: number, bossDef: typeof bossDefs[string]) {
  stats.maxHp *= bossDef.hp * pressure(wave, post50BossPressure.hp);
  stats.speed *= bossDef.speed * pressure(wave, post50BossPressure.speed);
  stats.attackDamage *= bossDef.damage * pressure(wave, post50BossPressure.damage);
  stats.defense *= 1.5 * pressure(wave, post50BossPressure.defense);
  stats.evasion = Math.min(enemyMaxEvasion, stats.evasion * 1.1 * pressure(wave, post50BossPressure.evasion));
  stats.accuracy *= 1.2 * pressure(wave, post50BossPressure.accuracy);
  stats.rewardGold = Math.max(1, Math.round(enemyBase.rewardGold * progressiveWaveMultiplier(Math.max(0, wave - 1), waveRates.reward) * bossDef.gold));
  stats.rewardEssence = Math.round(stats.rewardEssence * bossDef.essence);
  stats.bossKind = bossDef.bossKind;
  stats.isBoss = true;
  return stats;
}

function progressiveWaveMultiplier(waveOffset: number, rates: number[]) {
  const early = Math.min(waveOffset, balanceEarlyCap);
  const mid = Math.min(Math.max(0, waveOffset - balanceEarlyCap), balanceMidCap - balanceEarlyCap);
  const late = Math.max(0, waveOffset - balanceMidCap);
  return Math.pow(rates[0], early) * Math.pow(rates[1], mid) * Math.pow(rates[2], late);
}

function pressure(wave: number, perWave: number) {
  return 1 + Math.max(0, wave - 50) * perWave;
}
