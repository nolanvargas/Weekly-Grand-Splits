// Renders the checkpoint split table in vertical form: one row per lap.
// Each cell shows either absolute CP time or a delta against a chosen reference.
void RenderCpTableNormal() {
  int numCols  = g_uiState.numCpCols;
  int colWidth = g_uiState.cpDeltaMode ? styleColWidthCpDelta : styleColWidthCpAbs;
  if (UI::BeginTable("cptable", numCols + 1, UI::TableFlags::SizingFixedFit)) {
    // header row
    UI::TableNextColumn(); SetMinWidth(styleColWidthCpLap); UI::Text("Lap");
    for (int cpIdx = 1; cpIdx <= numCols; cpIdx++) { // CPs start at 1
      UI::TableNextColumn(); SetMinWidth(colWidth);
      UI::Text(cpIdx == numCols ? "Fin" : "CP" + cpIdx);
    }

    for (int lapIdx = 1; lapIdx <= g_uiState.numLaps; lapIdx++) { // Laps start at 1
      UI::TableNextRow();
      UI::TableNextColumn(); UI::Text("" + lapIdx);
      for (int cpIdx = 1; cpIdx <= numCols; cpIdx++) { // CPs start at 1
        UI::TableNextColumn();
        if (lapIdx >= int(g_uiState.cpData.Length) || cpIdx >= int(g_uiState.cpData[lapIdx].Length)) {
          UI::Text("-"); continue;
        }
        CpCellData@ cell = g_uiState.cpData[lapIdx][cpIdx];
        if (cell is null || !cell.hasData) { UI::Text("-"); continue; }
        RenderCpCell(cell);
      }
    }

    UI::EndTable();
  }
}

// Renders the checkpoint split table transposed: one row per CP index.
// This makes it easier to compare the same CP across laps.
void RenderCpTableTransposed() {
  int numCols  = g_uiState.numCpCols;
  int colWidth = g_uiState.cpDeltaMode ? styleColWidthCpDelta : styleColWidthCpAbs;
  // cols: CP label | Lap1..numLaps
  if (UI::BeginTable("cptable_t", 1 + g_uiState.numLaps, UI::TableFlags::SizingFixedFit)) {
    // header row: blank | 1 | 2 | ... | numLaps
    UI::TableNextColumn(); SetMinWidth(styleColWidthCpAbs); UI::Text("Lap");
    for (int lapIdx = 1; lapIdx <= g_uiState.numLaps; lapIdx++) { // Laps start at 1
      UI::TableNextColumn(); SetMinWidth(colWidth); UI::Text("" + lapIdx);
    }

    // one row per CP
    for (int cpIdx = 1; cpIdx <= numCols; cpIdx++) { // CPs start at 1
      UI::TableNextRow();
      UI::TableNextColumn(); UI::Text(cpIdx == numCols ? "Fin" : "CP" + cpIdx);
      for (int lapIdx = 1; lapIdx <= g_uiState.numLaps; lapIdx++) { // Laps start at 1
        UI::TableNextColumn();
        if (lapIdx >= int(g_uiState.cpData.Length) || cpIdx >= int(g_uiState.cpData[lapIdx].Length)) {
          UI::Text("-"); continue;
        }
        CpCellData@ cell = g_uiState.cpData[lapIdx][cpIdx];
        if (cell is null || !cell.hasData) { UI::Text("-"); continue; }
        RenderCpCell(cell);
      }
    }

    UI::EndTable();
  }
}

// Top-level CP table window renderer.
// Handles visibility guards, window placement, and mode selection.
void RenderCpTable() {
  if (!cpTableVisible) return;

  auto app = cast<CTrackMania>(GetApp());
  auto map = app.RootMap;

  if (!g_state.isMultiLap) return;
  if (cpHideWithIFace) {
    auto playground = app.CurrentPlayground;
    if (playground is null || playground.Interface is null ||
        !UI::IsGameUIVisible()) {
      return;
    }
  }

  if (map is null || map.MapInfo.MapUid == "") return;

  if (cpLockPosition) {
    UI::SetNextWindowPos(int(anchorCp.x), int(anchorCp.y), UI::Cond::Always);
  } else {
    UI::SetNextWindowPos(int(anchorCp.x), int(anchorCp.y), UI::Cond::FirstUseEver);
  }

  int windowFlags =
      UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoCollapse |
      UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking;
  if (!UI::IsOverlayShown()) {
    windowFlags |= UI::WindowFlags::NoInputs;
  }

  bool isStale = g_uiState.cpIsStale;
  g_fmtDecimals = cpDecimals;
  g_fmtRoundUp  = cpRoundUp;
  UI::PushFont(cpFontStyle == FontStyle::Bold ? UI::Font::DefaultBold : cpFontStyle == FontStyle::Mono ? UI::Font::DefaultMono : UI::Font::Default);
  UI::PushFontSize(cpFontSize);
  if (cpGradientEnabled && g_cpWinSize.x > 0) DrawGradientBg(anchorCp, g_cpWinSize, cpGradientRadial, cpGradientColor1, cpGradientColor2);
  UI::PushStyleColor(UI::Col::WindowBg, cpGradientEnabled ? vec4(0, 0, 0, 0) : cpWindowBgColor);
  UI::PushStyleColor(UI::Col::Text, isStale ? vec4(cpTextColor.x, cpTextColor.y, cpTextColor.z, cpTextColor.w * 0.45f) : cpTextColor);
  UI::Begin("CpTimes", windowFlags);

  if (!cpLockPosition) {
    anchorCp = UI::GetWindowPos();
  }
  g_cpWinSize = UI::GetWindowSize();

  if (cpTableTransposed) RenderCpTableTransposed();
  else                   RenderCpTableNormal();

  UI::End();
  UI::PopStyleColor(2);
  UI::PopFontSize();
  UI::PopFont();
}
