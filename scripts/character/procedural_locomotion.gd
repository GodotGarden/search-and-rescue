extends RefCounted

## Poses a CharacterModel's joints per frame from horizontal velocity and grounded state.
## Idle/walk/run are one sine function faded by speed; airborne cross-fades to a fixed pose.
## See "Key decision: procedural sine-driven locomotion" in docs/procedural-character-spec.md.

const STRIDE_RATE := 2.4 # radians of gait phase per metre travelled, not per second — see phase note below.
const WALK_AMPLITUDE_SPEED := 4.0 # m/s at which walk-amplitude motion is fully faded in.
const RUN_AMPLITUDE_SPEED := 7.5 # m/s at which run-amplitude motion is fully faded in.
const IDLE_SWAY_SPEED := 0.15 # m/s at/under which idle sway is fully faded in.
const IDLE_SWAY_RATE := 1.6 # rad/sec of the idle breathing timer (time-based; there is no foot-slide risk to guard against while standing still).

const HIP_SWING_WALK := 0.55
const HIP_SWING_RUN := 0.95
const HIP_SWING_CLAMP := 1.05

const KNEE_BEND_WALK := 0.55
const KNEE_BEND_RUN := 1.15
const KNEE_BEND_CLAMP := 1.35

const SHOULDER_SWING_WALK := 0.45
const SHOULDER_SWING_RUN := 0.75
const SHOULDER_SWING_CLAMP := 0.95

const ELBOW_BEND_WALK := 0.25
const ELBOW_BEND_RUN := 0.5
const ELBOW_BEND_CLAMP := 0.7

const TORSO_IDLE_SWAY := 0.03
const HEAD_IDLE_SWAY := 0.02

const AIRBORNE_HIP_LIFT := -0.6
const AIRBORNE_KNEE_BEND := 0.9
const AIRBORNE_SHOULDER_LIFT := -0.25
const AIRBORNE_BLEND_RATE := 6.0

var _joints: Dictionary
var _rest_rotations: Dictionary
var _gait_phase := 0.0
var _idle_phase := 0.0
var _airborne_blend := 0.0


func _init(joints: Dictionary, rest_rotations: Dictionary) -> void:
	_joints = joints
	_rest_rotations = rest_rotations


func update(delta: float, horizontal_velocity: Vector3, grounded: bool) -> void:
	var speed := horizontal_velocity.length()
	_idle_phase = fmod(_idle_phase + delta * IDLE_SWAY_RATE, TAU)
	_airborne_blend = move_toward(_airborne_blend, 0.0 if grounded else 1.0, delta * AIRBORNE_BLEND_RATE)
	# Phase advances by distance travelled, not raw time, so feet don't slide/moonwalk at a given speed.
	if grounded:
		_gait_phase = fmod(_gait_phase + speed * delta * STRIDE_RATE, TAU)
	apply_pose(_gait_phase, speed, _idle_phase, _airborne_blend)


## Sets an exact, reproducible pose in one call: no delta-time integration or airborne blend ramp.
## For preview/capture tooling — see "Character animation contract" in
## docs/specifications/procedural-preview-lab.md. gait_phase and idle_phase are radians (0..TAU).
func set_exact_pose(gait_phase: float, speed: float, grounded: bool, idle_phase: float = 0.0) -> void:
	_gait_phase = fmod(gait_phase, TAU)
	_idle_phase = fmod(idle_phase, TAU)
	_airborne_blend = 0.0 if grounded else 1.0
	apply_pose(_gait_phase, speed, _idle_phase, _airborne_blend)


