# Son Yolcu — implementation

Build a portrait-first, offline-capable Godot browser game from the attached specification, preserving the user's approved change from React/TypeScript to Godot. Keep the local save and application-owned PWA export. The user subsequently requested a managed database and Manus sign-in for cross-device saves, superseding the original no-server constraint; the game remains playable offline and synchronizes when an authenticated connection is available.

The game is a quiet, low-contrast narrative decision game. A small mountain hotel silhouette sits behind a single card. Thin rules and typewriter text use charcoal, muted cream and a restrained warm-orange accent. Guest portraits use simple combinable geometric outlines. Interactions are swipes and accessible text buttons; story, choices, events and reports remain inline, with no modals. Motion is limited to subtle snow, swipes and meter changes.

## Structure

- `data/`: guest, rules, radio, chapter and ending content.
- `localization/`: player-facing Turkish and Azerbaijani strings.
- `scripts/game/son_logic.gd`: the authoritative night, event and ending rules.
- `scripts/son_main.gd`: title, card, notebook, event, progression and settings presentation.
- `assets/son-yolcu/`: replaceable hotel illustrations, icon and licensed monospace font.
- `web/loading.html` and Godot export preset: branded loader and offline browser build.
- `test/son_logic_check.gd`: bounded checks of meters, guest selection and endings.
- `server/`: the managed authentication backend, player-owned save API and additive database migrations; credentials stay server-side.
- The game save and account integration retain the local copy, synchronize account-owned snapshots across devices, and expose a safe resolution when local and cloud saves conflict instead of silently overwriting progress.

The initial story night uses the authored chapter groups; later nights recombine eligible guests, weather, rules and radio. Settings, discovered story, upgrades, endings and completed nights persist locally. The initial playable goal is a complete night with chapter events, notebook, magnifiers, multiple endings and a permanent upgrade; the full specification remains the target.
