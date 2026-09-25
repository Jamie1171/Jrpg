# The Unfinished Dawn — game design and production plan

Updated: 25 September 2026. Working title; full story spoilers in linked treatment.

## Purpose and decision status

The goal is to finish a complete, cohesive, playable JRPG and learn through building it. Learning design, software development, asset production, testing and collaboration with coding agents is part of the project's value. Commercial release and income are possible additional outcomes, not conditions for completing the game. Lack of commercial traction alone is not a reason to abandon it.

Jamie directs the game and tests builds from a phone. Development proceeds through small, reviewable repository changes and playable Android releases. The current instruction authorises this planning document, not implementation of the systems below.

This document consolidates the September discussions. It is the current system and production reference where older planning notes conflict. The [story treatment](../story/the-unfinished-dawn-treatment.md) remains the detailed narrative reference; The Hearthroad and other [earlier concepts](../research/android-jrpg-market-and-story-foundations.md) remain preserved alternatives. Names, scene details and tuning can evolve.

| Status | Meaning |
|---|---|
| Direction | Explicit goals and preferences expressed by Jamie; guide subsequent work. |
| Proposal | Recommended implementation or balance choice, not silently approved or already implemented. |
| Open | Needs design work or playtesting before a decision. |

**Direction:** freely rotatable stylised 3D; a cohesive story with loss, betrayal and a final antagonist; conventional turn-based combat and class identities; exploration and revisiting places; meaningful side quests and trades; equipment, loot and level progression; a level-100 character cap; random equipment-appropriate enchantments whose available tiers improve with enchanting skill, with cheaper retries.

**Proposals:** four active combatants, fixed character classes with specialisation branches, the exact stat list, magic acquisition, crafting quality rules, enchantment safeguards, respawn rules and milestone scope below. These are a starting design, not locked balance.

## What exists today

Preview 0.2.1 has three 3D locations, direct movement and a rotatable camera, touch and default Xbox controls, conversations, Rowan and Cael's opening battle, fishing, a fishing reward, selling fish, a journal, inventory, music and local saves. It ends at Ysra's arrival, before the festival and raid. Jamie reports solid frame rate and working controller support on his phone; this is not a performance measurement across devices.

The current character models and environments are an early art pass. The full campaign, general equipment system, character levelling, class progression, mining, crafting and enchanting are not implemented. Current battle values are prototype values, not the balance specification for the finished game.

## Experience and world

The player follows Rowan's story while choosing how deeply to explore, pursue side quests and develop trades. Story structure gives events consequences; it does not require every region to become inaccessible after its chapter.

Use connected towns, outdoor regions, routes and dungeons rather than requiring one seamless open world. Unlock shortcuts and fast travel after discovery. Revisited places should offer changed conversations, quests, gathering opportunities and evidence of earlier events. Story emergencies can briefly constrain travel; clearly signal this and restore exploration afterward. Do not automatically scale every old enemy to the party's level.

Trades should feel rewarding in their own right: useful gear, collections, visible mastery, new recipes, tools, optional locations and NPC relationships. Main-story completion must remain feasible without mastering them. The economy must nevertheless make crafted equipment genuinely competitive.

## Narrative spine and content planning

Retain the treatment's causal sequence:

| Stage | Story purpose and player experience |
|---|---|
| Brackenford | Establish Rowan, Mira, Tessa and Cael through playable ordinary life, delivery work and festival preparations. Ysra's arrival precedes the raid and Mira's death. |
| Stoneharbour | Find Ysra, seek lawful redress and discover official complicity. Reunite with surviving family; establish a recurring refuge. |
| Marsh islands | Recruit Nessa through a shared rescue objective. Rowan's pursuit of Hadrik has consequences for other people. |
| Rookspine | Meet Orin and opposing captain Bram; capture the Crown and learn why destroying it would kill bound soldiers. |
| Harrowfield | Discover and test the release rite; uncover the morally difficult truth about Rowan's father. |
| Merrow Abbey | Cael voluntarily betrays the party, surrendering the Crown and Orin to Veyr. Earlier disagreements must earn this development. |
| Rebuilding alliances | Recover from betrayal, recruit Bram and assemble support. Allow meaningful choice in the order of regional tasks. |
| Capital and finale | Apply the previously established release rite while confronting Veyr. Each companion contributes; no unrelated last-minute villain replaces him. |
| Epilogue | Show changed lives and places, resolve the central conflict and allow continued optional exploration where the story permits. |

