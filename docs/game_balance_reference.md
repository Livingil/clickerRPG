# Game Balance Reference

Актуальный документ по текущим балансным параметрам MVP.

Документ фиксирует:
- сущности игры
- боевые характеристики
- формулы
- источники прогрессии
- текущие коэффициенты волн, боссов, школ и навыков

Если цифры меняются в коде, документ тоже нужно обновлять.

## 1. Hero

### Core Stats

- `HP = 100`
  Текущее здоровье героя. Когда падает до `0`, герой умирает и стартует заново с первой волны.
- `Damage = 10`
  Базовый урон одной автоатаки до критов, улучшений и бонусов от смерти.
- `Attack Speed = 1.0`
  Сколько раз в секунду герой атакует.
- `Crit Chance = 0.02`
  Шанс критического удара. `0.10` = `10%`.
- `Crit Multiplier = 1.5`
  Во сколько раз крит усиливает урон. `1.5` = `150%` урона.
- `Defense = 0`
  Плоский параметр защиты. Уменьшает входящий урон через формулу damage reduction.
- `Evasion = 8`
  Уклонение героя. Снижает шанс попадания по герою.
- `Accuracy = 85`
  Меткость героя. Повышает шанс попадания по врагам.

### Utility / Combat Params

- `Move Speed = 185`
  Скорость перемещения героя по арене.
- `Attack Range = 460`
  Радиус поиска цели для базовой автоатаки.
- `Projectile Speed = 560`
  Скорость полета снаряда автоатаки.
- `Flee Distance = 170`
  Если враг подходит ближе этой дистанции, герой пытается отойти.
- `Preferred Distance = 220`
  Комфортная дистанция героя до цели.
- `Strafe Weight = 0.72`
  Насколько сильно герой смещается в сторону при kite-движении.
- `Flee Direction Lock Time = 0.25`
  Сколько времени герой держит уже выбранное направление отхода, чтобы не дрожать каждый кадр.
- `Orbit Switch Interval = 0.9 .. 1.8 sec`
  Интервал, через который герой может поменять сторону орбиты вокруг врагов.

### Final Hero Stats Formula

Финальные боевые статы героя собираются так:

- `final_damage = base_damage + gold_upgrade_damage + active_echo_damage`
- `final_attack_speed = base_attack_speed + gold_upgrade_attack_speed + active_echo_attack_speed`
- `final_crit_chance = clamp(base_crit_chance + gold_upgrade_crit_chance, 0, 1)`
- `final_crit_multiplier = max(1.0, base_crit_multiplier + gold_upgrade_crit_multiplier)`
- `final_max_hp = base_hp + echo_hp_bonus`
- `final_defense = base_defense + echo_defense_bonus`
- `final_evasion = base_evasion + echo_evasion_bonus`
- `final_accuracy = base_accuracy + echo_accuracy_bonus`

Пояснение:
- `base_*` — стартовые характеристики героя
- `gold_upgrade_*` — бонусы от апгрейдов за золото
- `active_echo_*` — активные бонусы после прошлых смертей

### Hero DPS Formula

`dps = damage * attack_speed * (1 + crit_chance * (crit_multiplier - 1))`

Пояснение:
- это теоретический средний DPS без учета движения, потерь по дистанции и навыков

### Auto Attack

- герой автоматически ищет ближайшего врага в радиусе `460`
- если атака готова, выпускает projectile
- кулдаун автоатаки:

`attack_cooldown = 1 / attack_speed`

Пояснение:
- чем выше `attack_speed`, тем меньше пауза между выстрелами

### Projectile

- projectile летит к цели
- при контакте наносит `school damage`
- school damage проходит через vulnerability текущей школы

Пояснение:
- базовая атака посохом считается атакой активной школы

### Hit Chance Formula

`hit_chance = clamp(0.6 + (accuracy - evasion) * 0.004, 0.15, 0.98)`

Пояснение:
- и герой, и враги используют одну и ту же формулу попадания

### Defense Formula

`final_damage = raw_damage * (100 / (100 + defense))`

Пояснение:
- защита режет входящий урон плавно, без полного иммунитета

## 2. Enemies

### Base Enemy Stats

- `HP = 30`
  Базовое здоровье обычного врага на `Wave 1`.
- `Speed = 90`
  Базовая скорость движения к герою.
- `Damage = 6`
  Базовый урон одной атаки врага.
- `Defense = 0`
  Снижает входящий урон от героя.
- `Evasion = 4`
  Снижает шанс попадания по врагу.
