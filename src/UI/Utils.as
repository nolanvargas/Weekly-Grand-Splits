// Draws a linear or radial gradient background behind a UI window.
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

// Returns green or red based on lap delta sign and PB availability.
vec4 GetLapDeltaColor(int delta, bool hasBest) {
  if (!hasBest || delta == 0) return COLOR_WHITE;
  return delta < 0 ? COLOR_GREEN : COLOR_RED;
}

// Returns a color for a live in-progress lap delta against best.
vec4 GetLiveDeltaColor(int liveDelta) {
  if (liveDelta < 0) return COLOR_GREEN;
  if (liveDelta > 0) return COLOR_RED;
  // for in-progress deltas, color negative (faster) times green, positive (slower) red, and zero gray.
  return COLOR_GRAY;
}

// Renders one CP cell showing absolute time or a delta value.
void RenderCpCell(CpCellData@ cell) {
  if (!g_uiState.cpDeltaMode || cell.refTime == 0) { UI::Text(FormatCpTime(cell.cpTime)); return; }
  int delta = cell.cpTime - cell.refTime;
  vec4 color = delta < 0 ? COLOR_GREEN : (delta > 0 ? COLOR_RED : COLOR_WHITE);
  UI::PushStyleColor(UI::Col::Text, color);
  UI::Text(FormatDelta(delta));
  UI::PopStyleColor();
}

// Enforces a minimum column width by inserting a zero-height dummy item.
void SetMinWidth(int width) {
  UI::PushStyleVar(UI::StyleVar::ItemSpacing, vec2(0, 0));
  UI::Dummy(vec2(width, 0));
  UI::PopStyleVar();
}


// --- JSON helpers (used only by RaceHistory disk format) ---

// Converts a 2D array of lap CP times into nested JSON arrays.
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

// Returns the storage file path for the given map's history JSON.
string MapRaceHistoryJsonPath(const string&in mapId) {
  IO::CreateFolder(IO::FromStorageFolder("maps"));
  return IO::FromStorageFolder("maps/" + mapId + ".json");
}