The treatment's Crown rules and character motivations remain authoritative. Essential explanations belong on the main path, not solely in optional quests. Protect player investment when a companion leaves: return equipped gear and preserve shared profession progression.

For each chapter, write a playable scene outline recording objectives, available routes, recruitment, information revealed, battle lessons, required assets and state changes. Maintain a reveal ledger so later revelations have earlier setup. Plan the whole ending early, then script and build chapters in manageable sections.

## Combat, classes and character growth

Use familiar, fully paused turn-based decisions. Proposed baseline: four active characters when the roster allows, smaller parties earlier, reserves receiving adequate experience to remain usable, and a visible speed-based turn order. Four is the current proposal; the older treatment's three-person party is not a final constraint.

| Command | Proposed role |
|---|---|
| Attack | Dependable action using the equipped weapon, its damage type and relevant effects. No ordinary MP cost. |
| Defend | Reliable damage mitigation until the character's next turn; initially trial around 50% reduction and a small MP recovery. Prefer this to relying only on a chance to evade. |
| Magic | Class-permitted spells with elemental, healing, protection or control functions. |
| Skills | Class-specific physical or tactical abilities; initially use the same MP resource, with cooldowns only where useful. |
| Items | Healing, remedies and tactical consumables, with clear targets and effects. |

Exact formulas, defend behaviour, turn ordering, interruption, item revival rules and cooldowns need specification and testing. Do not assume a community Godot combat framework is built into the engine. Evaluate an existing framework against the current project before adopting it; replace working foundations only for a concrete benefit.

Proposed identities: Rowan as a spellblade/Wayblade, Cael as a protective knight, Ysra as a healer and ward specialist, Nessa as a ranger with traps and utility, Orin as an elemental runesage, and Bram as a defensive vanguard. These are familiar roles expressed through the existing cast, not a commitment to add a new thief companion. Agile leather users can be supported without changing the story roster.

Proposed progression: essential abilities arrive through character levels; occasional class points develop two specialisation branches, with an affordable respec. Additional class-compatible spells can come from teachers, tomes, shops, exploration and quests. Crafting may improve spells or supporting equipment without making every ordinary cast consume gathered materials.

Character level cap: 100. The previously discussed story finish around levels 65–75 is only a candidate pacing target. Build and test an early level band before extrapolating a hundred levels of stats.

Proposed core stats: HP, MP, physical attack/defence, magic attack/defence and speed. Bound secondary accuracy, evasion, critical chance and resistance so stacking cannot remove all challenge. Class determines base growth; equipment modifies the result. Keep character level and profession proficiency separate.

Candidate magic elements: fire, ice, lightning, earth, light and dark; physical types: slash, pierce and crush. Avoid adding a complex universal element wheel unless it improves decisions. Clearly reveal learned weaknesses and resistances. Boss control resistance should preserve useful tactical options instead of making every status skill pointless.

## Equipment and parallel crafting routes

Direction: weapon, offhand, body, head, accessory and boots. Classes define legal equipment. Two-handed weapons occupy both hands; dual wielding needs a shared power budget rather than granting a free second full-strength turn. Offhands can include shields, light weapons, magical focuses or support objects.

Metal, leather and cloth are parallel equipment families, not one universal progression from cloth to plate. A high-tier robe should remain a valid endgame caster item. Protection, mobility, magical utility and class abilities give the families different strengths at comparable overall power.

The material names below are examples, not a final resource catalogue.

| Route | Gathering and processing | Example progression | Typical outputs |
|---|---|---|---|
| Smithing | Mine ores; smelt metals and alloys at a forge. | Copper/bronze, iron/steel, then regional fantasy metals such as mythril and adamantine. | Blades, metal armour, shields, fittings and some tools. |
| Leatherworking | Collect hides from suitable creatures or purchase them; tan and prepare leather. | Common hides, supple or tough regional hides, rare specialised hides. | Light armour, boots, gloves represented within outfits, belts and straps. |
| Weaving and tailoring | Gather flax or other fibre plants; process fibre into thread and fabric. Acquire wool, silk or fantasy fibres through farms, traders, creature drops and quests as appropriate. | Linen, wool or silk variants, reinforced fabrics and rare arcane textiles. | Robes, cloth headwear, caster outfits and textile components. |
| Woodworking | Cut suitable trees and process timber. | Common woods, resilient regional woods and rare specialist timber. | Staves, bows, handles, shields and optional furnishings. |
| Enchanting | Obtain magical reagents through exploration, drops, vendors and optional salvage. | Higher proficiency unlocks higher enchantment tiers. | Compatible random magical effects on equipment from any route. |

