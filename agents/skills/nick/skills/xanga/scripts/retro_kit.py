#!/usr/bin/env python3
"""2003-homepage chart kit for /nick:xanga.

  retro_kit.py series <spec.json>   bars over time: neon bars, stat boxes, tilted event tag
  retro_kit.py top <spec.json>      ranked before/after rows: "My Top N", rainbow bars, -98%!!
  retro_kit.py frame <image>        last resort: wrap a picture that can't be redrawn

Spec fields are documented in SKILL.md. Every number and label comes from the spec; the kit only
draws. For a chart shape these don't cover, import page(), render(), spongecase(), counter() and
burst() and write the body by hand.
"""
import argparse
import datetime
import html
import json
import os
import re
import subprocess

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
WIDTH = 980
FONT = '"Comic Sans MS", "Chalkboard SE", cursive'
RAINBOW = "#ff0000, #ff8800, #ffee00, #33ff00, #00ccff, #6633ff"
UTC = datetime.timezone.utc
esc = html.escape

_HEART_TILE = ("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='44' height='40'>"
               "<text x='4' y='18' font-size='14' fill='%23ff99cc'>&#9829;</text>"
               "<text x='26' y='36' font-size='11' fill='%23cc99ff'>&#9733;</text></svg>")

# stars = Geocities (neon on a starfield). hearts = Xanga/MySpace (pink, dotted, glitter).
THEMES = {
    "stars": """
:root { --ink: #fff; --sub: #ffff66; --foot: #ccccff; --axis: #00ffff; --label: #ff99ff; --name: #ffff66; --rule: #6633ff;
  --before: linear-gradient(180deg, #ff00cc, #9900ff); --before-edge: #ff99ee;
  --after: #39ff14; --after-edge: #ccffcc; --after-glow: 0 0 8px #39ff14, 0 0 14px #39ff14;
  --chip-bg: #000080; --chip-edge: #00ffff; --chip-k: #00ffff; --chip-before: #ff66ff; --chip-after: #39ff14; --chip-plain: #ffff00;
  --glow: 0 0 6px #39ff14; --good: #39ff14; --bad: #ff99ff; --delta: #ffff00; --delta-shadow: #ff00cc; }
body { background-color: #000010;
  background-image: radial-gradient(1.6px 1.6px at 20px 30px, #fff 50%, transparent 51%), radial-gradient(1px 1px at 90px 70px, #ffffaa 50%, transparent 51%),
    radial-gradient(1.4px 1.4px at 140px 20px, #aaddff 50%, transparent 51%), radial-gradient(1px 1px at 60px 120px, #fff 50%, transparent 51%),
    radial-gradient(1.8px 1.8px at 170px 140px, #ffccff 50%, transparent 51%);
  background-size: 190px 160px; }
.frame { border: 6px ridge #ff00cc; background: rgba(20, 0, 40, 0.75); }
""",
    "hearts": f"""
:root {{ --ink: #660066; --sub: #993399; --foot: #993399; --axis: #ff3399; --label: #9900cc; --name: #9900cc; --rule: #ffb3e0;
  --before: repeating-linear-gradient(90deg, #ff99cc 0 8px, #ffccee 8px 16px); --before-edge: #ffccee;
  --after: linear-gradient(90deg, {RAINBOW}); --after-edge: #ccffcc; --after-glow: none;
  --chip-bg: #ffe0f4; --chip-edge: #ff99dd; --chip-k: #993399; --chip-before: #cc0066; --chip-after: #cc0066; --chip-plain: #cc0066;
  --glow: none; --good: #009900; --bad: #993366; --delta: #ff0066; --delta-shadow: #ffcc00; }}
body {{ background-color: #ffe6f5; background-image: url("{_HEART_TILE}"); }}
.frame {{ border: 4px dotted #ff3399; background: #fff8fd; box-shadow: 6px 6px 0 #cc66ff; }}
""",
}

