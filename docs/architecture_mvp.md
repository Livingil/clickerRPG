# MVP Architecture

## Runtime Split

- `autoload/` holds shared runtime state, constants, signals, and save/load.
- `scripts/core/` holds reusable progression and combat formula helpers.
- `scenes/gameplay/` holds combat orchestration, wave flow, and battlefield ownership.
- `scenes/hero/`, `scenes/enemies/`, `scenes/abilities/` keep actor logic isolated by domain.
- `scenes/ui/` reads `GameState` and issues explicit commands such as equip, upgrade, settings, and prestige.

## Runtime Composition

- `Main` composes `GameplayRoot` and `HUD`.
- `GameplayRoot` wires hero attacks into the ability system, injects hero and battlefield into the spawner, and resets the run after death.
- `Battlefield` owns containers for enemies, projectiles, and visual effects.
- `Hero` owns HP and delegates stats, movement, and attack cadence to components.
- `EnemySpawner` owns active enemy instances and asks `WaveController` what to spawn.
- `WaveController` owns wave progression, boss milestones, timed challenges, farm mode, and retry flow.
- `MilestoneChallengeController` owns timed milestone challenge state, farm-mode fallback, skipped milestones, and retry requests.
- `WaveEnemyTypeRules` owns normal enemy availability, weighted type selection, and mono-wave rolls.
- `EnemyWaveScaler` applies wave, enemy, and boss stat/reward scaling to spawned enemies.
- `Enemy` owns movement, HP, vulnerability stacks, burn, attacks, death, and reward emission.

## Global State

