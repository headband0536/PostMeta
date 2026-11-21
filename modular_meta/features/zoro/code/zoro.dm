#define THREE_SWORD_STYLE_ICON 'modular_meta/features/zoro/icons/three_sword_style.dmi'
/// katana fit for the three sword style, given by [/datum/element/three_sword_style]
#define TRAIT_THREE_SWORD_KATANA "three_sword_katana"

/**
 * lets a katana be held in the teeth and grants the three sword style while it is there
 *
 * the bite muffles speech, running with it cuts the face for a share of the katana's own force
 */
/datum/element/three_sword_style
	/// quick equip tries the teeth last, so a katana that fits a belt or back goes there first
	var/static/list/katana_slot_priority = list(ITEM_SLOT_BACK, ITEM_SLOT_BELT, ITEM_SLOT_SUITSTORE, ITEM_SLOT_MASK)

/datum/element/three_sword_style/Attach(datum/target)
	. = ..()
	if(!isitem(target))
		return ELEMENT_INCOMPATIBLE
	var/obj/item/katana = target
	katana.slot_flags |= ITEM_SLOT_MASK
	katana.slot_equipment_priority = katana_slot_priority
	katana.action_slots = ITEM_SLOT_MASK
	ADD_TRAIT(katana, TRAIT_THREE_SWORD_KATANA, ELEMENT_TRAIT(type))
	katana.AddElement(/datum/element/muffles_speech) // mmmf mmf mmmmf
	katana.add_item_action(/datum/action/cooldown/three_sword_style)
	RegisterSignal(katana, COMSIG_ITEM_EQUIPPED, PROC_REF(on_equipped))
	RegisterSignal(katana, COMSIG_ITEM_DROPPED, PROC_REF(on_dropped))

/datum/element/three_sword_style/Detach(obj/item/source)
	UnregisterSignal(source, list(COMSIG_ITEM_EQUIPPED, COMSIG_ITEM_DROPPED))
	for(var/datum/action/cooldown/three_sword_style/style_action in source.actions)
		source.remove_item_action(style_action)
	source.RemoveElement(/datum/element/muffles_speech)
	REMOVE_TRAIT(source, TRAIT_THREE_SWORD_KATANA, ELEMENT_TRAIT(type))
	source.action_slots = initial(source.action_slots)
	source.slot_equipment_priority = initial(source.slot_equipment_priority)
	source.slot_flags &= ~ITEM_SLOT_MASK
	return ..()

/// swaps in the katana-in-teeth sprite and starts watching the biter's steps
/datum/element/three_sword_style/proc/on_equipped(obj/item/source, mob/user, slot)
	SIGNAL_HANDLER
	if(!(slot & ITEM_SLOT_MASK))
		return
	source.worn_icon = THREE_SWORD_STYLE_ICON
	source.worn_icon_state = "[source.icon_state]_mouth"
	user.update_worn_mask() // the mask slot got drawn before we got here
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(on_biter_moved))

/// puts the katana's own sprites back once it leaves the teeth
/datum/element/three_sword_style/proc/on_dropped(obj/item/source, mob/user)
	SIGNAL_HANDLER
	if(user.get_item_by_slot(ITEM_SLOT_MASK) != source)
		return
	source.worn_icon = initial(source.worn_icon)
	source.worn_icon_state = initial(source.worn_icon_state)
	UnregisterSignal(user, COMSIG_MOVABLE_MOVED)

#define SELF_CUT_CHANCE 4
#define SELF_CUT_FORCE_MULTIPLIER 0.2

/// walking is safe, running with a blade in the teeth is not, being dragged or carried does not count
/datum/element/three_sword_style/proc/on_biter_moved(mob/living/carbon/human/source, atom/old_loc, movement_dir, forced)
	SIGNAL_HANDLER
	if(forced || source.moving_from_pull || source.buckled || source.move_intent == MOVE_INTENT_WALK || !prob(SELF_CUT_CHANCE))
		return
	var/obj/item/katana = source.get_item_by_slot(ITEM_SLOT_MASK)
	source.apply_damage(katana.force * SELF_CUT_FORCE_MULTIPLIER, katana.damtype, BODY_ZONE_HEAD, sharpness = katana.sharpness)
	playsound(source, katana.hitsound, vol = 30, vary = TRUE)
	source.visible_message(
		span_danger("[source] cuts [source.p_their()] cheek on [katana] clenched in [source.p_their()] teeth!"),
		span_userdanger("You cut your cheek on [katana] in your teeth!"),
	)

