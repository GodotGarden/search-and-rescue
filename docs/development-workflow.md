# Development Workflow

## Working rule

Make the next playable thing, test it in Godot, and keep each change easy to review. Prototype speed comes from small safe steps, not from skipping verification.

## Before starting work

1. Read the relevant milestone in [the roadmap](../roadmap.md).
2. Pull the current branch and create a short-lived feature branch, for example `player/third-person-camera` or `incident/lost-hiker`.
3. Check whether a similar scene, script, or resource already exists before creating a new pattern.

## Day-to-day loop

1. Make one cohesive change: a scene, interaction, incident step, model import, or fix.
2. Run the affected scene in Godot.
3. Exercise the happy path and one obvious edge case such as restarting, leaving range, or interacting twice.
4. Check changed files before committing. Do not commit generated Godot cache/import folders unless the repository explicitly needs a particular generated file.
5. Commit with a short outcome-focused message, for example `Add hiker extraction objective`.

## Scene and script conventions

- Name scene roots by their role: `Player`, `Casualty`, `IncidentHiker`.
- Keep a script next to its scene when it is tightly scene-specific; use `scripts/` for reusable behaviors shared across scenes.
- Prefer exported variables for values a designer is likely to tune in the Inspector.
- Add a short comment only where intent is not obvious from the structure or name.
- Use signals for cross-scene events instead of deeply nested node paths.
- Avoid changing unrelated scenes or reformatting unrelated scripts in a feature branch.

## Testing checklist

For any player-facing change, confirm:

- The project opens without new parse errors or warnings that need action.
- The current scene runs.
- The main rescue loop still completes, if your change touches it.
- If the change touches shared gameplay, test it with a host and second player—not two local copies of the same state.
- A scene restart resets important state.
- The player cannot easily get stuck in terrain, UI, or an incomplete objective state.

For the current scaffold's repeatable host/join checks, use the [two-player LAN test guide](lan-multiplayer-testing.md). For the complete two-player incident contract, use [Multiplayer MVP](multiplayer-mvp.md).

For an art import, also use the checklists in [Asset and model conventions](assets-and-models.md) and [Goxel workflow](goxel-workflow.md).

## Third-party add-ons

Add an add-on only to solve a present, understood problem. Before adding one, record its source/version/license in the asset register, verify Godot 4.7 compatibility, and make a clean commit. Prefer native Godot features for the first slice.

## Rendering checks

Once the co-op slice exists, test the busiest outdoor area in Forward+ on the team's target desktop machines. Check frame-time stability as well as average frame rate, then record any terrain, foliage, light, or effect change that materially affects the budget.

## Definition of done

A change is done when it works in a running scene, its assets are tracked, its purpose is understandable to the next contributor, and it has not added an unneeded dependency or framework.
