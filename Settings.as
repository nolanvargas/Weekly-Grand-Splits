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

void Heading(const string &in label, vec4 color = vec4(1.0f, 1.0f, 1.0f, 1.0f)) {
    UI::PushStyleColor(UI::Col::Text, color);
    UI::SeparatorText(label);
    UI::PopStyleColor();
}

// Section heading colors for settings tabs
const vec4 HEADING_TEXT       = vec4(0.55f, 0.85f, 1.00f, 1.0f); // sky blue   — text styling
const vec4 HEADING_BACKGROUND = vec4(1.00f, 0.75f, 0.30f, 1.0f); // amber      — background fill
const vec4 HEADING_GRADIENT   = vec4(0.80f, 0.50f, 1.00f, 1.0f); // violet     — gradient

// --- Lap Window ---

[Setting category="Lap Window" name="Visible"]
bool windowVisible = true;

void S_RenderLapPrecisionTab() {
    lapDecimals = UI::SliderInt("Decimal places (0-3)", lapDecimals, 0, 3);
    if (lapDecimals >= 3) lapRoundUp = false;
    UI::BeginDisabled(lapDecimals >= 3);
    lapRoundUp = UI::Checkbox("Round-up precision (0.5 \u2192 1)", lapRoundUp);
    UI::EndDisabled();
}

[Setting category="Lap Window" name="Transposed (laps as columns)"]
bool lapTableTransposed = false;

[Setting category="Lap Window" name="Hide along with Trackmania UI"]
bool lapHideWithIFace = false;

[Setting category="Lap Window" name="Show previous attempt until first checkpoint"]
bool lapKeepPreviousAttempt = true;

[Setting category="Lap Window" name="Lock window position"]
bool lapLockPosition = false;

[Setting category="Lap Window" name="Show map name"]
bool lapShowMapName = false;

[Setting category="Lap Window" name="Show map author"]
bool lapShowMapAuthor = false;

[Setting hidden]
int lapDecimals = 1;

[Setting hidden]
bool lapRoundUp = false;

[Setting category="Lap Window" name="Font size" min=8 max=48]
int lapFontSize = 22;

[Setting category="Lap Window" name="Font style"]
FontStyle lapFontStyle = FontStyle::Default;

[Setting hidden]
vec4 lapWindowBgColor = vec4(0.06f, 0.06f, 0.06f, 0.70f);

[Setting hidden]
vec4 lapTextColor = vec4(1.0f, 1.0f, 1.0f, 1.0f);

[Setting hidden]
bool lapGradientEnabled = false;

[Setting hidden]
bool lapGradientRadial = false;

[Setting hidden]
vec4 lapGradientColor1 = vec4(0.06f, 0.06f, 0.06f, 0.85f);

[Setting hidden]
vec4 lapGradientColor2 = vec4(0.15f, 0.15f, 0.25f, 0.55f);

[Setting category="Lap Window" name="Lap column width" min=8 max=120]
int styleColWidthLap = 32;

[Setting category="Lap Window" name="+/- column width" min=8 max=200]
int styleColWidthDelta = 72;

[Setting category="Lap Window" name="Time column width" min=8 max=200]
int styleColWidthTime = 72;

// --- CP Window ---

[Setting category="CP Window" name="Visible"]
bool cpTableVisible = true;

void S_RenderCpPrecisionTab() {
    cpDecimals = UI::SliderInt("Decimal places (0-3)", cpDecimals, 0, 3);
    if (cpDecimals >= 3) cpRoundUp = false;
    UI::BeginDisabled(cpDecimals >= 3);
    cpRoundUp = UI::Checkbox("Round-up precision (0.5 \u2192 1)", cpRoundUp);
    UI::EndDisabled();
}



[Setting category="CP Window" name="Time display mode"]
CpDisplayMode cpDisplayMode = CpDisplayMode::Absolute;

[Setting category="CP Window" name="Transposed (CPs as rows)"]
bool cpTableTransposed = false;

[Setting category="CP Window" name="Hide along with Trackmania UI"]
bool cpHideWithIFace = false;

[Setting category="CP Window" name="Show previous attempt until first checkpoint"]
bool cpKeepPreviousAttempt = true;

[Setting category="CP Window" name="Lock window position"]
bool cpLockPosition = false;

[Setting hidden]
int cpDecimals = 2;

[Setting hidden]
bool cpRoundUp = false;

[Setting category="CP Window" name="Font size" min=8 max=48]
int cpFontSize = 16;

[Setting category="CP Window" name="Font style"]
FontStyle cpFontStyle = FontStyle::Default;

[Setting hidden]
vec4 cpWindowBgColor = vec4(0.06f, 0.06f, 0.06f, 0.70f);

[Setting hidden]
vec4 cpTextColor = vec4(1.0f, 1.0f, 1.0f, 1.0f);

[Setting hidden]
bool cpGradientEnabled = false;

[Setting hidden]
bool cpGradientRadial = false;