BASE_CSS = f"""
* {{ box-sizing: border-box; }}
html, body {{ margin: 0; }}
body {{ width: {WIDTH}px; padding: 18px 22px; font-family: {FONT}; color: var(--ink); }}
h1 {{ margin: 0; font-size: 32px; text-align: center; }}
.rainbow {{ background: linear-gradient(90deg, {RAINBOW}, #ff00cc); -webkit-background-clip: text; background-clip: text; color: transparent; }}
.sub {{ text-align: center; font-size: 15px; margin: 2px 0 10px; color: var(--sub); }}
.sub b {{ color: #ff0066; }}
.frame {{ position: relative; padding: 12px; }}
.frame img {{ display: block; width: 100%; }}
.counter {{ display: inline-flex; gap: 2px; vertical-align: middle; }}
.counter span {{ background: #000; color: #39ff14; font: bold 15px "Courier New", monospace; padding: 1px 4px; border: 2px inset #888; }}
.hazard {{ background: repeating-linear-gradient(45deg, #ffdd00 0 14px, #111 14px 28px); color: #111;
  padding: 6px; text-align: center; border: 3px outset #ffdd00; margin-bottom: 12px; }}
.hazard b {{ background: #ffdd00; padding: 2px 10px; border: 2px solid #111; font: bold 15px "Arial Black", Impact, sans-serif; letter-spacing: 1px; }}
.chips {{ display: flex; gap: 12px; justify-content: center; margin-bottom: 12px; }}
.chip {{ border: 4px outset var(--chip-edge); background: var(--chip-bg); padding: 6px 14px; text-align: center; min-width: 190px; }}
.chip .k {{ color: var(--chip-k); font-size: 13px; }}
.chip .v {{ font-size: 24px; font-weight: bold; color: var(--chip-plain); }}
.chip.before .v {{ color: var(--chip-before); }}
.chip.after .v {{ color: var(--chip-after); text-shadow: var(--glow); }}
.tag {{ position: absolute; white-space: nowrap; background: #ff0000; color: #ffff00; border: 3px outset #ffff00;
  font: bold 14px {FONT}; padding: 3px 8px; transform: rotate(-3deg); z-index: 2; }}
.burst {{ position: absolute; right: -8px; top: -34px; width: 132px; height: 132px; background: #ffff00; display: flex; align-items: center;
  justify-content: center; text-align: center; transform: rotate(10deg); z-index: 2;
  clip-path: polygon(50% 0%, 61% 25%, 88% 12%, 77% 40%, 100% 50%, 77% 60%, 88% 88%, 61% 75%, 50% 100%, 39% 75%, 12% 88%, 23% 60%, 0% 50%, 23% 40%, 12% 12%, 39% 25%); }}
.burst span {{ font: bold 17px {FONT}; color: #ff0000; line-height: 1.05; }}
.foot {{ display: flex; justify-content: space-between; align-items: center; gap: 16px; margin-top: 12px; font-size: 12px; color: var(--foot); }}

.series.frame {{ padding: 30px 22px 30px 64px; }}
.plot {{ height: 300px; position: relative; border-left: 3px solid var(--axis); border-bottom: 3px solid var(--axis); }}
.bar {{ position: absolute; bottom: 0; background: var(--before); border: 1px outset var(--before-edge); }}
.bar.after {{ background: var(--after); border-color: var(--after-edge); box-shadow: var(--after-glow); }}
.markline {{ position: absolute; top: -22px; bottom: 0; border-left: 3px dashed #ffff00; }}
.markline .tag {{ top: -26px; right: 8px; }}
.note {{ position: absolute; bottom: 34px; white-space: nowrap; font-size: 16px; font-weight: bold; color: var(--good); text-shadow: var(--glow); }}
.yl {{ position: absolute; left: 6px; font-size: 13px; color: var(--axis); }}
.day {{ position: absolute; bottom: -24px; font-size: 13px; color: var(--label); }}

.top.frame {{ padding: 12px 18px 14px; }}
.row {{ display: grid; grid-template-columns: 200px 1fr 90px; align-items: center; padding: 5px 0; border-bottom: 2px dashed var(--rule); }}
.row:last-of-type {{ border-bottom: none; }}
.name {{ font-size: 16px; font-weight: bold; color: var(--name); }}
.b {{ display: inline-block; height: 15px; vertical-align: middle; border: 2px outset var(--before-edge); background: var(--before); }}
.b.after {{ background: var(--after); border-color: var(--after-edge); box-shadow: var(--after-glow); }}
.v {{ font-size: 13px; margin-left: 8px; vertical-align: middle; color: var(--bad); }}
.v.a {{ color: var(--good); font-weight: bold; }}
.delta {{ text-align: right; font-size: 20px; font-weight: bold; color: var(--delta); text-shadow: 1px 1px 0 var(--delta-shadow); }}
.legend {{ text-align: center; font-size: 12px; margin-top: 8px; }}
.legend .b {{ width: 28px; height: 11px; }}
"""


def spongecase(s):
    out, up = [], False
    for ch in s:
        if ch.isalpha():
            out.append(ch.upper() if up else ch.lower())
            up = not up
        else:
            out.append(ch)
    return "".join(out)


