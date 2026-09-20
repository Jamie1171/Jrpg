# Jrpg

A story-led, turn-based JRPG designed around a mobile playtesting workflow and a zero additional development-spend target.

**The first playable Brackenford opening is implemented in Godot 4.5.1.**

![Brackenford in the playable game](docs/preview/village.webp)

[Download the Android preview from Releases](https://github.com/Jamie1171/Jrpg/releases),
or check [the Android build](https://github.com/Jamie1171/Jrpg/actions/workflows/android.yml).

The opening includes the inn, village and woodland; portrait conversations;
Rowan and Cael's first battle; optional fishing and a permanent reward; a journal,
inventory, original music and local saves. It ends with Ysra's arrival, before the
festival and the raid. The illustrated environments and animated sprites use a
coherent rendered 2D style. This is an early playable chapter, not the full game.

- [Phone playtesting guide](docs/production/phone-playtesting.md)
- [Build and technical notes](docs/production/build-notes.md)
- [Art and audio provenance](docs/art/asset-manifest.md)

Current creative direction: a cohesive adventure with loss, betrayal, developing party relationships and a decisive confrontation with its main antagonist. Mining, crafting, fishing and other trades offer substantial optional achievement and rewards alongside that story.

- [From story to a playable Android game](docs/production/from-story-to-playable.md): production order, visual approach, remote builds and the first Brackenford milestone.
- [The Unfinished Dawn — alternative story treatment](docs/story/the-unfinished-dawn-treatment.md): protagonist, antagonist, staggered companion recruitment, revealed backstory, betrayal, chapter progression and ending; includes a separate optional trade progression.
- [Android JRPG research and story foundations](docs/research/android-jrpg-market-and-story-foundations.md): the original investigation and earlier concepts. **The Hearthroad remains an available option**, alongside The Names We Keep and The Wandering Table. Its recommendation reflects the earlier brief, not a final selection.

The research compares 13 Android JRPGs and two adjacent crafting games and records 45 public Google Play review observations. All proposed titles, casts, settings and mechanics remain discussion drafts; no story has been selected as final canon.

The `game/` folder is the native Godot project. Open `game/project.godot` in Godot
4.5.1 to run it on a computer. Android APKs build automatically through GitHub
Actions; no editor installation on the player's phone is required.
