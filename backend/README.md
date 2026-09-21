# ClickerRPG Backend

Authoritative backend for player progress, economy, saves, prestige, equipment, artifacts, schools, ads, and offline rewards.

## Start

```bash
npm install
cp .env.example .env
npm run dev
```

MongoDB must be available at `MONGO_URI`.

Local MongoDB through Docker:

```bash
docker compose up -d
```

## Main API

- `GET /health`
- `POST /api/auth/dev-login`
- `GET /api/player/save-data`
- `PUT /api/player/save-data` (development/migration only; not mounted in production)
- `POST /api/godot/command`
- `GET /api/player/state`
- `POST /api/run/start`
- `POST /api/run/wave-complete`
- `POST /api/run/enemy-killed`
- `POST /api/run/death`
- `POST /api/equipment/unlock`
- `POST /api/equipment/upgrade`
- `POST /api/artifact/upgrade`
- `POST /api/echo/activate`
- `POST /api/prestige/perform`
- `POST /api/prestige/upgrade`
- `POST /api/school/set-active`
- `POST /api/school/skill-used`
- `POST /api/school/equip-skill`
- `POST /api/ad/claim-boost`
- `POST /api/offline/claim`

`POST /api/auth/dev-login` returns `sessionToken`. Pass it as `Authorization: Bearer <sessionToken>`.
The insecure `x-player-id`/`?playerId=` fallback is only for development unless `ALLOW_INSECURE_PLAYER_ID_HEADER=true`.
Legacy typed routes (`/api/run`, `/api/equipment`, `/api/school`, `/api/offline`, etc.) are development compatibility routes. They are mounted only when `NODE_ENV !== "production"` and `ALLOW_LEGACY_STATE_ROUTES=true`.

## Godot command API

Godot uses `/api/godot/command` for server-authoritative mutations of the same snake_case save data that the client already stores locally. Request body:

```json
{
  "command": "equipment.upgrade",
  "payload": { "equipmentId": "weapon" },
  "expectedServerRevision": 12,
  "includeSaveData": true
}
```

Response contains `success`, command `result`, `serverRevision`, and authoritative `saveData` unless `includeSaveData` is `false`. The client applies returned `saveData` through `GameState.apply_save_data()`. Frequent commands such as enemy kill batches and school XP events use compact responses with server deltas and advance `serverRevision`.

Supported commands:

- `equipment.unlock`
- `sync.snapshot`
- `equipment.upgrade`
- `artifact.upgrade`
- `artifact.grantApexReward` (disabled; apex rewards are claimed by apex enemy kill)
- `echo.activate`
- `prestige.perform`
- `prestige.upgrade`
- `school.setActive`
- `school.addXp` (development only in production-like authority flow)
- `school.addXpBatch` (development only in production-like authority flow)
- `school.addXpEvents`
- `school.equipSkill`
- `school.clearSkill`
- `weapon.applySchoolOffer`
- `run.enemyKilled`
- `run.enemyKilledBatch`
- `run.waveChanged` (disabled; use `wave.start`)
- `run.death`
- `offline.claim`
- `wave.start`
- `wave.complete`
- `ad.requestOffer`
- `ad.activateSpeed`
- `ad.activateBoost`
- `dev.resetAll`

Real-time combat stays local by default. The old remote combat resolver is disabled in production because it accepts client-provided combat stats; it can be enabled only as a debug aid. Wave start returns server-issued enemy `instanceId` values, and rewards are claimed through `run.enemyKilledBatch` once per id. Wave progress must be confirmed with `wave.complete`, which checks required enemy claims and a soft server-estimated clear-time floor. Direct client-provided reward claims through `run.claimRewards` are disabled. Direct wave mutation through `run.waveChanged` is disabled.

School XP uses allow-listed event types (`hit`, `skill_minor`, `skill_major`) and is capped per minute. Offline rewards use server timestamps. Ad boosts are allow-listed, cooldown-limited, and random ad boosts require server-issued offers.
