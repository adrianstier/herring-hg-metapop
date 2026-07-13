# Deck Build Decision

Decision date: 2026-05-17.

## Decision

Build a fresh 20-slide Royal Society deck in
`analysis/04_talks/2026-royalsociety/Talk_Materials/`, reusing the Drive deck's assets and
selected visual components, rather than cutting the 35-slide EEMB142C teaching
deck down to size.

## Reason

The Drive deck is useful raw material, but it is a 50-minute undergraduate
teaching deck with a different spine. The Royal Society slot is a short expert
talk in Session 5, "Tipping Points in Ecosystem Services", and the chair asked
for solutions. The current canonical sequence is already a different argument:
three separable layers, a management window, portfolio erosion, held predator
mechanisms, and a solutions close.

## Build Rule

- Reuse `DRV-ASSETS` photos/videos, especially spawn, k'aaw, Gwaii Haanas,
  collaborator, and predator clips.
- Reuse the timeline visual system:
  `analysis/04_talks/2026-royalsociety/Talk_Materials/herring_haida_gwaii_timeline.html`.
- Use `build1_spine.html` as the first shared visual artifact for slides
  2, 12, and 20.
- Treat `DRV-DECK` as a source deck, not the final template.
- Keep the current model firewall: `m1_stier_11` is the promoted baseline;
  predator and Doherty material are context/bridge slides unless explicitly
  marked as held.

## Immediate Production Path

1. Export or redraw the three-layer spine as an editable slide group or high-
   resolution placed image for slides 2, 12, and 20.
2. Build the remaining heavy proof objects: S7 portfolio build, S10 predator
   demand build, S14 hysteresis build.
3. Pull static proof objects from the current figure set and provenance notes.
4. Render a contact sheet before final `.pptx` export.
5. Send final `.pptx` to `scientific.meetings@royalsociety.org`.
