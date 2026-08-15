extends Node3D

## Emits a short burst of dust when the parent CharacterBody3D's vertical velocity goes from a
## sustained fall back to (near) zero within a single physics step — i.e. touching down after a
## jump or a drop off a ledge.
##
## Detected purely from the base `CharacterBody3D.velocity` property rather than anything specific
## to responder.gd: gravity only ever makes velocity.y more negative while airborne, so a jump back
## toward zero in one step can only be the floor collision resolving it on landing. Reading only
## this base-class property (present on every CharacterBody3D) also means it keeps working for
## remote peers, whose `velocity` is replicated over the network even though their `is_on_floor()`
## never updates locally (movement for remote bodies is applied by lerping position directly rather
## than via move_and_slide() — see responder.gd's REMOTE_GROUNDED_VELOCITY_THRESHOLD comment).
##
## Instance this scene as a direct child of a CharacterBody3D, positioned at ground/foot level.

@export var fall_speed_threshold := 3.0 # m/s downward speed required before a touchdown counts as a "landing".
@export var landed_speed_threshold := 0.75 # m/s vertical speed still considered "settled" once grounded.

@onready var _particles: GPUParticles3D = $GPUParticles3D

var _character_body: CharacterBody3D
var _was_falling := false


func _ready() -> void:
	_character_body = get_parent() as CharacterBody3D


func _physics_process(_delta: float) -> void:
	if _character_body == null:
		return
	var vertical_velocity := _character_body.velocity.y
	var falling := vertical_velocity <= -fall_speed_threshold
	if _was_falling and not falling and absf(vertical_velocity) <= landed_speed_threshold:
		_emit_burst()
	_was_falling = falling


func _emit_burst() -> void:
	_particles.restart()
	_particles.emitting = true
