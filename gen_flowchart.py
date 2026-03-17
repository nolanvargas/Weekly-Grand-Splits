"""
Flowchart — Weekly Grand Splits: Lap Finish / Lap Start Events
Standard: Chapter 01, SoftwareDesign.pdf
Black & white, top-to-bottom dominant flow.
"""

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyBboxPatch
import numpy as np

# ── canvas ────────────────────────────────────────────────────────────────────
FW, FH = 11, 20
fig, ax = plt.subplots(figsize=(FW, FH))
ax.set_xlim(0, FW)
ax.set_ylim(0, FH)
ax.set_facecolor("white")
fig.patch.set_facecolor("white")
ax.axis("off")

# ── dimensions ────────────────────────────────────────────────────────────────
CX   = FW / 2          # main column centre
BW   = 5.0             # process box width
BH   = 0.60            # process box height
DW   = 3.2             # diamond half-width
DH   = 0.50            # diamond half-height
FS   = 8.5             # main font size
FS_L = 7.5             # label font size
LW   = 1.0             # line width

# ── primitives ────────────────────────────────────────────────────────────────

def rect(x, y, text, width=BW, height=BH, fs=FS, bold=False):
    """Centred rectangle process box."""
    r = FancyBboxPatch((x - width/2, y - height/2), width, height,
                       boxstyle="square,pad=0",
                       facecolor="white", edgecolor="black", linewidth=LW, zorder=3)
    ax.add_patch(r)
    lines = text.split("\n")
    step = height / (len(lines) + 1)
    for i, ln in enumerate(lines):
        ax.text(x, y + height/2 - step*(i+1), ln,
                ha="center", va="center", fontsize=fs,
                fontweight="bold" if bold else "normal",
                fontfamily="sans-serif", color="black", zorder=4)

def diamond(x, y, text, w=DW, h=DH, fs=FS):
    """Decision diamond centred at (x, y)."""
    pts = np.array([[x, y+h], [x+w, y], [x, y-h], [x-w, y]])
    d = plt.Polygon(pts, closed=True,
                    facecolor="white", edgecolor="black", linewidth=LW, zorder=3)
    ax.add_patch(d)
    lines = text.split("\n")
    for i, ln in enumerate(lines):
        off = (i - (len(lines)-1)/2) * 0.20
        ax.text(x, y - off, ln, ha="center", va="center",
                fontsize=fs, fontfamily="sans-serif", color="black", zorder=4)

def start_end(x, y, label, filled=False, r=0.26):
    """Start (filled) or end (double-ring) terminator."""
    if filled:
        c = plt.Circle((x, y), r, facecolor="black", edgecolor="black",
                        linewidth=LW, zorder=3)
        ax.add_patch(c)
        ax.text(x + r + 0.15, y, label, va="center", ha="left",
                fontsize=FS_L, color="black")
    else:
        c_out = plt.Circle((x, y), r, facecolor="white", edgecolor="black",
                            linewidth=LW, zorder=3)
        c_in  = plt.Circle((x, y), r*0.55, facecolor="black", edgecolor="black",
                            linewidth=0.5, zorder=4)
        ax.add_patch(c_out)
        ax.add_patch(c_in)
        ax.text(x + r + 0.15, y, label, va="center", ha="left",
                fontsize=FS_L, color="black")

def arr(x1, y1, x2, y2, lbl="", lbl_dx=0.12, lbl_dy=0.10):
    """Straight arrow."""
    ax.annotate("", xy=(x2, y2), xytext=(x1, y1),
                arrowprops=dict(arrowstyle="-|>", color="black",
                                lw=LW, mutation_scale=10), zorder=2)
    if lbl:
        mx, my = (x1+x2)/2, (y1+y2)/2
        ax.text(mx + lbl_dx, my + lbl_dy, lbl,
                ha="left", va="bottom", fontsize=FS_L, color="black")

