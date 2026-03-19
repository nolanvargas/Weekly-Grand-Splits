//visual studio code formatting messes with the [Setting ..] text causing open planet to crash
//moved to different file to get around that issue
#if __INTELLISENSE__
#include "cppIntellisense.h"
#endif

enum FontStyle {
  Default,
  Bold,
  Mono
}

enum CpDisplayMode {
  Absolute,
  DeltaPB,
  DeltaBestLapCp,
  DeltaBestAllTime
}

// --- Lap Window ---

[Setting category="Lap Window" name="Visible"]
bool windowVisible = true;

[Setting category="Lap Window" name="Transposed (laps as columns)"]
bool lapTableTransposed = false;

[Setting category="Lap Window" name="Hide along with Trackmania UI"]
bool lapHideWithIFace = false;

[Setting category="Lap Window" name="Lock window position"]
bool lapLockPosition = false;

[Setting category="Lap Window" name="Use thousandths precision"]
bool lapUseThousandths = false;

[Setting category="Lap Window" name="Font size" min=8 max=48]
int lapFontSize = 16;

[Setting category="Lap Window" name="Font style"]
FontStyle lapFontStyle = FontStyle::Default;

[Setting category="Lap Window" name="Background color" color]
vec4 lapWindowBgColor = vec4(0.06f, 0.06f, 0.06f, 0.70f);

[Setting category="Lap Window" name="Text color" color]
vec4 lapTextColor = vec4(1.0f, 1.0f, 1.0f, 1.0f);

[Setting category="Lap Window" name="Gradient background"]
bool lapGradientEnabled = false;

[Setting category="Lap Window" name="Gradient type: radial (off = linear top-to-bottom)"]
bool lapGradientRadial = false;

[Setting category="Lap Window" name="Gradient color 1 (top / inner)" color]
vec4 lapGradientColor1 = vec4(0.06f, 0.06f, 0.06f, 0.85f);

[Setting category="Lap Window" name="Gradient color 2 (bottom / outer)" color]
vec4 lapGradientColor2 = vec4(0.15f, 0.15f, 0.25f, 0.55f);

// --- CP Window ---

[Setting category="CP Window" name="Visible"]
bool cpTableVisible = true;

[Setting category="CP Window" name="Time display mode"]
CpDisplayMode cpDisplayMode = CpDisplayMode::Absolute;

[Setting category="CP Window" name="Transposed (CPs as rows)"]
bool cpTableTransposed = false;

[Setting category="CP Window" name="Hide along with Trackmania UI"]
bool cpHideWithIFace = false;

[Setting category="CP Window" name="Lock window position"]
bool cpLockPosition = false;

[Setting category="CP Window" name="Use thousandths precision"]
bool cpUseThousandths = false;

[Setting category="CP Window" name="Font size" min=8 max=48]
int cpFontSize = 16;

[Setting category="CP Window" name="Font style"]
FontStyle cpFontStyle = FontStyle::Default;

[Setting category="CP Window" name="Background color" color]
vec4 cpWindowBgColor = vec4(0.06f, 0.06f, 0.06f, 0.70f);

[Setting category="CP Window" name="Text color" color]
vec4 cpTextColor = vec4(1.0f, 1.0f, 1.0f, 1.0f);

[Setting category="CP Window" name="Gradient background"]
bool cpGradientEnabled = false;

[Setting category="CP Window" name="Radial"]
bool cpGradientRadial = false;

[Setting category="CP Window" name="Gradient color 1 (top / inner)" color]
vec4 cpGradientColor1 = vec4(0.06f, 0.06f, 0.06f, 0.85f);

[Setting category="CP Window" name="Gradient color 2 (bottom / outer)" color]
vec4 cpGradientColor2 = vec4(0.15f, 0.15f, 0.25f, 0.55f);

// --- Advanced style (table column min-widths, pixels) ---

[Setting category="Advanced style" name="Lap table: Lap column" min=8 max=120]
int styleColWidthLap = 32;

[Setting category="Advanced style" name="Lap table: +/- column" min=8 max=200]
int styleColWidthDelta = 72;

[Setting category="Advanced style" name="Lap table: Time column" min=8 max=200]
int styleColWidthTime = 72;

[Setting category="Advanced style" name="CP table: Lap column" min=8 max=80]
int styleColWidthCpLap = 16;

[Setting category="Advanced style" name="CP table: split column (absolute)" min=16 max=200]
int styleColWidthCpAbs = 36;

[Setting category="Advanced style" name="CP table: split column (delta)" min=16 max=200]
int styleColWidthCpDelta = 52;
