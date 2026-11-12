---
user-invocable: true
description: "Remake a chart or image as a 2003 personal homepage (Geocities starfield, Xanga/MySpace pink, Comic Sans, rainbow text, hit counter). Same data and numbers as the original, only the styling changes; the original is never touched. Use for 'make it retro', 'geocities/xanga/myspace-ify', 'retro version of the charts', or /nick:xanga [image or chart]. Flags: `--stars`, `--hearts`, `--post`."
---

# xanga

A joke remix of a chart Nick already has: a Datadog chart, a shipping-post card, any image. The
joke is the styling. The numbers stay true.

Kit: `~/.dotfiles/agents/skills/nick/skills/xanga/scripts/retro_kit.py` (python3, no deps,
headless Chrome at 2x, page height measured for you). Call it `$KIT` below. Run it with
`PYTHONDONTWRITEBYTECODE=1` so no `__pycache__` lands in the dotfiles repo.

## 1. Find the target

- Argument is an image path, or "the charts" from this session: use those.
- No argument: the charts or images this session made last. None? Ask which image.
- Several charts: one retro image per original.

## 2. Redraw it (the default)

The flashy version is a full redraw: every bar, label and stat box restyled. A border around the
plain chart is not it. Nick, on a bordered example: "don't seem as flashy as the originals."

1. Get the data. Read the regular chart's generator and data file, or re-pull the series
   (`pup`). List every number, label, date range, marker, footnote and source line it shows.
2. Write a small `gen_retro.py` beside the regular generator. It reads the **same data file**,
   computes every figure, and writes a spec JSON. No hard-coded numbers, so a later
   "regenerate" keeps the pair in step.
3. Render: `python3 $KIT series <spec.json>` or `python3 $KIT top <spec.json>`
   (`--theme stars|hearts`, `--out <png>`; default output is `<spec>.png`).

| Chart | Builder | Default theme |
|---|---|---|
| bars or points over time, an event marker | `series` | `stars` |
| ranked before/after per customer, "Top N" | `top` | `hearts` |

`series` spec:

```json
{"title": "Acme job times", "sub": "✨ time per run ✨ each bar = 1 run!! (jan 5 – jan 9, UTC)",
 "banner": "UNDER CONSTRUCTION ⚠ (jk it's fast now)",
 "chips": [{"k": "before the fix (jan 6)", "v": "20 min / run", "tone": "before"},
           {"k": "after the fix!!!", "v": "30 sec / run", "tone": "after"},
           {"k": "typical acme run", "v": "25 → 5 min"}],
 "points": [{"t": "2026-01-05T00:30:00Z", "v": 20.0}],
 "y": {"max": 30, "ticks": [0, 10, 20, 30], "unit": "min"},
 "start": "2026-01-05T00:00:00Z",
 "marker": {"t": "2026-01-07T12:00:00Z", "label": "FIX LIVE!!1! 1/7 @ 12:00 UTC"},
 "after_from": "2026-01-07T12:10:00Z", "note": "30 sec!!!",
 "source": "source: datadog job logs · fix: PR #1234", "hits": "0031337"}
```

Points after `after_from` (default: the marker) get the glowing "after" color; a point can set
`"after": true` itself. `start`, `end`, `bar_width`, `burst` are optional.

`top` spec:

```json
{"title": "My Top 7 Customers", "mood": "ecstatic", "sub": "time per run · before = jan 6 avg",
 "chips": [{"k": "typical run, acme", "v": "25 → 5 min"}],
 "rows": [{"name": "Acme", "before": 1200, "after": 30, "before_label": "20 min", "after_label": "30 sec"}],
 "legend": {"before": "before the fix (jan 6)", "after": "after the fix!!!", "extra": "12 customers save 10+ sec per run"},
 "source": "source: datadog job logs · fix: PR #1234 · ✨ thx 4 visiting!! ✨", "hits": "0001234"}
```

`before`/`after` size the bars; the labels are printed as given, plus `:(` and `!!! :D`. The
right column is the computed change (`-98%!!`); set `"delta"` on a row to override it. `burst`
(`["OMG", "98%", "FASTER"]`) is optional.

Both: `banner`, `mood`, `chips`, `burst` work in either builder. Titles get `~*~ ~*~` and a
rainbow; `series` titles are sPoNgEcAsEd, `top` titles are not (`"sponge_title"` flips it).

A chart shape these two don't cover: import `page`, `render`, `spongecase`, `counter`, `burst`
from the kit and write the body by hand, using the kit's classes (`.chip`, `.bar`, `.tag`,
`.hazard`) so it matches.

## 3. Last resort: frame

Only when the data can't be had (someone else's screenshot):

```
python3 $KIT frame <image> --title "..." [--theme stars|hearts] [--mood ecstatic] [--sub "..."] \
  [--banner "UNDER CONSTRUCTION"] [--tag "FIX LIVE!!1!"] [--burst "OMG|98%|FASTER"] [--source "..."] [--hits 0001234]
```

Writes `<image>-retro.png`. Say plainly that the chart inside is unchanged, and why a redraw
wasn't possible.

## 4. Flavor

Two charts, no flag: one `stars`, one `hearts`. `--stars` / `--hearts` forces one for all.

- hit counter (`hits`): the PR number, zero-padded, is a good value
- `mood`, "sign my guestbook", "thx 4 visiting!!", "best viewed at 800x600" in `source`
- retro spelling in labels: `sec!!!`, `b4`, `jan 6`

## 5. Same facts, different paint

Nick: "the chart pairs should basically show the same data and metrics, but just styled
differently."

- Every number, unit, date range, marker and source line on the regular chart is on the retro
  one, with the same value. Nothing extra, nothing dropped.
- Retro spelling is fine. Rounding differently is not.
- A joke never adds a claim. "UNDER CONSTRUCTION (fixed now lol)" hinted at a regression the
  regular chart left out, so it was cut. If the regular chart avoids a topic, so does this one.
- A `burst` or `tag` only repeats a figure already on the chart.

## 6. Check and hand over

1. Read each PNG. Look for labels overlapping bars, a tag or burst covering data, a chip row
   wrapping. Fix the spec and re-render before showing anything.
2. Put the pair side by side and tick off the list from step 2.1.
3. Copy to `~/Downloads/<original-name>-retro.png` and `open` them. The originals stay where
   they are, so "undo" is just using the regular set.
4. Report as a two-column table, Regular | Retro, with absolute paths.
5. `--post`, or Nick asks "and the message?": write a retro version of the post text too. Same
   facts, same link, same length cap. Deliver it like any pasteable (file, `pbcopy`, fenced
   block).

## Never

- Never edit or overwrite the regular image, its generator, or the regular post text.
- Never post or attach the image anywhere. Nick picks the set and posts it.