[Setting hidden]
vec4 cpGradientColor1 = vec4(0.06f, 0.06f, 0.06f, 0.85f);

[Setting hidden]
vec4 cpGradientColor2 = vec4(0.15f, 0.15f, 0.25f, 0.55f);

[Setting category="CP Window" name="Lap column width" min=8 max=80]
int styleColWidthCpLap = 16;

[Setting category="CP Window" name="Split column width (absolute)" min=16 max=200]
int styleColWidthCpAbs = 36;

[Setting category="CP Window" name="Split column width (delta)" min=16 max=200]
int styleColWidthCpDelta = 52;

// --- Debug ---

[Setting category="Debug" name="Show live game state window"]
bool debugShowStateWindow = false;

[Setting category="Debug" name="Log: player events (respawn, stale state)"]
bool debugLogEventPlayer = false;

void LogEventPlayer(const string&in msg) {
  if (!debugLogEventPlayer) return;
  print(msg);
}

[SettingsTab name="Lap Window Colors" icon="PaintBrush"]
void S_RenderLapColorsTab() {
    if (UI::Button("Reset to default##lap")) {
        lapTextColor       = vec4(1.0f, 1.0f, 1.0f, 1.0f);
        lapWindowBgColor   = vec4(0.06f, 0.06f, 0.06f, 0.70f);
        lapGradientEnabled = false;
        lapGradientRadial  = false;
        lapGradientColor1  = vec4(0.06f, 0.06f, 0.06f, 0.85f);
        lapGradientColor2  = vec4(0.15f, 0.15f, 0.25f, 0.55f);
    }

    Heading("Text", HEADING_TEXT);
    lapTextColor = UI::InputColor4("Text color", lapTextColor, UI::ColorEditFlags::AlphaBar | UI::ColorEditFlags::AlphaPreviewHalf);

    Heading("Background", HEADING_BACKGROUND);
    UI::BeginDisabled(lapGradientEnabled);
    lapWindowBgColor = UI::InputColor4("Background color", lapWindowBgColor, UI::ColorEditFlags::AlphaBar | UI::ColorEditFlags::AlphaPreviewHalf);
    UI::EndDisabled();

    Heading("Gradient", HEADING_GRADIENT);
    lapGradientEnabled = UI::Checkbox("Enable gradient background", lapGradientEnabled);
    UI::BeginDisabled(!lapGradientEnabled);
    lapGradientRadial = UI::Checkbox("Radial (off = linear top-to-bottom)", lapGradientRadial);
    lapGradientColor1 = UI::InputColor4("Color 1 (top / inner)", lapGradientColor1, UI::ColorEditFlags::AlphaBar | UI::ColorEditFlags::AlphaPreviewHalf);
    lapGradientColor2 = UI::InputColor4("Color 2 (bottom / outer)", lapGradientColor2, UI::ColorEditFlags::AlphaBar | UI::ColorEditFlags::AlphaPreviewHalf);
    UI::EndDisabled();

}

[SettingsTab name="CP Window Colors" icon="PaintBrush"]
void S_RenderCpColorsTab() {
    if (UI::Button("Reset to default##cp")) {
        cpTextColor       = vec4(1.0f, 1.0f, 1.0f, 1.0f);
        cpWindowBgColor   = vec4(0.06f, 0.06f, 0.06f, 0.70f);
        cpGradientEnabled = false;
        cpGradientRadial  = false;
        cpGradientColor1  = vec4(0.06f, 0.06f, 0.06f, 0.85f);
        cpGradientColor2  = vec4(0.15f, 0.15f, 0.25f, 0.55f);
    }

    Heading("Text", HEADING_TEXT);
    cpTextColor = UI::InputColor4("Text color", cpTextColor, UI::ColorEditFlags::AlphaBar | UI::ColorEditFlags::AlphaPreviewHalf);

    Heading("Background", HEADING_BACKGROUND);
    UI::BeginDisabled(cpGradientEnabled);
    cpWindowBgColor = UI::InputColor4("Background color", cpWindowBgColor, UI::ColorEditFlags::AlphaBar | UI::ColorEditFlags::AlphaPreviewHalf);
    UI::EndDisabled();

    Heading("Gradient", HEADING_GRADIENT);
    cpGradientEnabled = UI::Checkbox("Enable gradient background", cpGradientEnabled);
    UI::BeginDisabled(!cpGradientEnabled);
    cpGradientRadial = UI::Checkbox("Radial (off = linear top-to-bottom)", cpGradientRadial);
    cpGradientColor1 = UI::InputColor4("Color 1 (top / inner)", cpGradientColor1, UI::ColorEditFlags::AlphaBar | UI::ColorEditFlags::AlphaPreviewHalf);
    cpGradientColor2 = UI::InputColor4("Color 2 (bottom / outer)", cpGradientColor2, UI::ColorEditFlags::AlphaBar | UI::ColorEditFlags::AlphaPreviewHalf);
    UI::EndDisabled();

}