def elbow(x1, y1, xb, y2, lbl="", lbl_dx=0.08, lbl_dy=0.08):
    """L-bend: horizontal then vertical arrow."""
    ax.plot([x1, xb], [y1, y1], color="black", lw=LW, zorder=2)
    ax.annotate("", xy=(xb, y2), xytext=(xb, y1),
                arrowprops=dict(arrowstyle="-|>", color="black",
                                lw=LW, mutation_scale=10), zorder=2)
    if lbl:
        ax.text(x1 + lbl_dx, y1 + lbl_dy, lbl,
                ha="left", va="bottom", fontsize=FS_L, color="black")

def corner(x1, y1, x2, y2, lbl="", lbl_side="right"):
    """Corner connector: vertical then horizontal to target."""
    ax.plot([x1, x1], [y1, y2], color="black", lw=LW, zorder=2)
    ax.annotate("", xy=(x2, y2), xytext=(x1, y2),
                arrowprops=dict(arrowstyle="-|>", color="black",
                                lw=LW, mutation_scale=10), zorder=2)
    if lbl:
        dx = 0.10 if lbl_side == "right" else -0.10
        ha = "left" if lbl_side == "right" else "right"
        ax.text(x1 + dx, (y1+y2)/2, lbl, ha=ha, va="center",
                fontsize=FS_L, color="black")

# ── Y positions (top → bottom) ────────────────────────────────────────────────
Y = dict(
    start       = 18.3,
    get_times   = 17.1,
    d_valid     = 15.9,
    rec_cp      = 14.7,
    d_lap_fin   = 13.4,
    lap_data    = 12.4,   # left branch box
    d_finish    = 11.5,
    inc_lap     = 10.4,
    d_alldone   =  9.2,
    race_done   =  8.1,
    d_ismulti   =  6.9,
    upd_pb      =  6.0,   # left branch box
    save        =  4.9,
    end         =  3.7,
)

# right-side END columns
RX  = CX + 3.8   # right end-symbol x
LX  = CX - 3.8   # left branch x

# ── DRAW NODES ────────────────────────────────────────────────────────────────

start_end(CX, Y["start"], "Start", filled=True)

rect(CX, Y["get_times"],
     "Get checkpoint time\nCalculate lap delta time",
     height=0.75)

diamond(CX, Y["d_valid"], "Times valid?")

rect(CX, Y["rec_cp"],
     "Record CP split and update CP best")

diamond(CX, Y["d_lap_fin"],
        "Multi-lap\nlap finish?")

rect(LX, Y["lap_data"],
     "Record lap time\nSave CP splits, reset lap",
     width=3.8, height=0.75)

diamond(CX, Y["d_finish"], "Finish waypoint?")

rect(CX, Y["inc_lap"], "Increment lap counter")

diamond(CX, Y["d_alldone"], "All laps\ncomplete?")

rect(CX, Y["race_done"],
     "Mark race as finished")

diamond(CX, Y["d_ismulti"], "Multi-lap\nrace?")

rect(LX, Y["upd_pb"],
     "Check and update PB",
     width=3.8)

rect(CX, Y["save"], "Save data")

start_end(CX, Y["end"], "End", filled=False)

# ── RIGHT-SIDE END NODES (early returns) ─────────────────────────────────────
# Invalid times
start_end(RX, Y["d_valid"], "End", filled=False)

# Not all laps done
start_end(RX, Y["d_alldone"], "End", filled=False)

