# Son Yolcu — implementation

Build a portrait-first, offline Godot browser game from the attached specification, preserving the user's approved change from React/TypeScript to Godot. Use a local save, no server, and an application-owned PWA export.

The game is a quiet, low-contrast narrative decision game. A small mountain hotel silhouette sits behind a single card. Thin rules and typewriter text use charcoal, muted cream and a restrained warm-orange accent. Guest portraits use simple combinable geometric outlines. Interactions are swipes and accessible text buttons; story, choices, events and reports remain inline, with no modals. Motion is limited to subtle snow, swipes and meter changes.

## Structure

- `data/`: guest, rules, radio, chapter and ending content.
- `localization/`: player-facing Turkish and Azerbaijani strings.
- `scripts/game/son_logic.gd`: the authoritative night, event and ending rules.
- `scripts/son_main.gd`: title, card, notebook, event, progression and settings presentation.
- `assets/son-yolcu/`: replaceable hotel illustrations, icon and licensed monospace font.
- `web/loading.html` and Godot export preset: branded loader and offline browser build.
- `test/son_logic_check.gd`: bounded checks of meters, guest selection and endings.

The initial story night uses the authored chapter groups; later nights recombine eligible guests, weather, rules and radio. Settings, discovered story, upgrades, endings and completed nights persist locally. The initial playable goal is a complete night with chapter events, notebook, magnifiers, multiple endings and a permanent upgrade; the full specification remains the target.
