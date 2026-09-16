# Original RPG character art

Generated using the built-in image generation tool, then integrated as transparent sprite atlases. Runtime cropping uses the adjacent JSON silhouette metadata; source PNGs are unchanged.

## Survivor prompt

Use case: stylized-concept.
Asset type: production pixel-art character sprite atlas for an original top-down Godot RPG, NEON REQUIEM.
Generate ONE transparent PNG sprite sheet, EXACTLY 1536 x 1024 pixels. Layout is EXACTLY 8 equal columns by 4 equal rows; each cell is 192 x 256 pixels. No borders, grid lines, labels or text. Real transparent alpha background.
Art style: convincing classic RPG Maker / 16-bit JRPG walking character art, compact expressive chibi-adult proportions, about 2.3 heads tall, LARGE 12-pixel-wide head, short sturdy legs, compact torso, clean outlined pixel clusters, rich restrained 1989 crime-story palette. Original character, not any existing RPG Maker asset or copyrighted character. Not realistic thin-limbed proportions. Pixel art at a native 48 x 64 pixel resolution PER CELL, upscaled exactly 4x with nearest-neighbor pixels. No smooth painting, no anti-aliasing, no 3D.
Character: original adult male street survivor with thick tousled dark brown hair, visible brows, warm skin, slightly tired determined face, faded blue denim/leather jacket with cream collar over an ivory T-shirt, dark trousers, brown boots. No hat. He always visibly holds an ordinary warm wood baseball bat with a dark red wrapped handle. Bat and both hands form one connected drawing, never floating. Keep face, clothes and body size perfectly consistent across ALL 32 cells.
Rows: row 1 faces SOUTH (toward camera), row 2 WEST (left profile), row 3 EAST (right profile), row 4 NORTH (back to camera). Top-down three-quarter RPG camera, same viewpoint all cells, no perspective change.
Columns, same sequence in each row:
1 neutral combat-ready standing, bat resting by shoulder;
2 left-foot-forward walk with bat held;
3 right-foot-forward walk with bat held;
4 light attack WINDUP, torso coiled, hands loading the bat;
5 light attack CONTACT, bat visibly extended in the facing direction, body stepping into strike;
6 light attack FOLLOW-THROUGH, bat across body, feet apart;
7 heavy attack RAISED OVERHEAD, both hands clearly connected to bat handle;
8 heavy attack SLAM CONTACT, knees bent, hands and bat brought forcefully down and forward in the facing direction.
Alignment is critical: ground center at local pixel (96,224) in EVERY 192x256 cell, equivalent to native (24,56). Neutral body is about 136 pixels tall (native 34px), so hair begins around local y=88. Head is about 48 pixels wide (native12px). Feet stay on the same baseline even for attack poses; no shadows or ground discs. Full bat including overhead raise must fit inside each cell. Leave at least 16 transparent pixels around each cell edge. No overlapping or clipped sprites. Uniform scale, strong readable hand-designed silhouettes, limited coherent palette. This is a usable game atlas, not a concept-art poster.

## Survivor refinement

Edit this exact sprite atlas for game use. Preserve the same original blue-jacket character, proportions, pixel style, ALL poses, the EXACT 1536x1024 canvas, and EXACT 8-column by 4-row cell layout (192x256 per cell).
CRITICAL CHANGE 1: Remove the entire brown/black gradient backdrop, glow, ground shading, and all shadows. Every pixel outside the character/bat silhouettes MUST have true transparent alpha 0. Do not replace it with black, white, checkerboard, a colored backdrop, or an imitation transparency pattern. Export real transparent PNG.
CRITICAL CHANGE 2: In column 6 (follow-through) of each of the four rows, the character currently has empty hands. Restore a wooden baseball bat physically attached to those hands in the follow-through pose. No frame may have an absent or floating bat.
CRITICAL CHANGE 3: Keep sprites entirely inside their own 192x256 cells with at least 8 transparent pixels clearance at every cell edge; in particular contact bats must not enter neighboring cells. Preserve consistent body sizes and feet baselines. Do not add text or grid lines. Do not alter anything else.

## Street Thug prompt

Use this sprite sheet as a STRICT layout, proportion, pose and pixel-art style reference. Create a matching original STREET THUG sprite atlas, not another blue-jacket hero.
Keep the exact 1536x1024 canvas, 8 columns by 4 rows (192x256 cells), feet locations, chibi-adult RPG proportions and original classic RPG character style. Keep all 32 poses in the same order. Rows face south, west, east, north. Columns: idle, left walking step, right walking step, light windup, light contact, light follow-through, overhead windup, overhead slam.
Replace the character consistently in EVERY frame: stocky adult street thug with a broad jaw, dark buzzcut and stubble, worn rust-red sleeveless vest over charcoal shirt, dark olive cargo trousers, scuffed black boots, bare forearms with a simple dark wrist wrap. He holds a battered SHORT STEEL PIPE with both hands visibly gripping it. Use the same restrained pixel-cluster quality, head/body ratio and body height as the reference so both characters belong to one game. Not a palette swap of the hero: clearly different hair, face, build and clothing.
TRUE transparent alpha background, no ground shadows, no backdrop/glow. Every weapon must remain attached to the hands and visibly present in ALL frames including follow-through. Keep every pipe and body fully inside its own cell with transparent clearance; contact poses must not bleed into neighboring cells. No labels, no grid, no letters or watermark. These will be cropped into a working Godot game; consistency and clean sprite silhouettes are mandatory.