- `Accuracy = 80`
  Повышает шанс попадания врага по герою.
- `Attack Range = 66`
  Дистанция, на которой враг может ударить героя.
- `Attack Cooldown = 0.9`
  Пауза между атаками врага.
- `Gold Reward = 5`
  Базовая награда золотом за убийство.
- `Essence Reward = 1`
  Базовая награда essence за убийство.
- `Body Radius = 18`
  Используется для позиционирования и ограничений в пределах арены.

### Enemy Attack Behavior

- враг идет к герою
- если вошел в радиус атаки и кулдаун прошел, бьет героя
- урон врага прямой, без крита

## 3. Wave Scaling

### Per-Wave Multipliers

Для любой волны `wave`:

- `hp_multiplier = 1.24^(wave - 1)`
- `speed_multiplier = 1.05^(wave - 1)`
- `damage_multiplier = 1.16^(wave - 1)`
- `defense_multiplier = 1.08^(wave - 1)`
- `evasion_multiplier = 1.03^(wave - 1)`
- `accuracy_multiplier = 1.04^(wave - 1)`
- `reward_multiplier = 1.12^(wave - 1)`

Пояснение:
- каждая новая волна делает врагов толще, быстрее, опаснее и чуть выгоднее

### Normal Enemy Formulas

- `enemy_hp = 30 * 1.24^(wave - 1)`
- `enemy_speed = 90 * 1.05^(wave - 1)`
- `enemy_damage = 6 * 1.16^(wave - 1)`
- `enemy_defense = 0 * 1.08^(wave - 1)`
- `enemy_evasion = 4 * 1.03^(wave - 1)`
- `enemy_accuracy = 80 * 1.04^(wave - 1)`
- `enemy_gold = round(5 * 1.12^(wave - 1))`
- `enemy_essence = round(1 * 1.12^(wave - 1))`

### Normal Enemy Count Per Wave

`normal_enemy_count = 4 + floor((wave - 1) / 2) + (wave - 1)`

Пояснение:
- кроме усиления статов, волна еще и повышает количество обычных мобов

Примеры:
- `Wave 1 = 4`
- `Wave 2 = 5`
- `Wave 3 = 7`

## 4. Bosses

### Wave Boss

Появляется в каждой волне вместе с первым обычным врагом.

Множители поверх волновой базы:

- `HP x4.5`
- `Speed x0.9`
- `Damage x1.8`
- `Gold x3.5`
- `Essence x2.0`

Пояснение:
- это постоянный pressure-босс каждой волны

### Mini Boss

Появляется после полной зачистки каждой `5`, `15`, `25`... волны.

Множители:

- `HP x8.0`
- `Speed x0.88`
- `Damage x2.6`
- `Gold x7.0`
- `Essence x4.0`

Пояснение:
- это промежуточная стена прогресса каждые 5 волн

### Grand Boss

Появляется после полной зачистки каждой `10`, `20`, `30`... волны.

Множители:

- `HP x13.0`
- `Speed x0.92`
- `Damage x3.8`
- `Gold x12.0`
- `Essence x7.0`

Пояснение:
- это более серьезная веха прогресса, чем mini boss

### Simultaneous Enemies On Map

- `base_max_active_enemies = 5`
- `+1 active enemy every 5 waves`

Формула:

`max_active_enemies = 5 + floor((wave - 1) / 5)`

## 5. Resources

### Main Resources

- `Gold`
  Временная валюта забега для покупки run-upgrades.
- `Essence`
  Сейчас тоже выдается врагами; позже может быть использована глубже в мета-прогрессии.
- `Echo Collected`
  Временный накопленный бонус текущего захода, который активируется только после смерти.
- `Echo Power`
  Уже активированный бонус от прошлых смертей.

### Gold / Essence

- выдаются за убийства врагов
- скейлятся от волны через `reward_multiplier`

## 6. Gold Upgrades

Четыре run-upgrade:

- `Damage`
- `Attack Speed`
- `Crit Chance`
- `Crit Mult`

Пояснение:
- это временные усиления текущего цикла до prestige

Текущее состояние:
- в текущем баланс-проходе gold upgrades временно отключены из gameplay UI
- gold сохраняется как ресурс, но не тратится на статы

### Upgrade Formulas

#### Damage

- `base_cost = 20`
- `cost_scale = 1.35`
- `value_per_level = 1.5`

Цена:

`cost = round(20 * 1.35^level)`

Бонус:

`gold_upgrade_damage = level * 1.5`

Пояснение:
- усиливает каждую автоатаку и навыки, которые используют базовый damage героя

