# Element templates

Copy a template, change the id, coordinates, and colors, and delete nothing else. Fields not listed (angle, version, groupIds, and so on) take Excalidraw's defaults, so omit them. Colors come from `color-palette.md`.

## File wrapper

```json
{
  "type": "excalidraw",
  "version": 2,
  "source": "https://excalidraw.com",
  "elements": [],
  "appState": { "viewBackgroundColor": "#ffffff", "gridSize": 20 },
  "files": {}
}
```

## Conventions

- `id`: a descriptive string (`ingest_box`, `ingest_label`, `arrow_ingest_queue`), unique in the file.
- `seed`: any integer, unique per element. Give each section its own range (section one 1000-1999, section two 2000-2999) so later edits never collide.
- Coordinates are canvas pixels, y grows downward. `width` and `height` of a line or arrow are the absolute extent of its `points`.
- `fontFamily` values: `1` hand-drawn Virgil, `2` sans, `3` monospace, `5` Excalifont, `6` Nunito. Use `3` unless the user asks otherwise.
- Text size: height is `lines * fontSize * 1.25`. Width is about `0.6 * fontSize` per character for monospace (`fontFamily: 3`) and `1.0 * fontSize` per CJK character. Measure the longest line, then add a margin; the render shows whether it fits.

## Free-floating text

The default for titles, labels, and annotations. `textAlign: "left"` anchors at `x`; use `"center"` with a wide box when centering under a shape.

```json
{
  "id": "section_title",
  "type": "text",
  "x": 0,
  "y": 0,
  "width": 220,
  "height": 20,
  "text": "Ingest pipeline",
  "originalText": "Ingest pipeline",
  "fontSize": 16,
  "fontFamily": 3,
  "textAlign": "left",
  "verticalAlign": "top",
  "strokeColor": "#111827",
  "opacity": 100,
  "lineHeight": 1.25,
  "seed": 1001
}
```

Typographic hierarchy replaces boxes: titles `fontSize` 28 to 36, section headings 20 to 24, labels 16, annotations 12 to 14 in `#4b5563`.

## Text inside a container

Put the text id in the container's `boundElements` and the container id in `containerId`. Position the text so it is centered in the container (`x + (containerWidth - textWidth) / 2`).

```json
{
  "id": "ingest_box",
  "type": "rectangle",
  "x": 0,
  "y": 40,
  "width": 180,
  "height": 70,
  "strokeColor": "#1d4ed8",
  "backgroundColor": "#dbeafe",
  "fillStyle": "solid",
  "strokeWidth": 2,
  "roughness": 0,
  "opacity": 100,
  "roundness": { "type": 3 },
  "seed": 1002,
  "boundElements": [{ "id": "ingest_label", "type": "text" }]
}
```

```json
{
  "id": "ingest_label",
  "type": "text",
  "x": 20,
  "y": 62.5,
  "width": 140,
  "height": 25,
  "text": "Ingest\nvalidate + queue",
  "originalText": "Ingest\nvalidate + queue",
  "fontSize": 16,
  "fontFamily": 3,
  "textAlign": "center",
  "verticalAlign": "middle",
  "containerId": "ingest_box",
  "strokeColor": "#111827",
  "opacity": 100,
  "lineHeight": 1.25,
  "seed": 1003
}
```

## Shapes

Same fields as the rectangle above; change `type`, drop `roundness` for diamonds and ellipses. Size diamonds about 1.6 times larger than a rectangle holding the same text.

- Start or end: `"type": "ellipse"`
- Process: `"type": "rectangle"`
- Decision: `"type": "diamond"`

## Line

Leader lines, tree branches, dividers, and timeline spines. Points are relative to `x`, `y`.

```json
{
  "id": "timeline_spine",
  "type": "line",
  "x": 0,
  "y": 300,
  "width": 600,
  "height": 0,
  "points": [
    [0, 0],
    [600, 0]
  ],
  "strokeColor": "#6b7280",
  "strokeWidth": 2,
  "roughness": 0,
  "opacity": 100,
  "seed": 1004
}
```

## Small dot

A timeline marker or bullet. 12 to 16 pixels, filled.

```json
{
  "id": "timeline_dot_1",
  "type": "ellipse",
  "x": 94,
  "y": 294,
  "width": 12,
  "height": 12,
  "strokeColor": "#1d4ed8",
  "backgroundColor": "#1d4ed8",
  "fillStyle": "solid",
  "strokeWidth": 1,
  "roughness": 0,
  "opacity": 100,
  "seed": 1005
}
```

## Arrow with bindings

Start the arrow 2 pixels outside the source edge and end 2 pixels short of the target edge. `points` run from the arrow origin to its end. Both ends are bound, and each bound shape lists the arrow in its own `boundElements`; keep the two sides consistent. `focus` shifts the attachment point along the edge (-1 to 1, 0 is the middle).

```json
{
  "id": "arrow_ingest_queue",
  "type": "arrow",
  "x": 182,
  "y": 75,
  "width": 96,
  "height": 0,
  "points": [
    [0, 0],
    [96, 0]
  ],
  "strokeColor": "#6b7280",
  "strokeWidth": 2,
  "roughness": 0,
  "opacity": 100,
  "startArrowhead": null,
  "endArrowhead": "arrow",
  "startBinding": { "elementId": "ingest_box", "focus": 0, "gap": 2 },
  "endBinding": { "elementId": "queue_box", "focus": 0, "gap": 2 },
  "seed": 1006
}
```

Matching entries on the shapes:

```json
"boundElements": [
  { "id": "ingest_label", "type": "text" },
  { "id": "arrow_ingest_queue", "type": "arrow" }
]
```

Dashed arrow for optional or asynchronous flows: add `"strokeStyle": "dashed"`. Label an arrow with a free-floating text element placed next to its midpoint.

## Evidence block

A dark rectangle with free-floating monospace text on top. The text is not bound to the rectangle, so line breaks and colors stay under your control; give it its own `x`, `y` inside the rectangle with 12 pixels of padding.

```json
{
  "id": "event_block",
  "type": "rectangle",
  "x": 0,
  "y": 140,
  "width": 300,
  "height": 110,
  "strokeColor": "#374151",
  "backgroundColor": "#111827",
  "fillStyle": "solid",
  "strokeWidth": 1,
  "roughness": 0,
  "opacity": 100,
  "roundness": { "type": 3 },
  "seed": 1007
}
```

```json
{
  "id": "event_block_text",
  "type": "text",
  "x": 12,
  "y": 152,
  "width": 276,
  "height": 80,
  "text": "{\n  \"event\": \"order.created\",\n  \"id\": \"ord_1042\"\n}",
  "originalText": "{\n  \"event\": \"order.created\",\n  \"id\": \"ord_1042\"\n}",
  "fontSize": 16,
  "fontFamily": 3,
  "textAlign": "left",
  "verticalAlign": "top",
  "strokeColor": "#e5e7eb",
  "opacity": 100,
  "lineHeight": 1.25,
  "seed": 1008
}
```
