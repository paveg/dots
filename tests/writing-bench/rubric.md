# Writing-Bench Judge Rubric

For the LLM judge (Tier 2 of ADR 0006). The judge runs in a session separate from generation, on opus. Give it: this rubric, `~/.claude/references/japanese-writing/norms.md`, the prompt file, and the generated artifact. The judge scores 4 axes, 1–5 each, and must cite at least one concrete passage per axis as evidence.

## Axes

| Axis             | Norms section it operationalizes                  | What 5 looks like                                                                                                                     | What 1 looks like                                                                      |
| ---------------- | ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| naturalness      | Rhythm / AI-smell taxonomy / Audience             | Reads as written by a careful human; vocabulary passes the audience test（正本・正典のような翻訳借用語ゼロ）; varied sentence lengths | Template lists, hype words, translationese, uniform sentence rhythm                    |
| structure        | Structure / Volume and shape (shape half)         | Conclusion first at document and section level; form matches information structure (list/prose/table); one purpose                    | Buried conclusions, connective-chained bullets, mixed purposes, h4+ nesting            |
| volume           | Volume and shape (volume half) / Cognitive rhythm | Nothing to cut: every sentence updates the reader's situation; targets respected or exceeded for stated cause                         | Restated context, progress announcements, sections far past 400 字 with no split       |
| diagram_judgment | markdown-formatting "When to diagram"             | Diagrams appear exactly where the trigger table fires (and nowhere else), correct type, ≤10 nodes                                     | Prose walls where a trigger clearly fired, or decorative diagrams no trigger justifies |

Score anchors: 5 = no finding a reviewer would raise; 4 = minor findings only; 3 = one clear IMPORTANT finding; 2 = several IMPORTANT findings; 1 = the axis's failure mode dominates the artifact.

## Judge output format

One JSON object per artifact:

```json
{
  "artifact": "01-pr-body-bugfix.md",
  "naturalness": 4,
  "structure": 5,
  "volume": 3,
  "diagram_judgment": 4,
  "evidence": {
    "naturalness": "…quoted passage + one-line reason…",
    "structure": "…",
    "volume": "…",
    "diagram_judgment": "…"
  }
}
```

## Judge constraints

- Judge the artifact against the prompt's stated facts only; a claim not present in the prompt material is a `volume`/`naturalness` deduction (invented content), not a bonus.
- Do not reward length. The prompts state everything that must appear; anything beyond it must earn its place.
- Prompt files carry an HTML comment with the expected mode and any planted trap（例: 10 番の translationese trap）— use it to direct attention, not to prejudge the score.