#### Attack Speed

- `base_cost = 25`
- `cost_scale = 1.4`
- `value_per_level = 0.04`

Цена:

`cost = round(25 * 1.4^level)`

Бонус:

`gold_upgrade_attack_speed = level * 0.04`

Пояснение:
- повышает частоту базовых атак

#### Crit Chance

- `base_cost = 30`
- `cost_scale = 1.45`
- `value_per_level = 0.0075`

Цена:

`cost = round(30 * 1.45^level)`

Бонус:

`gold_upgrade_crit_chance = level * 0.0075`

Пояснение:
- это `0.75%` крита за уровень

#### Crit Mult

- `base_cost = 40`
- `cost_scale = 1.5`
- `value_per_level = 0.05`

Цена:

`cost = round(40 * 1.5^level)`

Бонус:

`gold_upgrade_crit_multiplier = level * 0.05`

Пояснение:
- увеличивает силу уже выпавшего крита

## 7. Death / Echo System

### Echo Gain

- normal enemy: `+1 echo`
- wave boss: `+2 echo`
- mini boss: `+6 echo`
- grand boss: `+12 echo`

### Echo Behavior

- `echo_collected` копится в текущем заходе
- `echo_power` — уже активный бонус
- при смерти:
  - `echo_power += echo_collected`
  - `echo_collected = 0`
- при prestige:
  - `echo_collected = 0`
  - `echo_power = 0`

Пояснение:
- собранный Echo не усиливает героя сразу
- он становится силой только после смерти

### Active Echo Bonuses

- `active_echo_hp = echo_power * 0.35`
- `active_echo_damage = echo_power * 0.05`
- `active_echo_attack_speed = floor(echo_power / 40) * 0.01`
- `active_echo_crit_chance = floor(echo_power / 80) * 0.0025`
- `active_echo_crit_multiplier = floor(echo_power / 100) * 0.01`
- `active_echo_defense = echo_power * 0.12`
- `active_echo_evasion = echo_power * 0.05`
- `active_echo_accuracy = echo_power * 0.08`

Пояснение:
- echo теперь усиливает все основные параметры героя, но малыми шагами
- урон, hp, defense, evasion, accuracy растут плавно
- crit и attack speed растут ступенчато

### Collected Echo Preview

- `after_death_hp_bonus = echo_collected * 0.35`
- `after_death_damage_bonus = echo_collected * 0.05`
- `after_death_attack_speed_bonus = floor(echo_collected / 40) * 0.01`
- `after_death_crit_chance_bonus = floor(echo_collected / 80) * 0.0025`
- `after_death_crit_multiplier_bonus = floor(echo_collected / 100) * 0.01`
- `after_death_defense_bonus = echo_collected * 0.12`
- `after_death_evasion_bonus = echo_collected * 0.05`
- `after_death_accuracy_bonus = echo_collected * 0.08`

Пояснение:
- это прогноз того, каким станет бонус после следующей смерти

## 8. Death Loop

При смерти героя:

- враги очищаются
- волна сбрасывается на `Wave 1`
- герой возвращается в стартовую точку
- HP восстанавливается
- gold upgrades сохраняются
- equipped skills сохраняются
- active school сохраняется
- `echo_collected` переводится в `echo_power`

Пояснение:
- смерть не является полным поражением, а частью цикла усиления

## 9. Prestige

Сейчас prestige делает hard reset run-слоя:

- `gold = 0`
- `essence = 0`
- `echo_collected = 0`
- `echo_power = 0`
- все gold upgrades сбрасываются

При этом школьный mastery на аккаунте остается.

Пояснение:
- prestige — постоянный meta-reset слой, а не обычный restart после смерти

## 10. Schools

### Current Schools

- `Fire`
- `Water`
- `Earth`
- `Air`
- `Lightning`

### School Core Rule

Автоатака посохом = автоатака текущей школы.

Каждое попадание school-hit:
- наносит school damage
- накладывает `1 stack` vulnerability этой школы

Пояснение:
- выбор школы влияет на тип урона, набор навыков и путь mastery

## 11. Vulnerability System

### Rules

- `+4% damage` от этой школы за stack
- максимум `5 stacks`
- длительность `4 sec`
- новое попадание обновляет таймер

### Formula

`school_damage_multiplier = 1.0 + stacks * 0.04`

Примеры:
- `1 stack = x1.04`
- `3 stacks = x1.12`
- `5 stacks = x1.20`

Пояснение:
- vulnerability усиливает урон только соответствующей школы