Bronze is made from copper and tin; steel is processed from iron with carbon. They are not ordinary ore veins. Stone is a separate quarrying/building material. Fantasy deposits can have their own clearly defined rules.

Keep each route understandable. Weaving and tailoring may be one profession at first; tanning may be a leatherworking operation rather than another XP bar. Recipes may share components without forcing mastery of every profession: vendors can supply ordinary thread, leather strips and fittings.

Examples of varied cloth acquisition: gather flax by the river, buy wool from a farming settlement, collect silk from appropriate creatures, and earn rare fibres through a woodland side quest. Each major equipment tier needs practical sources for metal, leather and cloth so one class is not left behind by the available materials.

## Enchanting: random effects, growing tiers, cheaper retries

**Jamie's direction:** materials do not deterministically choose the finished effect. Enchanting proficiency improves access to effect tiers; the actual effect is random, constrained by equipment type and who can wield it. A player can try again at a reduced cost.

Proposed first design:

1. Choose an eligible item and an enchantment tier unlocked by proficiency and allowed by the item's equipment tier. Show the cost, eligible effects and their odds before committing.
2. Pay a reagent cost for that tier, independent of which effect is rolled. Randomly select from the compatible effect pool. Higher proficiency unlocks stronger tiers; it does not make a chosen material guarantee fire damage or another particular result.
3. Start with one random enchantment slot per item. Store the effect, tier and value on that individual item. Keep authored unique item properties separate.
4. Allow rerolling that slot at the same tier for less than the initial application cost, with a non-zero cost floor. The exact discount needs economic testing. A higher-tier upgrade requires a new tier-appropriate payment; cheap low-tier rerolls must not create top-tier gear.
5. Recommended protection, still a proposal: preview the rolled replacement and let the player keep either the old or new effect. The paid attempt is consumed either way. A reroll may otherwise produce a different useful effect, so perfection is optional rather than necessary for progression.

Filter first, then roll. A caster-only focus should not receive a bonus requiring an unavailable sword skill. A shared accessory should use broadly useful effects or a pool compatible with all its legal users. This also avoids equipment changing unexpectedly when moved between characters. The precise handling of hybrid classes and shared gear remains open.

Candidate pools include weapon damage/status effects; robe MP economy, ward strength or resistance; light armour speed, evasion or utility; heavy armour protection and retaliation; boots mobility-related combat effects. These are illustrations of compatibility, not a final effect list. Cap stacking and speed/MP discounts across slots.

Important safeguards to specify before implementation:

- Save the item result and material deduction atomically; reopening the menu or reloading must not provide free rerolls.
- Prevent ordinary cheap rerolls becoming the best way to farm enchanting XP. First crafts, meaningful tier-appropriate work and commissions should drive mastery.
- Choose whether to exclude the current effect from a reroll and whether to add a bad-luck safeguard after testing. Do not promise either yet.
- Decide whether numerical strength within a tier is fixed or rolled. Random effect identity is already enough uncertainty for the first version.
- Re-enchanting an old item at higher proficiency should be explicit, not a silent stat upgrade to every stored item.
- Use only earned in-game resources for this system; paid rerolls are not part of the proposal.

A crafted iron sword remains an iron sword with workmanship and an enchantment. Any earlier named anti-beast sword example was illustrative, not a requirement to feed specific beast materials into a guaranteed enchantment recipe. Authored named treasures may still have fixed signature properties.

## Gathering, professions and other trades

Mining nodes have a variable yield range, clear proficiency/tool requirements and regional distribution. An iron seam in an early forest can become a reason to return later. Avoid tying all gathering access to character combat level. Keep low-tier materials useful in selected components and commissions without demanding enormous repeated quantities.

Respawns should support return visits without encouraging door-crossing exploits or requiring real-world waiting. Initial proposal: reset eligible resource nodes and enemies after a defined rest or expedition cycle; persistent chests follow separate rules. Exact rules and yields remain open.

Make gathering briefly interactive: read a seam, choose a safe extraction or pursue a richer but riskier section; identify a fishing cue and choose an action. Mastered ordinary tasks should permit efficient repetition or batching. Avoid demanding a long minigame for every unit of ore, and provide alternatives to precision timing.

