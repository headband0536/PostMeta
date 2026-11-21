## Module ID: zoro

Катаны можно держать в зубах (слот маски): речь мычит как под скотчем, а бег с катаной во рту иногда режет щёку на долю `force` катаны. Шагом можно ходить безопасно.

С катаной в зубах и катаной в каждой руке доступна способность «Three Sword Style»: стойка с поднятыми катанами и аурой, затем рывок к выбранной точке и удар каждой из трёх катан по каждому, кто стоял на пути. Урон идёт через обычную атаку предмета, поэтому игрушечные катаны бьют как игрушки.

Катаны: `/obj/item/katana`, `/obj/item/toy/katana`, `/obj/item/energy_katana`, `/obj/item/nullrod/claymore/katana`, `/obj/item/cursed_katana`. Проклятая катана приросла к руке, в зубы её не взять, но в руке она считается. Чтобы добавить новую, повесь на неё `/datum/element/three_sword_style` и нарисуй в `icons/three_sword_style.dmi` стейты `<icon_state>_mouth`, `<icon_state>_raised_left`, `<icon_state>_raised_right`.

Быстрая экипировка (E) кладёт катану в зубы последним вариантом, после спины, пояса и хранилища костюма.

### Defines/Helpers:

- N/A

### TG Proc/File Changes:

- `code/datums/elements/muffles_speech.dm`: `/datum/element/muffles_speech/proc/equipped()` мычит только в слоте маски, а не в любом слоте из `slot_flags` (иначе энергокатана мычала бы со спины)

### TGUI Files:

- N/A
