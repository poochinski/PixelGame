# Milestone 1 — RPG sprite pass validation

For the subsequent cash inventory and money-drop pass, see `LOOT_VALIDATION.md`.

Tested on Windows with Godot 4.7.2 stable, Compatibility renderer, Intel UHD Graphics 770.

## Results

- Editor import: no script or import errors (`rpg_import.log`).
- Combat integration: **52/52 passed** (`rpg_integration.log`). Covers movement, mouse aim, camera, combo, exact damage, invulnerability, knockback, stagger, walls, navigation, thug behavior, death/respawn and pause. New checks verify raised-bat windup and that light/heavy contact sprites coincide with damage.
- Rendered feedback: **passed** (`rpg_rendered_validation.log`). Checks real mouse input and heavy hit-stop activation/release; captures arena, heavy windup/contact, dodge and facing directions.
- Atlas review: **66/66 passed** (`rpg_animation_review.log`). Verifies transparent backgrounds and valid crops for both 32-pose atlases. Rendered sheets: `rpg_player_sheet.png`, `rpg_thug_sheet.png`.
- Visual review: inspected both pose sheets and in-arena idle, overhead windup and impact captures. Extended weapons remain intact; hands and weapon are one image. Metadata corrects differences between source-row boot baselines.

The first regression run caught the lunge starting before the heavy contact sprite. Moving the lunge to contact fixed it; the full combat rerun passed. These are automated engine checks and visual inspection, not human playtesting.

## Reproduce

From the project directory, using your Godot executable:

```text
godot --headless --editor --import --quit
godot --headless --fixed-fps 60 --quit-after 4000 res://tests/CombatIntegration.tscn
godot --quit-after 600 res://tests/CombatShowcase.tscn
godot --quit-after 600 res://tests/AnimationReview.tscn
godot
```

`CombatTest.tscn` is the main scene. Internal resolution is 320x180, nearest filtering with integer viewport scaling, default window 1280x720 and a 60 FPS cap.

## Current art limits

Original generated prototype art uses four directional rows and three-frame walking. The three light combo steps share attack art with distinct timing/damage; south follow-through holds the contact sprite to keep the weapon visible. Dodge uses a held stride with afterimages, and death rotates the whole sprite. These can gain dedicated frames after feedback on this visual direction.

Only the requested combat milestone is implemented. One active thug respawns for practice; no wider game systems are present.