Smithing success is an open design point. Jamie suggested proficiency-based success chances. Recommended baseline: learned, appropriate recipes always yield usable equipment; skill improves workmanship, efficiency and access to advanced recipes. If risky advanced attempts are included, show the odds and provide salvage rather than routinely destroying rare ingredients. Confirm this trade-off before building the system.

Alchemy supplies MP recovery, remedies and tactical mixtures. Fishing and foraging support cooking, healing and preparation buffs. Proposed limit: one active meal preparation effect, so menus do not become a chore of stacking every dish. Professions belong to the shared player progression, not a companion who can permanently leave.

Give trades optional stories, commissions and mastery rewards. Never put the only critical story clue or required release rite behind a profession grind.

## Loot, shops and economy

Use a shared equipment power budget. Separate material/equipment tier, workmanship, random enchantment and authored special properties. Rarity should indicate meaningful reward characteristics, not multiply every stat without limits.

| Source | Intended value |
|---|---|
| Standard shops | Reliable, affordable regional baseline for a player following the story. |
| Vendor specials | Occasional interesting or better offers within the area's power limits. |
| Exploration and fixed treasures | Distinctive properties, named items, useful upgrades and discovery rewards. |
| Random regional chests | Weighted pools appropriate to area, rarity and reward value; avoid filling most discoveries with irrelevant junk. |
| Crafting | Choice of useful equipment at least competitive with shops; investment enables better workmanship and specialised combinations. |
| Enchanting | Further customisation and long-term improvement across found, bought and crafted gear. |

Most ordinary chests can draw from regional reward pools; major story or signature rewards are fixed. Persist rewards so reloads do not offer cost-free rerolling, and mark emptied chests. Most chests are one-time exploration rewards, unlike renewable resource nodes.

Vendor specials should refresh through an explicit in-game event or rest cycle, not a real-world urgency timer. Persist their inventory. Check that refreshes do not trivialise exploration or eliminate the value of crafting.

Enemies have distinct stats, behaviour, abilities, resistances and weighted drops. Make essential progression materials reliably obtainable through at least one route. A rare optional drop is acceptable; a necessary upgrade hidden behind hundreds of identical kills is not the goal.

Balance gold income, resource availability, crafting XP, equipment costs, reroll costs and sale values together. Gathering and selling is a legitimate income route; infinite buy-craft-sell or buy-salvage-reroll profit loops require explicit prevention unless deliberately designed. Protect unique quest items from sale and explain known material uses.

## Encounters and side quests

Visible overworld enemies are the proposed default, consistent with Jamie's preference. Use roaming silhouettes or actual monster models, clear contact behaviour and a short post-battle safety window. Species, territory and relative strength can affect aggression; not every stronger monster must chase or every weaker monster flee.

A field strike can grant a modest opening advantage, not an automatic full-party victory turn. Story and quest XP, encounter placement and fair boss expectations should let players avoid some optional fights without being forced into a grinding wall.

A random-encounter option remains a possible later feature, not initial scope. Two encounter systems require separate pacing and testing. The pasted 80–85% preference figures have not been established as representative market evidence and are not a design assumption.

Prioritise authored side quests involving people, exploration and consequential rewards. Repeatable trade commissions can support them but should not replace them. Make return routes useful, distinguish main and optional objectives, and let the journal help a player resume after time away.

## Visuals, cutscenes, audio and mobile production

Target a coherent stylised 3D look inspired by PS2-era JRPG readability, with improved presentation where affordable. Reuse modular architecture, shared materials, appropriate texture atlases, skeletons and animations. Keep silhouettes, palette, scale and texture treatment consistent across procedural, generated and hand-edited assets.

Godot and Blender remain the established foundation. Meshy is a possible asset source, not a prerequisite or an approved purchase. Before committing to a paid pipeline, evaluate a representative character, monster and prop in the game for visual consistency, animation, cleanup effort, licensing, file size and device performance. Check current subscription/API costs and retry terms at that point; do not assume they are interchangeable.

Asset workflow: concept/reference → model → topology and deformation review → UV/material work and suitable baking → rig/animation → Godot import → phone inspection. Decimation alone does not ensure good animated topology. Baked ambient occlusion can supply contact/crevice shading; it does not replace every lighting need. Atlases and polygon budgets do not guarantee frame rate.

