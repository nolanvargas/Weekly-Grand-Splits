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

void Heading(const string &in label) {
    UI::SeparatorText(label);
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

[Setting category="Debug" name="Print race events to log"]
bool debugPrintEvents = false;

[Setting category="Debug" name="Dry-run player events (hooks print only; no persistence or metrics)"]
bool debugPlayerEventsDryRun = false;

string g_lastPrintOnce = "";
void PrintOnce(const string&in msg) {
  if (!debugPrintEvents || msg == g_lastPrintOnce) return;
  g_lastPrintOnce = msg;
  print(msg);
}

// Player event hooks: when dry-run is on, always print (no dedupe) and skip side effects in GameState.
void HookEventPrint(const string&in msg) {
  if (debugPlayerEventsDryRun) {
    print(msg);
    return;
  }
  PrintOnce(msg);
}

[Setting category="Debug" name="Show live game state window"]
bool debugShowStateWindow = false;

[Setting category="Debug" name="Notify ComputeFromHistory duration (ms)"]
bool debugNotifyComputeFromHistory = false;

[SettingsTab name="Lap Window Colors" icon="Palette"]
void S_RenderLapColorsTab() {
    Heading("Background");
    lapWindowBgColor = UI::InputColor4("Background color", lapWindowBgColor, UI::ColorEditFlags::AlphaBar | UI::ColorEditFlags::AlphaPreviewHalf);

    Heading("Text");
    lapTextColor = UI::InputColor4("Text color", lapTextColor, UI::ColorEditFlags::AlphaBar | UI::ColorEditFlags::AlphaPreviewHalf);

    Heading("Gradient");
    lapGradientEnabled = UI::Checkbox("Enable gradient background", lapGradientEnabled);
    UI::BeginDisabled(!lapGradientEnabled);
    lapGradientRadial = UI::Checkbox("Radial (off = linear top-to-bottom)", lapGradientRadial);
    lapGradientColor1 = UI::InputColor4("Color 1 (top / inner)", lapGradientColor1, UI::ColorEditFlags::AlphaBar | UI::ColorEditFlags::AlphaPreviewHalf);
    lapGradientColor2 = UI::InputColor4("Color 2 (bottom / outer)", lapGradientColor2, UI::ColorEditFlags::AlphaBar | UI::ColorEditFlags::AlphaPreviewHalf);
    UI::EndDisabled();
}

[SettingsTab name="CP Window Colors" icon="Palette"]
void S_RenderCpColorsTab() {
    Heading("Background");
    cpWindowBgColor = UI::InputColor4("Background color", cpWindowBgColor, UI::ColorEditFlags::AlphaBar | UI::ColorEditFlags::AlphaPreviewHalf);

    Heading("Text");
    cpTextColor = UI::InputColor4("Text color", cpTextColor, UI::ColorEditFlags::AlphaBar | UI::ColorEditFlags::AlphaPreviewHalf);

    Heading("Gradient");
    cpGradientEnabled = UI::Checkbox("Enable gradient background", cpGradientEnabled);
    UI::BeginDisabled(!cpGradientEnabled);
    cpGradientRadial = UI::Checkbox("Radial (off = linear top-to-bottom)", cpGradientRadial);
    cpGradientColor1 = UI::InputColor4("Color 1 (top / inner)", cpGradientColor1, UI::ColorEditFlags::AlphaBar | UI::ColorEditFlags::AlphaPreviewHalf);
    cpGradientColor2 = UI::InputColor4("Color 2 (bottom / outer)", cpGradientColor2, UI::ColorEditFlags::AlphaBar | UI::ColorEditFlags::AlphaPreviewHalf);
    UI::EndDisabled();
}
