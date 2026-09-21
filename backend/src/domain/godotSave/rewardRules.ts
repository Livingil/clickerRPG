export function echoGainForEnemy(bossKind: string, wave: number) {
  const rewardCurve = progressiveRewardMultiplier(wave);
  const rewardMultiplier = Math.pow(rewardCurve, 0.72);
  const kindMultiplier = bossKind === "wave" ? 1.6
    : bossKind === "mini" ? 3.2
      : bossKind === "grand" ? 5.5
        : bossKind === "apex" ? 9.0
          : 1.0;
  return Math.max(1, Math.round(rewardMultiplier * kindMultiplier * 0.42));
}

export function progressiveRewardMultiplier(wave: number) {
  return Math.pow(1.020, Math.min(Math.max(0, wave - 1), 120))
    * Math.pow(1.008, Math.min(Math.max(0, wave - 121), 1080))
    * Math.pow(1.002, Math.max(0, wave - 1201));
}