Use in-engine cutscenes with the same actors and locations, staged cameras, animation, dialogue, music and sound. Skipping must apply the same quest changes and rewards as watching. Full voice acting and rendered video are optional later choices, not dependencies for a complete story.

Planning allowance, not a forecast: aim initially around 1 GB installed for a substantial game and reassess after measuring representative finished assets. Unique textures, audio, animation and video dominate more than recipe or level counts. Track APK/download size separately from installed size. Preserve touch and controller usability throughout; judge heat and sustained performance on physical devices.

## Technical foundations and saves

Use stable data IDs for characters, classes, items, individual equipment instances, effects, recipes, enemies, loot tables, quests and regions. Separate rules and persistent state from presentation so tuning does not require rewriting scenes.

Before random equipment or professions ship, extend versioned saves to preserve inventory instances, rolled effects, profession XP, chest rewards, vendor stock and respawn state. Provide migrations and backup recovery. Avoid duplicate rewards when a dialogue is skipped, a map is re-entered or the app is interrupted.

Test meaningful risks: legal equipment, stat stacking limits, damage/healing rules, quest transitions, reward persistence, crafting deductions, reroll transactions and update/save compatibility. Validate menus with both touch and controller. Automated rules checks support, but cannot replace, playtests for pacing and enjoyment.

## Production order toward a complete game

Milestones are acceptance gates, not delivery-date promises. They control the amount built at once; they do not replace the complete-game objective with an endless demo.

| Milestone | Deliverable | Ready to advance when |
|---|---|---|
| 1. Design the opening and first progression band | Opening scene outline; first regional enemy/ability/item tables; comparable metal, leather and cloth gear; candidate crafting and enchantment rules. | One explore → fight → reward → improve → harder encounter loop can be explained and balanced on paper. Open decisions are explicitly recorded. |
| 2. Build reusable progression foundations | Inventory/equipment instances, stats and level growth, combat commands, persistent rewards and the menus/save migrations they need. | The loop works with touch and controller; equipment changes are understandable and survive an update. |
| 3. Prove trades and the art target | One useful recipe for each equipment family, a representative gathering interaction, random enchanting with cheaper retries, and one polished character/environment corner. | Every class family gets useful equipment; crafting competes with shops; rerolls persist; the art holds up in motion on the phone. Expand recipes only after this works. |
| 4. Complete and polish chapter one | Festival, raid and escape with staged scenes, battle pacing, optional activities, audio and recovery checkpoints. | A new player understands Rowan's relationships, objectives and loss, and can finish the chapter without mandatory profession grinding. |
| 5. Establish chapter two and reusable regional content | Stoneharbour, Ysra, return travel, side quests and a second balanced progression band. | Existing systems support another region without special-case rewrites; cloth/leather/metal and non-crafting players remain viable. |
| 6. Build the complete campaign | Remaining chapters in dependency order, staggered recruitment, betrayal, finale and epilogue. | The entire story is playable from a fresh save to a real ending, even while some assets still need polish. |
| 7. Finish the game | Replace placeholders, tune economy and difficulty, refine cutscenes and audio, test devices, accessibility and long saves. | The full campaign has been played through, critical defects resolved, assets accounted for and installation/update behaviour verified. |
| 8. Decide release format | Optional public release, pricing/unlock model, store requirements and support plan. | Publication is deliberately chosen; the completed game and learning remain worthwhile regardless of sales. |

Work on the visual sample alongside early mechanics rather than postponing all art until the end or creating an entire asset catalogue before the systems work. Expand each trade from a tested useful loop. Specify the first few levels and equipment tiers thoroughly before filling the whole level-100 progression.

For each milestone, leave a short decision record, explain why major implementation choices were made, and attach concrete phone playtest questions. This makes the development process a learning record as well as a growing game.

## Decisions to resolve next

1. Confirm active party size and the first class progression model.
2. Specify the opening's playable scenes, first enemy band and comparable equipment for the available classes.
3. Choose learned-recipe crafting guarantees versus failure risk and salvage.
4. Choose enchanting tier selection, old-versus-new result retention, duplicate handling and the initial reroll discount.
5. Define gathering/merchant refresh rules and baseline resource availability.
6. Approve a representative finished visual sample before expanding asset production or paying for an asset-generation service.

Commercial options previously discussed—paid download or a free opening with a one-time full unlock—remain open. No price, conversion assumption, launch date, paid subscription or revenue target is a commitment in this plan.