# ── ARROWS: main vertical spine ───────────────────────────────────────────────
arr(CX, Y["start"]     - 0.26, CX, Y["get_times"]  + 0.38)
arr(CX, Y["get_times"] - 0.38, CX, Y["d_valid"]    + DH)
arr(CX, Y["d_valid"]   - DH,   CX, Y["rec_cp"]     + BH/2,  lbl="Yes", lbl_dx=0.10, lbl_dy=0.06)
arr(CX, Y["rec_cp"]    - BH/2, CX, Y["d_lap_fin"]  + DH)
arr(CX, Y["d_lap_fin"] - DH,   CX, Y["d_finish"]   + DH,    lbl="No",  lbl_dx=0.10, lbl_dy=0.06)
arr(CX, Y["d_finish"]  - DH,   CX, Y["inc_lap"]    + BH/2,  lbl="Yes", lbl_dx=0.10, lbl_dy=0.06)
arr(CX, Y["inc_lap"]   - BH/2, CX, Y["d_alldone"]  + DH)
arr(CX, Y["d_alldone"] - DH,   CX, Y["race_done"]  + BH/2,  lbl="Yes", lbl_dx=0.10, lbl_dy=0.06)
arr(CX, Y["race_done"] - BH/2, CX, Y["d_ismulti"]  + DH)
arr(CX, Y["d_ismulti"] - DH,   CX, Y["save"]       + BH/2,  lbl="No",  lbl_dx=0.10, lbl_dy=0.06)
arr(CX, Y["save"]      - BH/2, CX, Y["end"]        + 0.26)

# ── ARROWS: right branches (invalid / not done) ───────────────────────────────
# Invalid times → right END
elbow(CX + DW, Y["d_valid"], RX, Y["d_valid"], lbl="No", lbl_dx=0.10, lbl_dy=0.06)

# Not all laps done → right END
elbow(CX + DW, Y["d_alldone"], RX, Y["d_alldone"], lbl="No", lbl_dx=0.10, lbl_dy=0.06)

# Not finish waypoint → down to save
# "No" exits left of d_finish diamond
ax.plot([CX - DW, CX - DW - 0.6], [Y["d_finish"], Y["d_finish"]], color="black", lw=LW)
ax.plot([CX - DW - 0.6, CX - DW - 0.6], [Y["d_finish"], Y["save"]], color="black", lw=LW)
ax.annotate("", xy=(CX - BW/2, Y["save"]),
            xytext=(CX - DW - 0.6, Y["save"]),
            arrowprops=dict(arrowstyle="-|>", color="black", lw=LW, mutation_scale=10), zorder=2)
ax.text(CX - DW - 0.55, Y["d_finish"] + 0.10, "No",
        ha="right", va="bottom", fontsize=FS_L, color="black")

# ── ARROWS: left branches ─────────────────────────────────────────────────────
# Lap finish → Yes → left box
elbow(CX - DW, Y["d_lap_fin"], LX, Y["lap_data"] + 0.38, lbl="Yes", lbl_dx=-1.0, lbl_dy=0.06)
# lap data box → down to rejoin at d_finish level
corner(LX, Y["lap_data"] - 0.38, CX - BW/2, Y["d_finish"] + DH)

# Multi-lap → Yes → left PB box
elbow(CX - DW, Y["d_ismulti"], LX, Y["upd_pb"] + BH/2, lbl="Yes", lbl_dx=-0.9, lbl_dy=0.06)
# PB box → merge to save
corner(LX, Y["upd_pb"] - BH/2, CX - BW/2, Y["save"])

# ── title ─────────────────────────────────────────────────────────────────────
ax.text(CX, FH - 0.25,
        "Weekly Grand Splits — Lap Finish / Lap Start Event Flow",
        ha="center", va="top", fontsize=9.5, fontweight="bold",
        color="black", fontfamily="sans-serif")
ax.text(CX, FH - 0.65,
        "Plugin.as · Storage.as",
        ha="center", va="top", fontsize=7.5,
        color="#555555", fontfamily="sans-serif")

plt.tight_layout(pad=0.3)

out = r"C:\Users\nolan\OpenplanetNext\Plugins\Weekly Grand Splits\lap_events_flowchart"
fig.savefig(out + ".png", dpi=180, bbox_inches="tight", facecolor="white")
fig.savefig(out + ".pdf", bbox_inches="tight", facecolor="white")
print(f"Saved:\n  {out}.png\n  {out}.pdf")