def counter(digits):
    return '<span class="counter">' + "".join(f"<span>{c}</span>" for c in str(digits)) + "</span>"


def burst(lines):
    return '<div class="burst"><span>' + "<br>".join(esc(x) for x in lines) + "</span></div>"


def page(theme, body, extra_css=""):
    return (f'<!doctype html><html><head><meta charset="utf-8"><style>{THEMES[theme]}{BASE_CSS}{extra_css}</style></head>'
            f"<body>{body}<script>addEventListener('load', () => {{ document.body.dataset.h = document.documentElement.scrollHeight }})</script></body></html>")


def _chrome(*args):
    # Headless Chrome often exits non-zero on teardown after doing its job, so callers check the output instead.
    return subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", *args], capture_output=True, text=True, timeout=120)


def render(out_png, page_html, height=None, width=WIDTH):
    """Write the page beside out_png and screenshot it at 2x. Height is measured from the page unless given."""
    out_png = os.path.abspath(out_png)
    src = os.path.splitext(out_png)[0] + ".html"
    with open(src, "w") as f:
        f.write(page_html)
    if height is None:
        m = re.search(r'data-h="(\d+)"', _chrome(f"--window-size={width},400", "--dump-dom", f"file://{src}").stdout)
        if not m:
            raise RuntimeError("could not measure the page height; pass height=")
        height = int(m.group(1))
    if os.path.exists(out_png):
        os.remove(out_png)
    r = _chrome("--force-device-scale-factor=2", f"--window-size={width},{height}", f"--screenshot={out_png}", f"file://{src}")
    if not os.path.exists(out_png):
        raise RuntimeError(f"Chrome wrote no screenshot (exit {r.returncode}): {r.stderr[-400:]}")
    return out_png


def _ts(s):
    return datetime.datetime.fromisoformat(s.replace("Z", "+00:00")).astimezone(UTC)


def _header(spec, sponge):
    title = spongecase(spec["title"]) if spec.get("sponge_title", sponge) else spec["title"]
    out = f'<h1 class="rainbow">~*~ {esc(title)} ~*~</h1>'
    parts = ([f'current mood: <b>{esc(spec["mood"])}</b> &#9786;'] if spec.get("mood") else []) + ([esc(spec["sub"])] if spec.get("sub") else [])
    if parts:
        out += f'<div class="sub">{" &middot; ".join(parts)}</div>'
    if spec.get("banner"):
        out += f'<div class="hazard"><b>&#9888; {esc(spec["banner"])}</b></div>'
    return out


def _chips(spec):
    chips = spec.get("chips") or []
    if not chips:
        return ""
    return '<div class="chips">' + "".join(
        f'<div class="chip {esc(c.get("tone", ""))}"><div class="k">{esc(c["k"])}</div><div class="v">{esc(c["v"])}</div></div>' for c in chips) + "</div>"


def _foot(spec):
    return (f'<div class="foot"><span>{esc(spec.get("source", "best viewed at 800x600"))}</span>'
            f'<span>visitors: {counter(spec.get("hits", "0031337"))}</span></div>')


def series(spec, theme="stars"):
    pts = sorted(spec["points"], key=lambda p: p["t"])
    y = spec["y"]
    marker = spec.get("marker")
    t0 = _ts(spec["start"]) if spec.get("start") else _ts(pts[0]["t"]).replace(hour=0, minute=0, second=0, microsecond=0)
    last = _ts(pts[-1]["t"])
    t1 = _ts(spec["end"]) if spec.get("end") else last + (last - t0) * 0.05
    span = (t1 - t0).total_seconds()
    pct = lambda t: (t - t0).total_seconds() / span * 100
    after_from = _ts(spec.get("after_from") or marker["t"]) if (spec.get("after_from") or marker) else None
    bw = spec.get("bar_width", 6)
    bars = []
    for p in pts:
        t = _ts(p["t"])
        after = p.get("after", after_from is not None and t > after_from)
        h = max(4, min(1, p["v"] / y["max"]) * 300)
        bars.append(f'<div class="bar{" after" if after else ""}" style="left:calc({pct(t):.3f}% - {bw / 2}px);width:{bw}px;height:{h:.0f}px"></div>')
    ticks = "".join(f'<span class="yl" style="top:{30 + (1 - v / y["max"]) * 300 - 9:.0f}px">{esc(f"{v:g} " + y.get("unit", "")) if v else "0"}</span>'
                    for v in y.get("ticks", [0, y["max"]]))
    days, d = "", t0.replace(hour=0, minute=0, second=0, microsecond=0)
    while d < t1:
        if 0 <= pct(d) < 96:
            days += f'<span class="day" style="left:{pct(d):.2f}%">{d.strftime("%b %-d").lower()}</span>'
        d += datetime.timedelta(days=1)
    mark = note = ""
    if marker:
        mark = f'<div class="markline" style="left:{pct(_ts(marker["t"])):.3f}%"><div class="tag">&#9733; {esc(marker["label"])} &#9733;</div></div>'
    if spec.get("note"):
        left = f'calc({pct(_ts(marker["t"])):.3f}% + 24px)' if marker else "24px"
        note = f'<div class="note" style="left:{left}">{esc(spec["note"])}</div>'
    body = (_header(spec, True) + _chips(spec)
            + f'<div class="frame series">{burst(spec["burst"]) if spec.get("burst") else ""}{ticks}<div class="plot">{"".join(bars)}{mark}{note}{days}</div></div>'
            + _foot(spec))
    return page(theme, body)