## Pure: poses every joint from an explicit phase/speed/blend state, no time integration or
## internal state mutation beyond the joints themselves. Shared by update() (gameplay, phase
## accumulated per-frame) and set_exact_pose() (preview tooling, phase supplied directly).
func apply_pose(gait_phase: float, speed: float, idle_phase: float, airborne_blend: float) -> void:
	var walk_factor := clampf(speed / WALK_AMPLITUDE_SPEED, 0.0, 1.0)
	var run_factor := clampf((speed - WALK_AMPLITUDE_SPEED) / (RUN_AMPLITUDE_SPEED - WALK_AMPLITUDE_SPEED), 0.0, 1.0)
	var idle_factor := 1.0 - clampf(speed / IDLE_SWAY_SPEED, 0.0, 1.0)

	var hip_amplitude := lerpf(HIP_SWING_WALK, HIP_SWING_RUN, run_factor) * walk_factor
	var knee_amplitude := lerpf(KNEE_BEND_WALK, KNEE_BEND_RUN, run_factor) * walk_factor
	var shoulder_amplitude := lerpf(SHOULDER_SWING_WALK, SHOULDER_SWING_RUN, run_factor) * walk_factor
	var elbow_amplitude := lerpf(ELBOW_BEND_WALK, ELBOW_BEND_RUN, run_factor) * walk_factor

	var left_swing := sin(gait_phase)
	var right_swing := sin(gait_phase + PI)

	_apply_rotation_x("HipL", left_swing * hip_amplitude, -HIP_SWING_CLAMP, HIP_SWING_CLAMP)
	_apply_rotation_x("HipR", right_swing * hip_amplitude, -HIP_SWING_CLAMP, HIP_SWING_CLAMP)
	# Knee bend is rectified (max with 0) so the joint only ever bends backward, never inverts.
	_apply_rotation_x("KneeL", maxf(-left_swing, 0.0) * knee_amplitude, 0.0, KNEE_BEND_CLAMP)
	_apply_rotation_x("KneeR", maxf(-right_swing, 0.0) * knee_amplitude, 0.0, KNEE_BEND_CLAMP)
	# Arms swing counter to the same-side leg.
	_apply_rotation_x("ShoulderL", right_swing * shoulder_amplitude, -SHOULDER_SWING_CLAMP, SHOULDER_SWING_CLAMP)
	_apply_rotation_x("ShoulderR", left_swing * shoulder_amplitude, -SHOULDER_SWING_CLAMP, SHOULDER_SWING_CLAMP)
	_apply_rotation_x("ElbowL", maxf(left_swing, 0.0) * elbow_amplitude, 0.0, ELBOW_BEND_CLAMP)
	_apply_rotation_x("ElbowR", maxf(right_swing, 0.0) * elbow_amplitude, 0.0, ELBOW_BEND_CLAMP)

	var sway := sin(idle_phase) * idle_factor
	_apply_rotation_x("Torso", sway * TORSO_IDLE_SWAY, -TORSO_IDLE_SWAY, TORSO_IDLE_SWAY)
	_apply_rotation_x("Head", -sway * HEAD_IDLE_SWAY, -HEAD_IDLE_SWAY, HEAD_IDLE_SWAY)

	if airborne_blend > 0.0:
		_blend_airborne(airborne_blend)


func _blend_airborne(airborne_blend: float) -> void:
	_lerp_rotation_x("HipL", AIRBORNE_HIP_LIFT, airborne_blend, -HIP_SWING_CLAMP, HIP_SWING_CLAMP)
	_lerp_rotation_x("HipR", AIRBORNE_HIP_LIFT, airborne_blend, -HIP_SWING_CLAMP, HIP_SWING_CLAMP)
	_lerp_rotation_x("KneeL", AIRBORNE_KNEE_BEND, airborne_blend, 0.0, KNEE_BEND_CLAMP)
	_lerp_rotation_x("KneeR", AIRBORNE_KNEE_BEND, airborne_blend, 0.0, KNEE_BEND_CLAMP)
	_lerp_rotation_x("ShoulderL", AIRBORNE_SHOULDER_LIFT, airborne_blend, -SHOULDER_SWING_CLAMP, SHOULDER_SWING_CLAMP)
	_lerp_rotation_x("ShoulderR", AIRBORNE_SHOULDER_LIFT, airborne_blend, -SHOULDER_SWING_CLAMP, SHOULDER_SWING_CLAMP)


func _apply_rotation_x(joint_name: String, angle: float, clamp_min: float, clamp_max: float) -> void:
	var joint: Node3D = _joints.get(joint_name)
	if joint == null:
		return
	var rest: Vector3 = _rest_rotations.get(joint_name, Vector3.ZERO)
	joint.rotation.x = rest.x + clampf(angle, clamp_min, clamp_max)


func _lerp_rotation_x(joint_name: String, target_angle: float, blend: float, clamp_min: float, clamp_max: float) -> void:
	var joint: Node3D = _joints.get(joint_name)
	if joint == null:
		return
	var rest: Vector3 = _rest_rotations.get(joint_name, Vector3.ZERO)
	var grounded_local := joint.rotation.x - rest.x
	var blended := lerpf(grounded_local, target_angle, blend)
	joint.rotation.x = rest.x + clampf(blended, clamp_min, clamp_max)
