# School System MVP

## Core Structure

- Player chooses one active school on `Rebirth`.
- Death does not change school or equipped skills.
- School mastery is permanent on the account.
- Skill slots are permanent on the account and unlock at highest reached waves:
  - slot 1 at wave 10
  - slot 2 at wave 20
  - slot 3 at wave 30
  - slot 4 at wave 50

## Base Combat Rule

- Staff auto attack is the school's auto attack.
- Every hit applies 1 stack of that school's elemental vulnerability.
- Vulnerability:
  - +4% damage from that school per stack
  - 5 stack cap
  - 4 second duration
  - hits refresh duration

## Mastery Structure

- Each school has 10 core mastery levels.
- School skills unlock at:
  - level 1 -> skill 1
  - level 5 -> skill 2
  - level 10 -> skill 3
- At level 10, all 3 skills of that school enter the global skill pool for future rebirths.
- After level 10, mastery continues infinitely for small eternal bonuses.

## Mastery XP Sources

- school auto attack hit
- school skill trigger
- boss kills with active school

## Schools

### Fire
- Role: burn pressure, spread, stable wave clear
- Core: fire hit + fire vulnerability
- Skill 1: Ember Chain
- Skill 2: Cinder Burst
- Skill 3: Ash Storm
- Post-10 direction: burn potency and fire damage

### Water
- Role: slow, control, sustain, freezing tempo
- Core: water hit + water vulnerability
- Skill 1: Frost Orb
- Skill 2: Tidal Pulse
- Skill 3: Glacial Field
- Post-10 direction: chill potency and water damage

### Earth
- Role: heavy hits, armor break, durable pressure
- Core: earth hit + earth vulnerability
- Skill 1: Stone Spike
- Skill 2: Quake Ring
- Skill 3: Bastion Crash
- Post-10 direction: armor break and earth damage

### Air
- Role: tempo, multihit, mobility-style pressure
- Core: air hit + air vulnerability
- Skill 1: Razor Gust
- Skill 2: Cyclone Arc
- Skill 3: Sky Flurry
- Post-10 direction: air attack speed and multihit chance

### Lightning
- Role: burst, chain hits, crit/proc play
- Core: lightning hit + lightning vulnerability
- Skill 1: Spark Jump
- Skill 2: Volt Lance
- Skill 3: Thunder Crown
- Post-10 direction: chain efficiency and lightning damage