def top(spec, theme="hearts"):
    rows_in = spec["rows"]
    biggest = max(max(r["before"], r["after"]) for r in rows_in)
    rows = []
    for r in rows_in:
        delta = r.get("delta") or f'{(r["after"] / r["before"] - 1) * 100:+.0f}%!!'
        rows.append(f"""<div class="row"><div class="name">&#9734; {esc(spongecase(r["name"]))} &#9734;</div>
  <div><div class="b" style="width:{max(8, r["before"] / biggest * 430):.0f}px"></div><span class="v">{esc(r["before_label"])} :(</span><br>
  <div class="b after" style="width:{max(8, r["after"] / biggest * 430):.0f}px"></div><span class="v a">{esc(r["after_label"])}!!! :D</span></div>
  <div class="delta">{esc(delta)}</div></div>""")
    lg = spec.get("legend", {})
    extra = f' &nbsp;&middot;&nbsp; {esc(lg["extra"])} &#10024;' if lg.get("extra") else ""
    legend = (f'<div class="legend"><span class="b"></span> {esc(lg.get("before", "before"))} &nbsp;&nbsp; '
              f'<span class="b after"></span> {esc(lg.get("after", "after!!!"))}{extra}</div>')
    inner = _header(spec, False) + _chips(spec) + "".join(rows) + legend
    body = f'<div class="frame top">{burst(spec["burst"]) if spec.get("burst") else ""}{inner}</div>' + _foot(spec)
    return page(theme, body, "h1 { font-size: 30px; margin-bottom: 2px; } .chip { border-width: 3px; padding: 5px 14px; } .chip .v { font-size: 20px; } .chip .k { font-size: 12px; }")


def frame(spec, theme="stars"):
    stickers = (burst(spec["burst"]) if spec.get("burst") else "") + (
        f'<div class="tag" style="top:-14px;left:24px">&#9733; {esc(spec["tag"])} &#9733;</div>' if spec.get("tag") else "")
    body = (_header(spec, True) + _chips(spec)
            + f'<div class="frame">{stickers}<img src="file://{os.path.abspath(spec["image"])}"></div>' + _foot(spec))
    return page(theme, body, ".burst { top: -84px; right: -12px; }")


BUILDERS = {"series": (series, "stars"), "top": (top, "hearts")}

if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sp = ap.add_subparsers(dest="cmd", required=True)
    for name in BUILDERS:
        c = sp.add_parser(name)
        c.add_argument("spec", help="JSON spec file")
        c.add_argument("--theme", choices=sorted(THEMES))
        c.add_argument("--out", help="default: <spec>.png")
    f = sp.add_parser("frame")
    f.add_argument("image")
    f.add_argument("--title", required=True)
    f.add_argument("--theme", choices=sorted(THEMES), default="stars")
    for opt in ("sub", "mood", "banner", "tag", "burst", "source", "hits", "out"):
        f.add_argument(f"--{opt}", help="burst lines are split on |" if opt == "burst" else None)
    a = ap.parse_args()
    if a.cmd == "frame":
        spec = {k: v for k, v in vars(a).items() if v is not None and k not in ("cmd", "theme", "out")}
        if "burst" in spec:
            spec["burst"] = spec["burst"].split("|")
        print(render(a.out or os.path.splitext(a.image)[0] + "-retro.png", frame(spec, a.theme)))
    else:
        build, default_theme = BUILDERS[a.cmd]
        with open(a.spec) as fh:
            spec = json.load(fh)
        print(render(a.out or os.path.splitext(a.spec)[0] + ".png", build(spec, a.theme or default_theme)))
