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


# --- Static interaction pose: kneel_one_knee ----------------------------------------------------
# See the "Appendix: Character Pose Library" in docs/specifications/procedural-preview-lab.md
# (category: standing interaction, implementation: "static joint pose with optional blend").
# Deliberately its own, looser set of per-joint clamps rather than reusing the locomotion
# constants above: this is a held static pose, not a cyclic gait, so it needs a deeper hip/knee
# fold than any walk/run stride ever reaches. Still clamped to a plausible range so a bad value
# can't visibly invert a limb, matching the "Joint rotation is clamped per joint" rig convention.
#
# Sign convention (verified against the walk gait, e.g. responder_default_walk_contact.tres):
# Knee is a child of Hip, both rotating about the same local X axis, so their angles compose
# additively — a leg's total absolute tilt from vertical is (hip angle + knee angle), not just
# the knee angle in isolation. The walk cycle only ever adds a *positive* knee angle on top of a
# *negative* (trailing) hip angle, which pulls the shin back toward vertical (a natural heel-lift
# fold) — it never needs a forward hip to compose with a positive knee, so it never surfaces this.
# A static pose that plants a forward-swung leg has to counter-rotate the knee *negative* to bring
# the shin back down under the hip instead of continuing to curl it forward past horizontal.
const KNEEL_SUPPORT_HIP := 0.75 # Front/support leg: thigh swings forward ~43°, foot plants ahead.
const KNEEL_SUPPORT_KNEE := -0.55 # Counter-rotates the hip angle so the shin hangs close to vertical under the knee (a planted lunge leg), instead of continuing to curl forward. Kept shallower than an anatomical ~90° lunge specifically to limit how far the planted foot floats above the ground plane — see the rig-limitation note below; this rig cannot fully close that gap without a root offset.
const KNEEL_DOWN_HIP := -0.15 # Kneeling leg: thigh stays close to vertical, small backward cant.
const KNEEL_DOWN_KNEE := -1.1 # Continues rotating the same (backward) direction as the hip, folding the shin back along the ground behind the knee.
const KNEEL_HIP_CLAMP := 1.3
const KNEEL_KNEE_CLAMP_MIN := -1.9
const KNEEL_KNEE_CLAMP_MAX := 0.15
const KNEEL_SHOULDER_LEAN := 0.3 # Small forward shoulder lean; hands read as "ready," not swinging.
const KNEEL_ELBOW_BEND := 0.35
const KNEEL_SHOULDER_CLAMP := SHOULDER_SWING_CLAMP
const KNEEL_ELBOW_CLAMP := ELBOW_BEND_CLAMP
const KNEEL_TORSO_LEAN := -0.32 # Negative leans forward, toward the casualty (see sign-convention note above); torso/head clamps are intentionally wider than idle sway's.
const KNEEL_TORSO_CLAMP := 0.4
const KNEEL_HEAD_TILT := -0.18 # Negative tilts the head further down, toward the casualty.
const KNEEL_HEAD_CLAMP := 0.3


## Static "one knee down, one foot planted" interaction pose — the responder/casualty treatment
## pose from the Character Pose Library appendix (docs/specifications/procedural-preview-lab.md).
## Not part of the locomotion cycle: it ignores gait/idle phase and is unaffected by
## update()/apply_pose(). Call this once to hold the pose (e.g. from a preview case or an
## interaction state); call set_exact_pose()/update() again to leave it — there is no blend_out
## yet (see the pose data contract's blend_in/blend_out fields, not implemented for this pose).
## kneeling_leg_left selects which leg kneels: true = left knee down, right foot planted forward.
##
## Rig-limitation note, flagged rather than silently worked around: the model root/pelvis position
## is fixed at build time (see CharacterModel._build_rig()'s Pelvis pivot) and this pose only
## rotates joints — it does not lower the root. The kneeling knee therefore will not literally
## touch the ground plane; it reads as a deep-kneel silhouette, not floor-accurate ground contact.
## A floor-accurate version would need a root offset and/or coordination with collider height and
## the camera-pivot height cached at spawn (responder.gd's _attach_sockets()) — out of scope for
## this visual-only pose evaluator; see the character-creature-systems skill's "flag rather than
## silently decide" rule for collision/grounded-state-adjacent changes.
func apply_kneel_one_knee_pose(kneeling_leg_left: bool = false) -> void:
	var support_suffix := "L" if kneeling_leg_left else "R"
	var down_suffix := "R" if kneeling_leg_left else "L"

	_apply_rotation_x("Hip%s" % support_suffix, KNEEL_SUPPORT_HIP, -KNEEL_HIP_CLAMP, KNEEL_HIP_CLAMP)
	_apply_rotation_x("Knee%s" % support_suffix, KNEEL_SUPPORT_KNEE, KNEEL_KNEE_CLAMP_MIN, KNEEL_KNEE_CLAMP_MAX)
	_apply_rotation_x("Hip%s" % down_suffix, KNEEL_DOWN_HIP, -KNEEL_HIP_CLAMP, KNEEL_HIP_CLAMP)
	_apply_rotation_x("Knee%s" % down_suffix, KNEEL_DOWN_KNEE, KNEEL_KNEE_CLAMP_MIN, KNEEL_KNEE_CLAMP_MAX)

	_apply_rotation_x("ShoulderL", KNEEL_SHOULDER_LEAN, -KNEEL_SHOULDER_CLAMP, KNEEL_SHOULDER_CLAMP)
	_apply_rotation_x("ShoulderR", KNEEL_SHOULDER_LEAN, -KNEEL_SHOULDER_CLAMP, KNEEL_SHOULDER_CLAMP)
	_apply_rotation_x("ElbowL", KNEEL_ELBOW_BEND, 0.0, KNEEL_ELBOW_CLAMP)
	_apply_rotation_x("ElbowR", KNEEL_ELBOW_BEND, 0.0, KNEEL_ELBOW_CLAMP)

	_apply_rotation_x("Torso", KNEEL_TORSO_LEAN, -KNEEL_TORSO_CLAMP, KNEEL_TORSO_CLAMP)
	_apply_rotation_x("Head", KNEEL_HEAD_TILT, -KNEEL_HEAD_CLAMP, KNEEL_HEAD_CLAMP)


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