## 12. School Mastery

### Skill Unlock Levels

- `Lv1` -> Skill 1
- `Lv5` -> Skill 2
- `Lv10` -> Skill 3

### Core Mastery XP Thresholds

- `Lv1 = 20 XP`
- `Lv2 = 200 XP`
- `Lv3 = 1,000 XP`
- `Lv4 = 3,000 XP`
- `Lv5 = 7,000 XP`
- `Lv6 = 15,000 XP`
- `Lv7 = 30,000 XP`
- `Lv8 = 60,000 XP`
- `Lv9 = 120,000 XP`
- `Lv10 = 240,000 XP`

Пояснение:
- `Lv1` специально быстрый, чтобы игрок рано получил первый навык
- дальше рост становится долгим meta-progression слоем

### Post-10 Mastery

После `Lv10` mastery продолжается бесконечно:

- `post_10_level_step = 120,000 XP`

Пояснение:
- это бесконечный хвост прогрессии после полного освоения школы

### Mastery XP Sources

- school auto attack hit: `+1 XP`
- school skill cast:
  - `Ember Chain = +3 XP`
  - `Cinder Burst = +3 XP`
  - `Ash Storm = +5 XP`
- boss kill:
  - wave boss: `+10 XP`
  - mini boss: `+25 XP`
  - grand boss: `+60 XP`

## 13. Skill Slots

Permanent account skill slots:

- `Slot 1 = immediately unlocked`
- `Slot 2 = Wave 20`
- `Slot 3 = Wave 30`
- `Slot 4 = Wave 50`

Правила:
- skill нужно вручную экипировать в slot
- skill не активируется автоматически при unlock
- equipped skills не сбрасываются при смерти

Пояснение:
- это постоянный account progression слой, а не временная механика волны

## 14. Fire School

### Fire Core

- school id: `fire`
- core label: `Burning Staff`
- роль: стабильное давление, burn-style pressure, wave clear

Пояснение:
- огонь должен хорошо чувствовать себя против групп врагов и в постоянном давлении

### Fire Skill 1: Ember Chain

- unlock: `Lv1`
- cooldown: `3.0 sec`
- cast_range: `420`
- chain_range: `260`

Поведение:
- ищет primary target
- если второй цели нет:
  - бьет одну цель усиленным ударом
  - `single_target_ratio = 1.15`
- если вторая цель есть:
  - бьет primary и chain target
  - `chain_ratio = 1.0`
- всегда рисует огненную линию от героя
- если есть вторая цель:
  - линия: `hero -> target1 -> target2`

Пояснение:
- это базовый ранний offensive skill школы огня

### Fire Skill 2: Cinder Burst

- unlock: `Lv5`
- cooldown: `5.5 sec`
- cast_range: `420`
- splash_range: `170`
- splash_ratio: `0.9`

Поведение:
- выбирает primary target
- наносит AoE урон всем врагам вокруг цели
- создает огненное burst-ring VFX

Пояснение:
- это навык wave-clear и давления по плотной пачке

### Fire Skill 3: Ash Storm

- unlock: `Lv10`
- cooldown: `8.0 sec`
- cast_range: `480`
- storm_radius: `170`
- storm_ratio: `1.25`

Поведение:
- выбирает primary target
- создает огненную storm-zone вокруг цели
- наносит school damage всем врагам внутри радиуса
- дает отдельный hero cast pulse и area VFX

Пояснение:
- это сильный late-skill текущей школы огня

## 15. Current UI-Relevant Combat Values

Постоянно отображаются:

- `Gold`
- `Essence`
- `Wave`
- `DPS`
- `HP`
- `Echo / Active Echo`
- `School / Mastery / Slot count`

Bottom sheet tabs:

- `Skills`
- `Upgrades`
- `Run`

Пояснение:
- header должен показывать только high-signal значения
- operational UI живет в bottom sheet

## 16. Current Balance Intent

Текущий баланс движется к infinite idle loop:

- герой усиливается через:
  - gold upgrades
  - school mastery / skills
  - death loop через echo
- враги усиливаются через:
  - wave HP scaling
  - wave damage scaling
  - wave count scaling
  - milestone bosses

Цель системы:
- игрок всегда может сделать новый заход немного сильнее
- но wave scaling со временем должен снова перегонять его
- это создает бесконечный цикл:
  - прогресс
  - стена
  - смерть
  - усиленный restart
  - новый прогресс

Пояснение:
- игра не должна “проходиться окончательно”
- она должна постоянно возвращать игрока в новый цикл усиления
