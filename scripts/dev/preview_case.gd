class_name PreviewCase
extends Resource

## A single named, reproducible capture for scripts/dev/character_preview.gd's batch mode.
## See "Batch Capture Runner" in docs/specifications/procedural-preview-lab.md.

enum CameraView { FRONT, SIDE_LEFT, SIDE_RIGHT, REAR, THREE_QUARTER }
enum StagePreset { NEUTRAL_REVIEW, SILHOUETTE, GAMEPLAY_CAMERA }

## Stable identifier, e.g. "responder_default_front". Also the default output filename stem.
@export var case_name: String = ""
@export_file("*.tres") var appearance_path: String = ""
@export var stage_preset: StagePreset = StagePreset.NEUTRAL_REVIEW
@export var camera_view: CameraView = CameraView.FRONT
## Normalized gait phase (0..1 = one full stride cycle). Ignored while pose_speed is 0.
@export_range(0.0, 1.0) var pose_phase: float = 0.0
## Horizontal speed (m/s) fed to locomotion: 0 = idle rest pose, ~walk below WALK_AMPLITUDE_SPEED,
## ~run above it. See procedural_locomotion.gd.
@export var pose_speed: float = 0.0
## False blends fully to the airborne/jump pose regardless of pose_phase.
@export var pose_grounded: bool = true
## res:// PNG path. Empty derives "res://dev-output/<case_name>.png".
@export var output_path: String = ""


func get_output_path() -> String:
	return output_path if not output_path.is_empty() else "res://dev-output/%s.png" % case_name


func get_camera_view_name() -> String:
	return CameraView.keys()[camera_view].to_lower()


func get_stage_preset_name() -> String:
	return StagePreset.keys()[stage_preset].to_lower()
