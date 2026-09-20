# Brackenford asset manifest

Created 20 September 2026 for the first playable opening of The Unfinished Dawn.
These are original generated illustrations, not extracted commercial game assets.
The final game uses compressed WebP copies at the original generated dimensions;
transparent sprite sheets retain their alpha channel. Cropping into animation and
portrait cells is performed by Godot at runtime. There is no image generation API
dependency when playing or building the game.

| Asset in `game/assets/` | Layout and purpose | Origin |
| --- | --- | --- |
| `art/brackenford.webp` | 1672×941, village background | OpenAI image generation |
| `art/inn.webp` | 1672×941, Hearth & Heron background | OpenAI image generation |
| `art/woodland.webp` | 1672×941, exploration/battle background | OpenAI image generation |
| `art/party_walk.webp` | 1536×1024; 6×4 cells of 256px | OpenAI image generation |
| `art/characters.webp` | 1536×1024; 3×2 cells of 512px | OpenAI image generation |
| `art/portraits.webp` | 1536×1024; 3×2 cells of 512px | OpenAI image generation |
| `audio/brackenford.ogg` | Original 40-second quiet village theme | Procedural composition; `tools/make_music.py` |
| `fonts/DejaVuSerif.ttf` | Heading font | DejaVu; bundled licence in the same folder |
| `icon.svg` | Original sun-and-river launcher emblem | Project-authored SVG |

Walking sheet: columns 0–2 Rowan (left step, idle, right step), columns 3–5 Cael;
rows down, left, right, up. Character sheet: Mira, Tessa, Ysra / Orren, mossback boar,
Petra. Portrait sheet: Rowan, Cael, Mira / Tessa, Ysra, Orren.

The art direction is warm late-summer light, teal shadows, timber and white plaster,
golden ground, natural proportions and expressive adult faces. Rowan wears a teal
cloak and courier satchel; Cael light armour and a muted red scarf. This visual
language can later accommodate additional environments and trades.

Full prompts are preserved in [generation-prompts.json](generation-prompts.json).
Generated assets still need consistency and originality review as the project
expands; this prototype does not establish exclusive ownership of an art style.

Godot's engine licence, bundled third-party notices and the font licence ship in
`game/THIRD_PARTY_NOTICES.txt`. Project-created code, story and assets have not been
given an additional blanket open-source licence by this change. A public repository
alone is not a licence grant.
