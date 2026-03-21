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

[Setting category="Debug" name="Show live game state window"]
bool debugShowStateWindow = false;

[Setting category="Debug" name="Notify ComputeFromHistory duration (ms)"]
bool debugNotifyComputeFromHistory = false;

// Event hook toggles
[Setting category="Debug" name="Log: map events (load/change/playground)"]
bool debugLogEventMap = false;

[Setting category="Debug" name="Log: race events (attempt start/end, give up)"]
bool debugLogEventRace = false;

[Setting category="Debug" name="Log: checkpoint & lap events"]
bool debugLogEventCP = false;

[Setting category="Debug" name="Log: player events (respawn, stale state)"]
bool debugLogEventPlayer = false;

// Other log toggles
[Setting category="Debug" name="Log: update loop"]
bool debugPrintUpdate = false;

[Setting category="Debug" name="Log: UI state changes"]
bool debugPrintUIState = false;

[Setting category="Debug" name="Log: warnings & errors"]
bool debugPrintWarnings = false;

// Consecutive print limit
[Setting category="Debug" name="Max consecutive identical prints (0 = unlimited)" min=0 max=100]
int debugMaxConsecutivePrints = 5;

// --- Log core ---
// Tracks how many consecutive frames each string has been attempted.
// BeginLogFrame() must be called once per Update() tick to flush frame state.
// Uses parallel arrays since dictionary is not available in this build.

array<string> g_logStrings;       // tracked message strings
array<int>    g_logCounts;        // consecutive frame count per string (parallel to g_logStrings)
array<string> g_logSeenThisFrame; // strings seen in the current frame

void BeginLogFrame() {
  // Drop entries for strings not seen last frame (streak broken); iterate backwards for safe removal.
  for (int i = int(g_logStrings.Length) - 1; i >= 0; i--) {
    if (g_logSeenThisFrame.Find(g_logStrings[i]) < 0) {
      g_logStrings.RemoveAt(i);
      g_logCounts.RemoveAt(i);
    }
  }
  g_logSeenThisFrame.Resize(0);
}

// Returns true if msg should be printed this frame, false if suppressed.
// Always records msg as seen this frame for streak tracking.
bool LogAllowed(const string&in msg) {
  if (g_logSeenThisFrame.Find(msg) < 0) {
    g_logSeenThisFrame.InsertLast(msg);
  }
  if (debugMaxConsecutivePrints == 0) return true;
  int idx = g_logStrings.Find(msg);
  if (idx < 0) {
    g_logStrings.InsertLast(msg);
    g_logCounts.InsertLast(1);
    return true;
  }
  if (g_logCounts[idx] >= debugMaxConsecutivePrints) return false;
  g_logCounts[idx]++;
  return true;
}

// --- Log helpers ---

void LogEventMap(const string&in msg) {
  if (!debugLogEventMap) return;
  if (LogAllowed(msg)) print(msg);
}

void LogEventRace(const string&in msg) {
  if (!debugLogEventRace) return;
  if (LogAllowed(msg)) print(msg);
}

void LogEventCP(const string&in msg) {
  if (!debugLogEventCP) return;
  if (LogAllowed(msg)) print(msg);
}

void LogEventPlayer(const string&in msg) {
  if (!debugLogEventPlayer) return;
  if (LogAllowed(msg)) print(msg);
}

void LogUpdate(const string&in msg) {
  if (!debugPrintUpdate) return;
  if (LogAllowed(msg)) print(msg);
}

void LogUIState(const string&in msg) {
  if (!debugPrintUIState) return;
  if (LogAllowed(msg)) print(msg);
}

void LogWarn(const string&in msg) {
  if (!debugPrintWarnings) return;
  if (LogAllowed(msg)) print(msg);
}

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
