# Куда класть арт

Сейчас всё нарисовано цветными заглушками (GradientTexture2D). Чтобы подставить свой арт:
открой сцену, выбери `Sprite2D`, перетащи png в поле **Texture**. Размеры коллизий подгони под рисунок.

| Что | Сцена | Что подправить |
|---|---|---|
| Буханка (заглушка 160×48, лежит горизонтально) | `scenes/Bread.tscn` | `Sprite2D.texture` и размер `CollisionShape2D`. Из неё получается `max_cuts` кусков, каждый разрез отрезает 1/8 длины справа |
| Кусок хлеба (20×44) | `scenes/breadslice.tscn` | `Sprite2D`, `CollisionShape2D` |
| Кубик сахара (12×12) | `scenes/sugarcube.tscn` | `Sprite2D`, `CollisionShape2D` |
| Нож (12×100, лезвие внизу) | `scenes/knife.tscn` | `Sprite2D`; `bladearea/CollisionShape2D` — зона, которой режем |
| Ложка (14×60) | `scenes/spoom.tscn` | `Sprite2D`; узел **Tip** — кончик, им мешаем, передвинь его на кончик ложки |
| Банка | `scenes/glassjar.tscn` | `back` (задняя стенка) и `front` (стекло поверх) — пустые `Sprite2D`, просто задай Texture. Вода: `ColorRect` и `WaterZone/wattercol` |
| Стол | `scenes/game.tscn` → `table/Sprite2D` | texture 1150×24 |
| Банка с сахаром | `scenes/game.tscn` → `sugarcan/Sprite2D` | уже есть `sugarcan.png` |
| Музыка | `assets/sfx/*.ogg` | подключена в `game.tscn` и `menu.tscn` узлом `MusicPlayer` |

## Слои физики (Project Settings → Layer Names)
1. `world` — стол, стены, стенки банки
2. `items` — хлеб, куски, сахар
3. `tools` — нож и ложка (сталкиваются только с миром, поэтому проходят сквозь хлеб)

## Настройки «на ощупь» (Inspector у любого предмета)
`follow_speed` — резвость, `max_accel` — «тяжесть» (меньше = тяжелее), `upright_strength` — насколько нож/ложка держат вертикаль.
У ножа `bladearea → min_cut_speed` — с какой скорости взмах режет. У банки `laps_needed` — сколько кругов ложкой до готового кваса.