#undef SELF_CUT_FORCE_MULTIPLIER
#undef SELF_CUT_CHANCE

/**
 * three sword style: a katana in each hand, the third in the teeth, a stance and a dash through everyone in the way
 *
 * every katana strikes every victim with its own attack, so toy katanas hit like toys
 */
/datum/action/cooldown/three_sword_style
	name = "Three Sword Style"
	desc = "Raise a katana in each hand, grit your teeth on the third and dash through everyone in the way."
	check_flags = /datum/action/item_action::check_flags | AB_CHECK_IMMOBILE
	button_icon_state = null
	click_to_activate = TRUE
	cooldown_time = 20 SECONDS
	/// furthest the dash goes, in tiles
	var/dash_range = 5
	/// how long the stance is held before the dash
	var/stance_time = 1 SECONDS
	/// pause between the dash and the slashes landing
	var/slash_delay = 0.4 SECONDS

/datum/action/cooldown/three_sword_style/New(Target, original = TRUE)
	. = ..()
	AddComponent(/datum/component/action_item_overlay, target)

/datum/action/cooldown/three_sword_style/Activate(atom/aimed_at)
	var/mob/living/carbon/human/swordsman = owner
	var/turf/aim_turf = get_turf(aimed_at)
	if(HAS_TRAIT(swordsman, TRAIT_PACIFISM))
		swordsman.balloon_alert(swordsman, "too peaceful!")
		return FALSE
	if(!isturf(swordsman.loc))
		swordsman.balloon_alert(swordsman, "no room to swing!")
		return FALSE
	if(!wields_three_katanas(swordsman))
		swordsman.balloon_alert(swordsman, "need katanas in hands!")
		return FALSE
	if(!length(get_dash_turfs(swordsman, aim_turf)))
		swordsman.balloon_alert(swordsman, "no room to dash!")
		return FALSE
	StartCooldown()
	INVOKE_ASYNC(src, PROC_REF(perform), swordsman, aim_turf)
	return TRUE

/// whether the katana is still in the teeth and every hand grips another one
/datum/action/cooldown/three_sword_style/proc/wields_three_katanas(mob/living/carbon/human/swordsman)
	if(swordsman.get_item_by_slot(ITEM_SLOT_MASK) != target || length(swordsman.get_empty_held_indexes()))
		return FALSE
	return length(get_hand_katanas(swordsman)) == length(swordsman.get_held_items())

/// every held item that fits the three sword style
/datum/action/cooldown/three_sword_style/proc/get_hand_katanas(mob/living/carbon/human/swordsman)
	var/list/obj/item/hand_katanas = list()
	for(var/obj/item/held_item as anything in swordsman.get_held_items())
		if(HAS_TRAIT(held_item, TRAIT_THREE_SWORD_KATANA))
			hand_katanas += held_item
	return hand_katanas

/// turfs the dash passes toward the aim, stopping before the first step something solid blocks, mobs never block
/datum/action/cooldown/three_sword_style/proc/get_dash_turfs(mob/living/carbon/human/swordsman, turf/aim_turf)
	var/turf/start_turf = get_turf(swordsman)
	var/turf/previous_turf = start_turf
	var/datum/can_pass_info/pass_info = new(swordsman, no_id = TRUE) // no id, so public airlocks count as walls too
	var/list/turf/dash_turfs = list()
	for(var/turf/line_turf as anything in get_line(start_turf, aim_turf) - start_turf)
		if(get_dist(start_turf, line_turf) > dash_range || line_turf.density || previous_turf.LinkBlockedWithAccess(line_turf, pass_info))
			break
		dash_turfs += line_turf
		previous_turf = line_turf
	return dash_turfs

#define AURA_FILTER "three_sword_style_aura"
#define AURA_PULSE_TIME (0.25 SECONDS)
#define AURA_REST_SIZE 1
#define AURA_PEAK_SIZE 3

