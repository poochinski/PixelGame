# Cash inventory and thug loot validation

Godot 4.7.2 stable on Windows, Compatibility renderer / Intel UHD Graphics 770.

- Import: no script errors (`loot_import.log`).
- Loot integration: **30/30 passed** headless (`loot_integration.log`) and rendered with audio (`loot_rendered.log`).
- Combat regression: **52/52 passed** (`loot_combat_regression.log`).
- Screenshots inspected: `money_on_ground.png`, `money_collected.png`, `inventory_preview.png`. The money pickup, amount, HUD confirmation and paused inventory are readable at 320x180 internal resolution.

The loot suite exercises real health/death signals, ground pickups and WASD collection. It checks nonlethal/dead enemies cannot generate extra loot; 64 deaths each create a variable integer payout in $1–$10; pickups survive enemy replacement; balance changes only on collection; duplicate attempts pay once; walls and dead players block collection; cash survives death/R resets; uncollected drops clear on encounter reset; and inventory keys correctly preserve pause state without key-repeat toggling.

```text
godot --headless --fixed-fps 60 --quit-after 4000 res://tests/LootIntegration.tscn
godot --headless --fixed-fps 60 --quit-after 4000 res://tests/CombatIntegration.tscn
godot --quit-after 1200 res://tests/LootIntegration.tscn
```

These are automated engine tests and screenshot inspection. Wallets are session-only; saving, spending, other loot types and item management are not part of this pass.
