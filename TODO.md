# Son Yolcu outcomes

- [ ] Mobile portrait/offline-capable browser game: Turkish default, Azerbaijani text, PWA, later Android packaging. The original no-backend requirement was superseded by the user's request for a managed database and cross-device saves.
- [ ] Full night: eight chapters with seven guests each, swipes and accessible alternatives; rooms, firewood, trust, chapter meters, clue magnifiers, peephole questions, random weather and meaningful failure/survival endings.
- [ ] Content: at least 60 individually authored guests with hidden types, clues, appearance, chapter conditions and 15 connected guests; the first night follows the source's story chapters, later nights reshuffle eligible guests.
- [ ] Narrative systems: 40 daily rules, radio lines, delayed chapter reports, notebook with notes/tags/clues/answers and Rahim's eight persistent discoveries, plus distinct chapter events and optional waiting timer.
- [ ] Progression: 30 titled replayable nights with escalating difficulty; points, permanent upgrades, saved settings, unlocked-ending gallery, 20 ending definitions and the conditional ninth storm chapter.
- [ ] Screens and style: minimal dark hotel scene, thin unnumbered meters, clock, text and two quiet bottom tools, inline event choices, simple character silhouettes, Turkish typewriter typography, settings, tutorial and no modals or bright visual effects.
- [ ] Delivery: meaningful automated gameplay checks, offline build, mobile/touch support, README and a saved playable checkpoint; report outstanding placeholders and next improvements.
- [ ] Managed account saves: provision the project database and server; use Manus sign-in and authenticated, player-owned database rows to persist progress, notes, current night, upgrades, endings and settings across devices.
- [ ] Offline-first synchronization: keep local saving and offline play; reconcile saves on reconnect, prevent one player from accessing another player's save, and avoid silently overwriting conflicting local or cloud progress.

## Current implementation and open items

- The playable eight-chapter loop, meters, tap/swipe choices, clues, questions, notebook, chapter events, reports, local saves and conditional storm chapter are implemented. A deterministic full-night run and native-renderer screen exercise have passed.
- Content currently contains 70 authored guests (39 with relationship links), 30 titled nights, 40 rule entries, 26 upgrades and 20 ending definitions, with Turkish and Azerbaijani text. More complex late-night double-lie/relationship variants and some delayed consequences are simplified, so the corresponding full-spec outcomes remain open.
- Rules reuse a smaller set of underlying gameplay effects. Guest portraits are minimalist procedural silhouettes; sound cues are synthesized placeholders, not recorded ambience.
- The PWA export is configured with a manifest and service worker, but real-device installation and offline behavior, touch input, audio and the mobile keyboard still need acceptance testing. Android wrapping and signing are documented, not implemented.
- Automated gameplay checks and the game README are present. Final export, packed-release validation and checkpoint registration must succeed before the delivery item can be considered complete.
