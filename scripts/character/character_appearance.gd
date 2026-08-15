class_name CharacterAppearance
extends Resource

## Cosmetic + shape data for a generated CharacterModel. See docs/procedural-character-spec.md.

enum HairStyle { NONE, SHORT, BUN }
enum HeadEquipment { NONE, CAP, RESCUE_HELMET }

const MIN_HEIGHT_M := 1.5
const MAX_HEIGHT_M := 2.0
const MIN_SHOULDER_HIP_RATIO := 0.85
const MAX_SHOULDER_HIP_RATIO := 1.35
const MIN_HEAD_SCALE := 0.8
const MAX_HEAD_SCALE := 1.25

@export var height_m: float = 1.75:
	set(value):
		height_m = clampf(value, MIN_HEIGHT_M, MAX_HEIGHT_M)

@export_range(0.0, 1.0) var build: float = 0.5:
	set(value):
		build = clampf(value, 0.0, 1.0)

@export var shoulder_hip_ratio: float = 1.05:
	set(value):
		shoulder_hip_ratio = clampf(value, MIN_SHOULDER_HIP_RATIO, MAX_SHOULDER_HIP_RATIO)

@export var head_scale: float = 1.0:
	set(value):
		head_scale = clampf(value, MIN_HEAD_SCALE, MAX_HEAD_SCALE)

@export var skin_color: Color = Color("caa47a")
@export var hair_style: HairStyle = HairStyle.SHORT
@export var hair_color: Color = Color("3b2a20")
@export var head_equipment: HeadEquipment = HeadEquipment.NONE
@export var clothing_primary_color: Color = Color("2c4a63")
@export var clothing_secondary_color: Color = Color("1c2c2c")
## Safety accent, repeated across chest, sleeves, and lower legs. See docs/character-appearance-visual-design.md.
@export var accent_color: Color = Color("f2c318")

## Host/internal only for this milestone: not exposed as a player-facing customization control.
## Reserved: character_builder.gd does not yet derive any deterministic variation from this —
## every field above is still set explicitly per appearance. Wire this up before relying on it
## to produce a crowd of distinct NPCs from one appearance.
@export var variant_seed: int = 0

## Bumped when builder logic changes shape in a way that would make an old seed produce a different
## result. Reserved alongside variant_seed for the same reason: not yet consumed by the builder.
@export var generator_version: int = 2


func to_payload() -> Dictionary:
	return {
		"height_m": height_m,
		"build": build,
		"shoulder_hip_ratio": shoulder_hip_ratio,
		"head_scale": head_scale,
		"skin_color": skin_color,
		"hair_style": hair_style,
		"hair_color": hair_color,
		"head_equipment": head_equipment,
		"clothing_primary_color": clothing_primary_color,
		"clothing_secondary_color": clothing_secondary_color,
		"accent_color": accent_color,
		"variant_seed": variant_seed,
		"generator_version": generator_version,
	}


static func from_payload(payload: Dictionary) -> CharacterAppearance:
	var appearance := new()
	appearance.height_m = payload.get("height_m", appearance.height_m)
	appearance.build = payload.get("build", appearance.build)
	appearance.shoulder_hip_ratio = payload.get("shoulder_hip_ratio", appearance.shoulder_hip_ratio)
	appearance.head_scale = payload.get("head_scale", appearance.head_scale)
	appearance.skin_color = payload.get("skin_color", appearance.skin_color)
	appearance.hair_style = payload.get("hair_style", appearance.hair_style)
	appearance.hair_color = payload.get("hair_color", appearance.hair_color)
	appearance.head_equipment = payload.get("head_equipment", appearance.head_equipment)
	appearance.clothing_primary_color = payload.get("clothing_primary_color", appearance.clothing_primary_color)
	appearance.clothing_secondary_color = payload.get("clothing_secondary_color", appearance.clothing_secondary_color)
	appearance.accent_color = payload.get("accent_color", appearance.accent_color)
	appearance.variant_seed = payload.get("variant_seed", appearance.variant_seed)
	appearance.generator_version = payload.get("generator_version", appearance.generator_version)
	return appearance
