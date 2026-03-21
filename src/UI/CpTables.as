// Renders the checkpoint split table in vertical form: one row per lap.
// Each cell shows either absolute CP time or a delta against a chosen reference.
void RenderCpTableNormal(bool isRacing, int numCols, bool deltaMode, int colWidth, array<int>@ bestEverCp) {
  if (UI::BeginTable("cptable", numCols + 1, UI::TableFlags::SizingFixedFit)) {
    // header row
    UI::TableNextColumn(); SetMinWidth(styleColWidthCpLap); UI::Text("Lap");
    for (int cpIdx = 0; cpIdx < numCols; cpIdx++) {
      UI::TableNextColumn(); SetMinWidth(colWidth);
      UI::Text(cpIdx == numCols - 1 ? "Fin" : "CP" + (cpIdx + 1));
    }

    Attempt@ disp = g_uiState.displayAttempt;
    // 10 lap rows
    for (int lapIdx = 0; lapIdx < MAX_LAPS; lapIdx++) {
      UI::TableNextRow();
      Lap@ lap = null;
      if (disp !is null && lapIdx < int(disp.laps.Length)) {
        @lap = disp.GetLap(lapIdx);
      }
      // mark rows as completed if we have stored CP splits for that lap, or as active if it is the current in-progress lap.
      bool completed = g_state.GetDisplayLapTime(lapIdx) != -1 && disp !is null && lapIdx < int(disp.laps.Length);
      bool active    = isRacing && lapIdx == g_state.currentLap;

      if (completed || active) {
        // for completed or active laps, render each CP cell as either an absolute time or delta vs the chosen reference.
        UI::TableNextColumn(); UI::Text("" + (lapIdx + 1));
        for (int cpIdx = 0; cpIdx < numCols; cpIdx++) {
          UI::TableNextColumn();
          if (lap is null || cpIdx >= int(lap.checkpoints.Length)) { UI::Text("-"); continue; }
          RenderCpCell(lap.GetCheckpointTime(cpIdx), GetCpRefTime(lapIdx, cpIdx, bestEverCp), deltaMode);
        }
      } else {
        UI::TableNextColumn(); UI::Text("" + (lapIdx + 1));
        for (int cpIdx = 0; cpIdx < numCols; cpIdx++) {
          UI::TableNextColumn(); UI::Text("-");
        }
      }
    }

    UI::EndTable();
  }
}

// Renders the checkpoint split table transposed: one row per CP index.
// This makes it easier to compare the same CP across laps.
void RenderCpTableTransposed(bool isRacing, int numCols, bool deltaMode, int colWidth, array<int>@ bestEverCp) {
  // cols: CP label | Lap1..Lap10 = 1 + MAX_LAPS = 11
  if (UI::BeginTable("cptable_t", 1 + MAX_LAPS, UI::TableFlags::SizingFixedFit)) {
    // open a transposed CP table where rows are CPs and columns are laps, to compare the same CP across attempts.
    // header row: "Lap" | 1 | 2 | ... | 10
    UI::TableNextColumn(); SetMinWidth(styleColWidthCpAbs); UI::Text("Lap");
    for (int lapIdx = 0; lapIdx < MAX_LAPS; lapIdx++) {
      UI::TableNextColumn(); SetMinWidth(colWidth); UI::Text("" + (lapIdx + 1));
    }

    Attempt@ disp = g_uiState.displayAttempt;
    // one row per CP
    for (int cpIdx = 0; cpIdx < numCols; cpIdx++) {
      UI::TableNextRow();
      UI::TableNextColumn(); UI::Text(cpIdx == numCols - 1 ? "Fin" : "CP" + (cpIdx + 1));
      for (int lapIdx = 0; lapIdx < MAX_LAPS; lapIdx++) {
        UI::TableNextColumn();
        bool completed = g_state.GetDisplayLapTime(lapIdx) != -1 && disp !is null && lapIdx < int(disp.laps.Length);
        bool active    = isRacing && lapIdx == g_state.currentLap;
        if (!completed && !active) { UI::Text("-"); continue; }
        Lap@ lap = null;
        if (disp !is null && lapIdx < int(disp.laps.Length)) {
          @lap = disp.GetLap(lapIdx);
        }
        if (lap is null || cpIdx >= int(lap.checkpoints.Length)) { UI::Text("-"); continue; }
        RenderCpCell(lap.GetCheckpointTime(cpIdx), GetCpRefTime(lapIdx, cpIdx, bestEverCp), deltaMode);
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

  // Determine column count from data.
  Attempt@ disp = g_uiState.displayAttempt;
  int numCols = g_state.numCps;
  if (disp !is null) {
    for (uint lapIdx = 0; lapIdx < disp.laps.Length; lapIdx++) {
      Lap@ lap = disp.laps[lapIdx];
      if (lap is null) continue;
      // grow the CP column count to accommodate the longest split list.
      if (int(lap.checkpoints.Length) > numCols) numCols = int(lap.checkpoints.Length);
    }
  }
  // ensure numCols covers historical splits; even when there are
  // no recorded CPs yet (numCols == 0), still show the empty window so the user can see that
  // the map is eligible and the CP overlay is active.

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

  bool isStale = g_uiState.isStale;
  g_fmtThousandths = cpUseThousandths;
  UI::PushFont(cpFontStyle == FontStyle::Bold ? UI::Font::DefaultBold : cpFontStyle == FontStyle::Mono ? UI::Font::DefaultMono : UI::Font::Default);
  UI::PushFontSize(cpFontSize);
  if (cpGradientEnabled && g_cpWinSize.x > 0) DrawGradientBg(g_cpWinPos, g_cpWinSize, cpGradientRadial, cpGradientColor1, cpGradientColor2);
  UI::PushStyleColor(UI::Col::WindowBg, cpGradientEnabled ? vec4(0, 0, 0, 0) : cpWindowBgColor);
  UI::PushStyleColor(UI::Col::Text, isStale ? vec4(cpTextColor.x, cpTextColor.y, cpTextColor.z, cpTextColor.w * 0.45f) : cpTextColor);
  UI::Begin("CpTimes", windowFlags);

  if (!cpLockPosition) {
    anchorCp = UI::GetWindowPos();
  }
  g_cpWinPos  = UI::GetWindowPos();
  g_cpWinSize = UI::GetWindowSize();

  bool isRacing = g_uiState.isRacing;
  // precompute best-ever per CP position across all laps (mode 3).
  // Note: GetCpRefTime now reads DeltaBestAllTime directly from Bests, but we still pass an array for compatibility.
  array<int> bestEverCp;
  for (int cpIdx = 0; cpIdx < numCols; cpIdx++) {
    bestEverCp.InsertLast(g_state.bests.GetBestAnyCpTime(cpIdx));
  }

  bool deltaMode = cpDisplayMode != CpDisplayMode::Absolute;
  int colWidth = deltaMode ? styleColWidthCpDelta : styleColWidthCpAbs;

  if (cpTableTransposed) RenderCpTableTransposed(isRacing, numCols, deltaMode, colWidth, bestEverCp);
  else                   RenderCpTableNormal(isRacing, numCols, deltaMode, colWidth, bestEverCp);

  UI::End();
  UI::PopStyleColor(2);
  UI::PopFontSize();
  UI::PopFont();
}

