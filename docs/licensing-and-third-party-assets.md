# Licensing and Third-Party Assets

## Adopted project licensing policy

The project uses a split license by content type:

- **Source code and project configuration:** [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).
- **Original artwork:** [Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/). This covers original models, textures, animations, UI art, concept art, and visual effects made for the project.
- **Audio:** not assigned by this decision. License original music, sound effects, and voice work separately before adding them to a public release.
- **Third-party content:** remains under its own recorded license and is never relicensed automatically by these project terms.

Before publishing, add the complete, unmodified Apache 2.0 text as the root `LICENSE` file, retain [ARTWORK_LICENSE.md](../ARTWORK_LICENSE.md), and maintain [THIRD_PARTY.md](../THIRD_PARTY.md).

CC BY 4.0 allows reuse and adaptation with attribution. Keep artwork authorship and modification records so the project can provide sensible credits. The attribution requirements are described in the [official CC BY 4.0 legal code](https://creativecommons.org/licenses/by/4.0/legalcode).

## Asset provenance rule

Every third-party asset, plug-in, texture, sound, font, model, code snippet, or reference pack must have a source and license recorded before it is committed. Free-to-download does not automatically mean free to redistribute in a game repository.

Create and maintain `THIRD_PARTY.md` at the repository root once external content begins. A template is included in this scaffold. Use this simple table:

| Item | Type | Source URL | Creator | License | Version/date | Modified? | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Example Terrain Add-on | Godot add-on | `https://…` | Creator | MIT | 1.2.0 | No | License copy in `addons/...` |

## What to keep with a dependency

- The original license and any required notice text.
- The exact version or download date.
- Attribution wording if required.
- The source file/URL and whether the asset was modified.
- Any usage limitation, including whether commercial use or redistribution is allowed.

For an add-on, preserve its included license file under the add-on directory when supplied. For a marketplace asset, retain the purchase/terms record outside the public repository if redistribution is restricted.

## Safe choices for the prototype

- Original models made by the team, with authorship noted.
- Assets under permissive licenses such as CC0 or compatible open licenses, after checking the exact terms.
- Godot Asset Library add-ons only after checking the repository license and Godot version compatibility.

Avoid assets with unclear provenance, non-redistributable licenses, untraceable AI-source claims, or terms that conflict with the intended project distribution. Do not copy assets from commercial games or images found through a search engine.

## Attribution and release checklist

Before a public build or repository release:

- [ ] Add the complete Apache 2.0 text as the root `LICENSE` covering project code.
- [ ] Keep `ARTWORK_LICENSE.md` and add credits for original CC BY 4.0 artwork.
- [ ] State the license/status for original audio and documentation.
- [ ] Ensure `THIRD_PARTY.md` is complete and links/copies notices as required.
- [ ] Include required attribution in credits, About screen, or distribution page.
- [ ] Confirm every included item permits the intended commercial/non-commercial use and redistribution.
- [ ] Remove accidental source files, downloaded packs, or references that cannot be distributed.

This document is a practical workflow note, not legal advice. If the project is commercial or uses a license with special conditions, review the terms carefully or seek qualified legal advice.
