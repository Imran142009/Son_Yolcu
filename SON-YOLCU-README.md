# Son Yolcu

A portrait-first, offline Godot 4 narrative card game. Decide who enters the mountain hotel, inspect clues, write notes, manage rooms, wood and trust, and reach dawn. Turkish is the default; Azerbaijani is available in settings. Progress, notes and settings are saved locally by Godot's `user://` storage (the browser build uses persistent browser storage where supported).

## Run

Open `project.godot` in Godot 4.7 or run `godot --path .`. The project uses the GL Compatibility renderer. Run the gameplay checks with `godot --headless --path . --script res://test/son_logic_check.gd` or `npm run check` in the managed project.

## Web and offline use

Export with the `Web` preset in `export_presets.cfg`. Its PWA option creates the manifest, icons and service worker. Serve the generated files over HTTPS or localhost; the first load requires a connection, then the browser may use the installed offline cache. Browser storage and service-worker availability depend on browser settings and are not guaranteed in private browsing. The game has no backend and does not call paid services at runtime.

## Android

For a future Android app, use Godot's Android export with the matching Godot export templates, Android SDK, JDK and signing configuration. Alternatively, export the web build and package the exported web assets in a Capacitor Android shell; install and configure Capacitor and Android Studio in that separate wrapper project. Native Godot export is the more direct route for this Godot implementation. Neither wrapper nor release signing is included here.

## Content and structure

`data/guests.json`, `data/content.json` and `data/nights.json` contain game content and translations; `localization/` contains interface copy. `scripts/game/son_logic.gd` owns the night state and decisions; `scripts/son_main.gd` renders the interface; `scripts/game/son_save.gd` owns persistence. Replaceable hotel PNGs and the icon are in `assets/son-yolcu/`. The DejaVu Sans Mono license is kept next to the font.

## Current limitations

The first story night uses the authored chapter groups; later nights reshuffle the eligible guests. Rules share a smaller set of underlying effects, and later-night double-lie and relationship variants are simplified. Some story and event outcomes use generalized reports rather than individually authored consequences. The Android wrapper is documentation only, and browser install/offline behavior still requires testing on the player's device.
