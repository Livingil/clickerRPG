# Balance Check Runbook

Короткий чеклист для повторяемой проверки баланса без лишних шагов и без длинных логов.

## 1. Что запускать

- Основной раннер: `res://scenes/dev/balance_report_runner.tscn`
- Генератор данных: `BalanceSimulator.run_multi_profiles(...)`
- Профили:
1. `cheapest`
2. `balanced`
3. `proc_focus`

## 2. Команда запуска (Windows, headless)

```powershell
& 'C:\Users\Владимир\Downloads\Godot_v4.6.2-stable_win64_console.exe' --headless --path . res://scenes/dev/balance_report_runner.tscn
```

Результаты сохраняются в `user://`:
1. `balance_report_multi.json`
2. `balance_report_multi.csv`

## 3. Быстрый режим (для экономии лимитов)

Использовать, когда нужен только sanity-check:
1. Не печатать все ряды в консоль (раннер уже печатает только summary).
2. Смотреть только финальные строки CSV по профилям:

```powershell
Get-Content "$env:APPDATA\Godot\app_userdata\clickerRPG\balance_report_multi.csv" | Select-Object -Last 6
```

3. Смотреть только ключевые волны (`1000`, `1500`, `2000`):

```powershell
Import-Csv "$env:APPDATA\Godot\app_userdata\clickerRPG\balance_report_multi.csv" |
  Where-Object { $_.wave -in 1000,1500,2000 } |
  Format-Table profile,wave,hero_dps,normal_ttk,apex_ttk,gold,essence,weapon,helm,chest,gloves,boots,ring,amulet,relic
```

## 4. Полный режим (когда нужно дебажить перекос)

1. Сравнить расход/доход по wave:

```powershell
Import-Csv "$env:APPDATA\Godot\app_userdata\clickerRPG\balance_report_multi.csv" |
  Format-Table profile,wave,wave_gold_income,wave_gold_spent,wave_essence_income,wave_essence_spent
```

2. Проверить, не застрял ли профиль в 1-2 слотах:
- если `ring/boots/relic` долго остаются `0`, профиль не раскрывает proc-механики;
- если `wave_essence_income >> wave_essence_spent`, лимит трат essence слишком низкий.

## 5. Минимальный шаблон анализа

После прогона фиксировать 5 пунктов:
1. `normal_ttk` и `apex_ttk` на волнах `1000/1500/2000`.
2. Какие слоты экипа реально качаются в каждом профиле.
3. Баланс доход/расход по `gold` (нет ли больших пил и провалов).
4. Баланс доход/расход по `essence` (нет ли runaway запаса).
5. Какой профиль ближе к целевому gameplay-loop.

## 6. Локальные правки для экспериментов

Основные точки:
1. `scripts/dev/balance_simulator.gd`:
   - `PROFILE_CONFIGS[*].weights`
   - `gold_spend_limit`
   - `essence_spend_limit`
2. `scripts/dev/balance_report_runner.gd`:
   - `MAX_WAVE`
   - `STEP`

## 7. Базовый критерий "ОК"

Для текущего infinite-loop ориентир:
1. `normal_ttk` не уходит в слишком долгое значение (комфортный бой).
2. `apex_ttk` растет плавно, без резких скачков.
3. Профиль `balanced` не игнорирует proc-слоты в late-game.
4. Запас essence не взрывается без возможности трат.
