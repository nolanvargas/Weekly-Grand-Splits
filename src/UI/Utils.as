// Draws a simple linear or radial gradient behind a UI window.
void DrawGradientBg(vec2 pos, vec2 size, bool radial, vec4 color1, vec4 color2) {
  nvg::BeginPath();
  nvg::Rect(pos.x, pos.y, size.x, size.y);
  nvg::Paint paint;
  if (radial) {
    // build a radial gradient centered on the window, using color1 at the center and color2 at the radius.
    float gradientRadius = Math::Sqrt(size.x * size.x / 4.0f + size.y * size.y / 4.0f);
    paint = nvg::RadialGradient(
      vec2(pos.x + size.x * 0.5f, pos.y + size.y * 0.5f),
      0.0f, gradientRadius,
      color1, color2
    );
  } else {
    // build a top-to-bottom linear gradient from color1 to color2 spanning the window height.
    paint = nvg::LinearGradient(
      vec2(pos.x, pos.y), vec2(pos.x, pos.y + size.y),
      color1, color2
    );
  }
  nvg::FillPaint(paint);
  nvg::Fill();
}

// Chooses a text color for lap deltas based on sign and whether a PB exists.
// Negative (faster) deltas are green, positive (slower) are red.
vec4 GetLapDeltaColor(int delta, bool hasBest) {
  if (!hasBest || delta == 0) return COLOR_WHITE;
  return delta < 0 ? COLOR_GREEN : COLOR_RED;
}

// Chooses a text color for live deltas while a lap is in progress.
// Mirrors the semantics of GetLapDeltaColor but for in-progress laps.
vec4 GetLiveDeltaColor(int liveDelta) {
  if (liveDelta < 0) return COLOR_GREEN;
  if (liveDelta > 0) return COLOR_RED;
  // for in-progress deltas, color negative (faster) times green, positive (slower) red, and zero gray.
  return COLOR_GRAY;
}

// Renders a single CP cell either as an absolute time or as a delta to refTime.
// Colors negative deltas green and positive deltas red.
void RenderCpCell(int cpTime, int refTime, bool deltaMode) {
  if (!deltaMode || refTime == 0) { UI::Text(FormatCpTime(cpTime)); return; }
  // when not in delta mode or without a valid reference, show the raw CP time only.
  int delta = cpTime - refTime;
  vec4 color = delta < 0 ? COLOR_GREEN : (delta > 0 ? COLOR_RED : COLOR_WHITE);
  UI::PushStyleColor(UI::Col::Text, color);
  UI::Text(FormatDelta(delta));
  UI::PopStyleColor();
}

// Resolves the reference time used for CP deltas based on the current mode.
// Modes:
// - DeltaPB: per-lap PB splits.
// - DeltaBestLapCp: best per-lap CP ever.
// - DeltaBestAllTime: best CP regardless of lap.
int GetCpRefTime(int lapIdx, int cpIdx, array<int>@ bestEverCp) {
  if (cpDisplayMode == CpDisplayMode::DeltaPB) {
    // for DeltaPB, use the per-lap PB split at this [lap, cp] as the reference time when it exists.
    return g_state.bests.GetBestSingleAttemptCpTime(lapIdx, cpIdx);
  } else if (cpDisplayMode == CpDisplayMode::DeltaBestLapCp) {
    // for DeltaBestLapCp, reference the best-ever split for this lap/CP combination from all attempts.
    return g_state.bests.GetBestCpByCpLapIndexTime(lapIdx, cpIdx);
  } else if (cpDisplayMode == CpDisplayMode::DeltaBestAllTime) {
    // for DeltaBestAllTime, compare against the overall best CP split at this CP index, regardless of lap.
    return g_state.bests.GetBestAnyCpTime(cpIdx);
  }
  return 0;
}

// Ensures a minimum width for the next table column.
// This works by inserting a dummy item with the desired width.
void SetMinWidth(int width) {
  UI::PushStyleVar(UI::StyleVar::ItemSpacing, vec2(0, 0));
  UI::Dummy(vec2(width, 0));
  UI::PopStyleVar();
}


// --- JSON helpers (used only by RaceHistory disk format) ---

Json::Value@ BuildLapsJson2D(const array<array<int>>@ data) {
  Json::Value@ outer = Json::Array();
  for (uint rowIndex = 0; rowIndex < data.Length; rowIndex++) {
    Json::Value@ inner = Json::Array();
    for (uint colIndex = 0; colIndex < data[rowIndex].Length; colIndex++) {
      inner.Add(Json::Value(data[rowIndex][colIndex]));
    }
    outer.Add(inner);
  }
  return outer;
}

array<array<int>> ReadLapsJson2D(Json::Value@ outer) {
  array<array<int>> result;
  for (uint rowIndex = 0; rowIndex < outer.Length; rowIndex++) {
    array<int> row;
    Json::Value@ inner = outer[rowIndex];
    for (uint colIndex = 0; colIndex < inner.Length; colIndex++) {
      row.InsertLast(int(inner[colIndex]));
    }
    result.InsertLast(row);
  }
  return result;
}

string MapRaceHistoryJsonPath(const string&in mapId) {
  IO::CreateFolder(IO::FromStorageFolder("maps"));
  return IO::FromStorageFolder("maps/" + mapId + ".json");
}
