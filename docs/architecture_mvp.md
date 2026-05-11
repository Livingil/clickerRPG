# MVP Architecture

## Runtime Split

- `autoload/` holds global runtime state and global constants.
- `scenes/gameplay/` holds combat orchestration and battlefield ownership.
- `scenes/hero/`, `scenes/enemies/`, `scenes/abilities/` keep actor logic isolated by domain.
- `scenes/ui/` stays read-only toward gameplay state, except for explicit commands later.

## First Vertical Slice

- `Main` composes `GameplayRoot` and `HUD`.
- `GameplayRoot` wires hero attacks into the ability system and injects hero into the spawner.
- `Hero` owns stats and attack cadence.
- `EnemySpawner` owns enemy lifecycle and active enemy count.
- `Enemy` owns movement, HP, death, and rewards.

## Next Planned Additions

- upgrade panel
- ability unlocks and effect scenes
- wave progression rules
- offline progress and save/load
- prestige reset flow
