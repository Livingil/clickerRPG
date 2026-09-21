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
- `PUT /api/player/save-data` (development/migration only)
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
Legacy typed routes (`/api/run`, `/api/equipment`, `/api/school`, `/api/offline`, etc.) are mounted only outside production unless `ALLOW_LEGACY_STATE_ROUTES=true`.

## Godot command API

Godot uses `/api/godot/command` for server-authoritative mutations of the same snake_case save data that the client already stores locally. Request body:

```json
{
  "command": "equipment.upgrade",
  "payload": { "equipmentId": "weapon" }
}
```

Response contains `success`, command `result`, and authoritative `saveData`. The client applies returned `saveData` through `GameState.apply_save_data()`.

Supported commands:

- `equipment.unlock`
- `equipment.upgrade`
- `artifact.upgrade`
- `artifact.grantApexReward` (disabled; apex rewards are claimed by apex enemy kill)
- `echo.activate`
- `prestige.perform`
- `prestige.upgrade`
- `school.setActive`
- `school.addXp`
- `school.addXpBatch`
- `school.equipSkill`
- `school.clearSkill`
- `weapon.applySchoolOffer`
- `run.enemyKilled`
- `run.enemyKilledBatch`
- `run.waveChanged` (disabled; use `wave.start`)
- `run.death`
- `offline.claim`
- `wave.start`
- `ad.requestOffer`
- `ad.activateSpeed`
- `ad.activateBoost`
- `dev.resetAll`

Real-time combat is still local/optimistic. Wave start returns server-issued enemy `instanceId` values, and rewards are claimed through `run.enemyKilledBatch` once per id. Direct client-provided reward claims through `run.claimRewards` are disabled. Direct wave mutation through `run.waveChanged` is disabled; wave progress must go through `wave.start`.

School XP is server-capped per event and per minute. Offline rewards use server timestamps. Ad boosts are allow-listed, cooldown-limited, and random ad boosts require server-issued offers.
