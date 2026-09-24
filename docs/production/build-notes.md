# Current build: 0.2.0

The active renderer is now true 3D. See [3D direction](3d-direction.md) for the
current architecture, asset pipeline and limitations. The 0.1.0 notes below
record the earlier implementation and are retained as history.

# The first playable build

Engine: **Godot 4.5.1**, GDScript, Compatibility renderer. World coordinates are
1280×720 with aspect-preserving scaling. Android uses a native ARM64 engine, not a
web wrapper. All gameplay is offline and no external inference APIs are called.

## Structure

| File | Responsibility |
| --- | --- |
| `game/scripts/main.gd` | Touch interface, dialogue presentation, scene progression, battle/fishing screens |
| `game/scripts/world_view.gd` | Illustrated maps, walking animation, navigation and interactions |
| `game/scripts/game_state.gd` | Versioned saves, recovery, quest events and permanent rewards |
| `game/scripts/battle_model.gd` | Deterministic turn-based combat, exposure, guard and interruption |
| `game/scripts/fishing_model.gd` | Turn-based fishing cues, tension and catch rules |
| `game/data/dialogue.json` | Authored opening conversations |
| `game/tests/test_game.gd` | Progression, reward, combat, navigation and save/recovery tests |
| `.github/workflows/android.yml` | Import, tests, rendered playthrough, Android export and downloadable preview |

State changes and inventory rewards have unique event IDs to prevent repeated
dialogue from awarding items twice. Saves use a temporary file, atomic replacement
and a last-valid backup. Bad data is validated before loading; an unreadable primary
can recover the backup. Saves are device-local. In-flight battles are intentionally
restarted from their prior checkpoint on reload.

## Running and verifying

Install Godot 4.5.1 and open `game/project.godot`, or run:

```sh
godot --headless --path game --editor --import --quit
godot --headless --path game --script tests/test_game.gd
godot --path game
```

The game supports WASD/arrows and E/Space as well as touch. An automated rendered
playthrough is available with `godot --path game --audio-driver Dummy -- --qa`.
Set `JRPG_SCREENSHOTS` to its output directory. This mode disables normal save
writes and exercises the opening, a successful battle, three catches and the charm.
CI runs it with Xvfb/software OpenGL. Rule tests use a separate disposable save path.

Android exporting uses Java 17, SDK platform 35 and build-tools 35.0.1. On a clean
Linux runner, `tools/install_godot.py` downloads pinned engine/template archives and
verifies their SHA-256 checksums. `tools/configure_android.py` reads the SDK and Java
paths from the environment and configures the editor. Export with:

```sh
godot --headless --path game --export-debug Android ../build/UnfinishedDawn-0.1.0.apk
```

The public test signing identity in `tools/preview-signing/` is **only** for this
prototype's separate `.preview` package. It preserves update compatibility between
builds; it is not a private production signing key. See that directory's notice.

## Verified and still to verify

The initial rules suite passes 64 checks, including valid/invalid saves, backup
recovery, one-time quest rewards, partner skill effects, victory, both fishing spots,
over-tension failure, trading and routes remaining on walkable floor. A rendered
desktop playthrough reaches the end of the opening and the optional fishing reward.
Screens are visually inspected in the real engine. APK signing and alignment are
checked after export.

Physical Android installation, GPU performance, touch comfort, audio and app
background/resume behaviour still need an actual phone playtest. This build is not
a complete campaign, a final combat balance pass, or a Play Store release.

Known prototype limits: fixed illustrated maps; NPCs have standing frames; two
playable classes; one story encounter; a small inventory; no equipment menu beyond
the automatic charm; no mining, woodcutting, smithing or crafting yet. Fishing is
turn-based rather than a real-time timing game. Dialogue cutscenes use portraits and
in-engine staging rather than rendered video. The full story treatment and earlier
concept options remain preserved.

Technical references: [Godot Android export](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_android.html)
and [command-line export](https://docs.godotengine.org/en/4.5/tutorials/editor/command_line_tutorial.html).
