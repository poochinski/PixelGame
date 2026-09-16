# NEON REQUIEM — Mercy Row town prototype

Godot 4.3+ / GDScript / Compatibility renderer. Open `project.godot` and press F5 to play **Mercy Row**, the new main scene at `levels/town/Town.tscn`. The original combat arena remains available by pressing F6 on `levels/testing/CombatTest.tscn`.

## Town

A small neighborhood with four neutral thugs, sidewalks, a main street, south walk, service alley and three enterable buildings:

- **Corner Supply (west):** buy bandages for $5 each; carry up to nine. Each heals 30 HP, clamped to maximum health. A full bag or insufficient cash prevents the purchase without charging.
- **Mercy Hospital (center):** free full healing. Player death returns here after two seconds, preserving cash, supplies and mission progress and resetting street hostility.
- **The Last Light (east):** accept *Street Business*, win three fights, then return for $25. Only victories after acceptance count. The reward pays once.

Town thugs leave the player alone until struck. A missed swing does not provoke them and nearby bystanders remain neutral. Defeated thugs drop $1–$10 and are replaced after 18 seconds spent outside, once the player is at least 95 pixels from their spawn. Interiors disable attacks and freeze street actors. Money pickups remain outside independently of corpses and room transitions.

## Controls

- WASD: movement (88 pixels/second, reduced from 115 after play feedback).
- Mouse: aim. Left click: three-hit bat combo; click again near the end of a swing to buffer the next attack.
- Right click: committed heavy swing.
- Space: directional dodge, or dodge toward aim while stationary. Cancels attacks; 0.22 second dash, 0.16 second invulnerability, 0.65 second cooldown.
- E: enter a nearby doorway, leave through the interior exit, or open a counter's service panel.
- 1: buy a bandage, receive hospital treatment, accept the bar job or claim its reward. E/Escape closes service panels.
- B: use a bandage, including from inventory. Full health does not consume one.
- Escape: pause/resume. F1: debug HUD and attack sectors. R resets only the standalone CombatTest arena.
- I: open/close inventory. Combat pauses while the panel shows pocket cash and the equipped bat. Escape closes it; an existing pause is preserved.

Once hostile, a thug approaches, circles at medium range, then commits. Its amber telegraph turns red when aim locks for the final 0.28 seconds; the strike can miss if you sidestep. Punish its 0.85-second recovery before it backs off and changes circling direction. The standalone CombatTest arena retains aggressive sparring enemies and a shorter 2.2-second enemy replacement timer.

## Cash and loot

Every defeated Street Thug drops one money pickup worth a uniformly random **$1–$10**, inclusive. Walk within 12 pixels after its brief bounce to collect it. Pickups stay behind when the next thug spawns; walls block collection. The HUD shows the balance and confirms each payout with a short message and chime.

Cash, bandages and mission progress survive room transitions and death during the current session. Closing the game starts a fresh session; disk saving is not implemented. Inventory shows cash, the equipped bat and bandages. Only money drops from thugs; bandages are bought at the shop. The standalone CombatTest reset clears ground pickups and preserves the wallet.

## Structure

- `components/`: reusable damage payload, health, hurtbox, sector hitbox, actor base.
- `player/`: movement/dodge controller, player scene, smooth camera.
- `weapons/`: melee timing/combo controller and Baseball Bat resource.
- `enemies/`: Street Thug scene and explicit chase/windup/strike/recovery/stagger states.
- `effects/`: impact particles, damage numbers, ghosts, synthesized original sounds, brief hit-stop.
- `inventory/`: player-owned cash, atomic supply purchases and bandage use.
- `missions/`: first bar job with acceptance, victory progress and one-time reward.
- `loot/`: reusable money pickup with bounce, sparkle, proximity and wall checks. Street Thug emits its randomized payout on death; the arena owns drops independently of enemy corpses.
- `art/`: original RPG-style character atlases, silhouette crop metadata, and frame animation. Each frame includes the body, hands and weapon together. `combat_pose.gd` supplies attack phase metadata.
- `levels/testing/`: CombatTest arena, collision, obstacle navigation, brick facade, shutters, wet asphalt, and three colored lights with dumpster shadows.
- `levels/town/`: Mercy Row controller, original code-drawn environment, shared building/obstacle layout and navigation.
- `levels/interiors/`: separate Shop, Hospital and Bar scenes sharing interior collision/art construction.
- `ui/`: combat HUD, pause/death overlays and debug display.
- `tests/`: automated engine integration tests and visual capture.

## Tuning

Player dodge settings and movement speed are exported on Player. Walking speed is 88; dodge speed is 220 (roughly 48 pixels per dash). Bat damage, reach, attack speed, knockback and stagger live in `weapons/baseball_bat.tres`. Light hits deal 18 / 18 / 28.8 damage; heavy deals 43.2. Light attack durations are roughly 0.38 / 0.38 / 0.52 seconds; heavy takes 0.80 seconds. Damage begins after the bat leaves its backswing. Attack timings and multipliers are in `melee_controller.gd`. Thug health is 110, damage 14, chase speed 52; windup is 0.54 seconds and recovery 0.85 seconds. Camera shake never exceeds 2 internal pixels; `shake_scale` can disable it.

Hitboxes query real physics hurtboxes during active frames, apply damage once per target per swing, reject friendly fire and check solid-wall occlusion. Navigation uses an 8-pixel AStar grid with obstacle clearance.

## RPG character animation pass

The survivor and thug use original compact, large-head RPG-style designs. Four direction rows contain idle, two walking poses, light load/contact/follow-through, and overhead load/slam. Hands and weapons are baked into each complete sprite. Light combo steps share this pose set while keeping their distinct timing and damage. Walking advances with ground travel, about nine frame changes per second at normal speed; blocked movement stops the cycle. Walking faces travel, stationary poses and attacks face mouse aim, and damage still uses the exact aim vector.

Windup plants the actor; the lunge and damage start together on the contact frame. Recovery permits movement and dodge cancels attacks. Atlas crop metadata preserves extended weapons without adjacent-frame bleed and registers each direction against its boot baseline. South follow-through holds the contact pose because the source follow-through hides the bat. Source PNGs are unchanged; generation prompts are in `art/sprites/GENERATION.md`.

`tests/AnimationReview.tscn` renders both characters in all 32 direction/pose combinations. See `tests/VALIDATION.md` for verification results. Older procedural art helpers remain available but are no longer used to draw actors.

Combat, cash loot, a first town, supplies, hospital care and one bar mission are implemented. Services currently use interactive counters and a job board. There is no dialogue NPC system, larger city, firearms or boss. See `tests/TOWN_VALIDATION.md` for this pass and `tests/LOOT_VALIDATION.md` for the previous cash/drop checks.