- `GameState` owns account/run resources, echo, schools, mastery, equipped skills, equipment, artifacts, combat text settings, language, and a derived bonus-total snapshot.
- `ArtifactRules` owns artifact ids, coefficients, display names, and effect summaries.
- `ArtifactProgressService` owns artifact upgrade costs, purchase mutation, random unowned grants, UI rows, and derived bonus totals.
- `EquipmentRules` owns equipment ids, unlock costs, upgrade costs, display names, and milestone texts.
- `EquipmentProgressRules` owns derived equipment formulas, weapon school offer rolls/text, soft-cap helpers, hero move speed, regen, block, reflect, haste, repeat, teleport, and clone values.
- `EquipmentProgressService` owns equipment unlock and upgrade mutations.
- `EquipmentPresentationRules` owns equipment menu summaries and short/expanded UI text composition.
- `InventoryProgressService` owns inventory purchase/reward orchestration, result application, equipment menu rows, and related signal emission.
- `PrestigeRules` owns prestige unlock wave, tree branch definitions, shard formula, prestige multipliers, and prestige milestone texts.
- `PrestigeService` owns prestige preview reports, prestige shard state transitions, full prestige execution, prestige upgrade purchases, prestige panel data, and derived prestige multipliers.
- `GameStateSaveAdapter` owns concrete save schema build/apply and save-specific parsing of skill and weapon-offer data.
- `GameStateLifecycleService` owns default dictionary initialization and full signal refresh after save loading.
- `WaveProgressService` owns saved wave-record mutation and one-time wave progress info event emission.
- `ProgressResetService` owns run and development full-reset state mutation; `GameState` keeps signal emission after reset.
- `AdBoostRules` owns ad boost ids, offer timing, random offer pool, durations, names, and short labels; `GameState` stores active timers.
- `EchoRules` owns Echo tier progression, next-bonus progress, and Echo bonus summary formatting.
- `EchoProgressService` owns Echo activation, state/signal application, and public Echo bonus snapshots/summaries.
- `SaveDataCodec` owns save-data migration and generic serialization/parsing helpers for arrays and dictionaries.
- `LocalizationRules` owns static UI translation strings and locale fallback.
- `SchoolProgressRules` owns school mastery summaries, mastery bonuses, level-up reports, unlocked skill pool, and skill-slot trimming rules.
- `SchoolStateService` owns school mastery XP mutation, active-school switching, skill-slot equip/replace/clear, rebuilt school state snapshots, and related state/signal application.
- `ProgressInfoEventService` owns one-time progress info event construction for wave milestones, skill slots, and prestige unlock.
- `AdBoostStateRules` owns ad boost offer snapshots, active boost timer transforms, and saved boost restore rules.
- `AdBoostService` owns ad offer lifecycle, accept/dismiss flow, active boost activation, reward multiplier checks, and related state/signal application.
- `OfflineRewardService` owns offline reward estimation, offline wave reward composition, and Echo gain per enemy kind.
- `ResourceProgressService` owns resource gain transforms/application, run-death counters, offline reward application, and the public Echo reward bridge.
- `PlayerBonusBuilder` owns aggregation of upgrade, equipment, and artifact progress and applies those totals to stored player bonus fields.
- `HeroStatsBuilder` owns final `CombatStats` composition and game-state stat snapshots from base bonuses, Echo, prestige, and active ad stat boosts.
- `RunDeathReportBuilder` owns the death report snapshot comparing hero power before and after collected Echo is activated, plus report state/signal application.
- `SkillPowerService` owns active skill damage/cooldown/proc multipliers, weapon school offer state transitions, and related state/signal application.
- `EquipmentCombatProcService` owns runtime equipment combat procs: block, reflect, repeat, haste, teleport, clone, regen, move-speed reads, and proc-state application.
- `GameConstants` owns static combat constants and scaling curves.
- `EnemyTypeRules` owns normal enemy type modifiers and base visual geometry; `Enemy` applies those rules to live actor state.
- `EnemyBossUiRules` owns boss tag text and color mapping for enemy visuals.
- `EnemyStatusUiRules` owns enemy status label codes for school stacks.
- `EnemySchoolEffectRules` owns enemy-side formulas for school stack multipliers, burn damage, and freeze duration.
- `EnemyVisualFeedback` owns enemy hit flash, floating combat text, and death burst spawning.
- `EnemyProjectileAttack` owns ranged enemy projectile spawning and fallback contact-hit behavior.
- `HudPanelRouter` owns HUD tab/popup visibility and pressed footer-button state; `HUD` wires signals and delegates navigation.
- `HudReportTextBuilder` owns localized HUD report and info-popup text composition; `HUD` displays already built messages.
- `PowerReportPopupController` owns the death/prestige rich-text report popup lifecycle.
- `AfkRewardPopupController` owns the offline reward popup lifecycle and clears pending offline reports on close.
- `SchoolLevelPopupController` owns the school-level reward popup and emits an explicit open-skills request.
- `AdBoostHudController` owns the ad offer buttons, active boost indicator, and ad-button flight animation.
- `MonoWaveAlertController` owns the centered mono-wave warning label, timing, and localized enemy type names.
- `AbilityPanelTextBuilder` owns ability panel descriptions, tooltips, current school bonus text, and next unlock text.
- `AbilityTileUiRules` owns ability tile icon loading and reusable tile style rules.
- `UpgradePanel` builds equipment/artifact rows from `GameState` presentation data and keeps purchase/unlock actions explicit.
- `SignalBus` is used for cross-domain events that should not create direct node references.
- `SaveSystem` persists `GameState` to `user://save_game.json`, loads it on startup, supports explicit save/load paths for smoke tests, and debounces autosaves from state-change signals.

## Implemented Progression

- Fire abilities are implemented as active combat skills.
- Other school skills use a generic school-damage runtime until their unique VFX and mechanics are implemented.
- Equipment and artifacts are the current main upgrade surfaces.
- Legacy gold stat upgrades were removed from runtime; equipment, artifacts, schools, and prestige are the active progression surfaces.
- Prestige is gated by highest reached wave `50`.
- The prestige panel also has a temporary development-only "start over" reset for fast testing.

## Next Planned Additions

- Real migration steps when save data moves beyond version `1`.
- Unique ability implementations for Water, Earth, Air, and Lightning.
- Further split of `GameState` into smaller progression/economy/localization services if the project keeps growing.
- Offline progress.

## Fast Checks

- Main scene load: `Godot --headless --path . --quit-after 2`.
- Save smoke: run `res://scenes/dev/save_smoke_runner.tscn`.
