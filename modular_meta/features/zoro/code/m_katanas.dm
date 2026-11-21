//ORIGINAL FILE: code/game/objects/items/weaponry/melee/katana.dm
/obj/item/katana/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/three_sword_style)

//ORIGINAL FILE: code/game/objects/items/toys.dm
/obj/item/toy/katana/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/three_sword_style)

//ORIGINAL FILE: code/modules/antagonists/space_ninja/equipment/energy_katana.dm
/obj/item/energy_katana/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/three_sword_style)

//ORIGINAL FILE: code/modules/jobs/job_types/chaplain/chaplain_nullrod.dm
/obj/item/nullrod/claymore/katana/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/three_sword_style)

//ORIGINAL FILE: code/modules/mining/lavaland/mining_loot/cursed_katana.dm
/obj/item/cursed_katana/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/three_sword_style)