/// holds the stance and dashes if nobody broke it
/datum/action/cooldown/three_sword_style/proc/perform(mob/living/carbon/human/swordsman, turf/aim_turf)
	strike_stance(swordsman)
	var/stance_held = do_after(swordsman, stance_time, extra_checks = CALLBACK(src, PROC_REF(wields_three_katanas), swordsman))
	swordsman.remove_filter(AURA_FILTER)
	swordsman.update_held_items() // the usual grip comes back
	if(stance_held)
		dash(swordsman, aim_turf)

/// raises the hand katanas into a П over the one in the teeth and lights the aura
/datum/action/cooldown/three_sword_style/proc/strike_stance(mob/living/carbon/human/swordsman)
	swordsman.set_combat_mode(TRUE)
	var/list/raised_katanas = list()
	for(var/obj/item/katana as anything in get_hand_katanas(swordsman))
		var/held_index = swordsman.get_held_index_of_item(katana)
		var/mutable_appearance/raised_katana = mutable_appearance(THREE_SWORD_STYLE_ICON, "[katana.icon_state]_raised_[IS_LEFT_INDEX(held_index) ? "left" : "right"]", -HANDS_LAYER)
		swordsman.apply_height(raised_katana, LOWER_BODY)
		var/obj/item/bodypart/arm/katana_arm = swordsman.hand_bodyparts[held_index]
		if(katana_arm.held_hand_offset)
			katana_arm.held_hand_offset.apply_offset(raised_katana)
		raised_katanas += raised_katana
	swordsman.remove_overlay(HANDS_LAYER)
	swordsman.overlays_standing[HANDS_LAYER] = raised_katanas
	swordsman.apply_overlay(HANDS_LAYER)
	swordsman.add_filter(AURA_FILTER, priority = 2, params = outline_filter(size = AURA_REST_SIZE, color = COLOR_LIME))
	animate(swordsman.get_filter(AURA_FILTER), size = AURA_PEAK_SIZE, time = AURA_PULSE_TIME, loop = -1, easing = SINE_EASING)
	animate(size = AURA_REST_SIZE, time = AURA_PULSE_TIME, easing = SINE_EASING)
	playsound(swordsman, 'sound/items/unsheath.ogg', vol = 50, vary = TRUE)
	playsound(swordsman, 'sound/effects/magic/charge.ogg', vol = 50, vary = TRUE)
	swordsman.visible_message(
		span_warning("[swordsman] raises two katanas and bites down on the third!"),
		span_notice("You raise your katanas and bite down on the third. Three sword style!"),
	)

#undef AURA_PEAK_SIZE
#undef AURA_REST_SIZE
#undef AURA_PULSE_TIME
#undef AURA_FILTER

/// blinks to the end of the path, leaving afterimages, and queues the slashes on everyone passed
/datum/action/cooldown/three_sword_style/proc/dash(mob/living/carbon/human/swordsman, turf/aim_turf)
	var/list/turf/dash_turfs = get_dash_turfs(swordsman, aim_turf)
	if(!length(dash_turfs))
		swordsman.balloon_alert(swordsman, "path blocked!")
		return
	var/list/mob/living/victims = list()
	new /obj/effect/temp_visual/decoy/fading/halfsecond(get_turf(swordsman), swordsman)
	for(var/turf/dash_turf as anything in dash_turfs)
		for(var/mob/living/victim in dash_turf)
			victims += victim
		new /obj/effect/temp_visual/decoy/fading/halfsecond(dash_turf, swordsman) // afterimages or it didn't happen
	swordsman.forceMove(dash_turfs[length(dash_turfs)])
	playsound(swordsman, 'sound/vehicles/mecha/mech_charge_attack.ogg', vol = 75, vary = TRUE)
	addtimer(CALLBACK(src, PROC_REF(land_slashes), swordsman, victims), slash_delay)

/// hits every victim with every katana once the pause after the dash is over
/datum/action/cooldown/three_sword_style/proc/land_slashes(mob/living/carbon/human/swordsman, list/mob/living/victims)
	if(!wields_three_katanas(swordsman))
		return
	var/list/obj/item/katanas = get_hand_katanas(swordsman) + target // they were already cut, they just didn't know it yet
	for(var/mob/living/victim as anything in victims)
		for(var/obj/item/katana as anything in katanas)
			if(QDELETED(victim))
				break
			katana.melee_attack_chain(swordsman, victim)

#undef TRAIT_THREE_SWORD_KATANA
#undef THREE_SWORD_STYLE_ICON
