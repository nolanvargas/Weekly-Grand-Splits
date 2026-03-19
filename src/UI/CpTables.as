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

    // 10 lap rows
    for (int lapIdx = 0; lapIdx < MAX_LAPS; lapIdx++) {
      UI::TableNextRow();
      array<array<int>> lapCp = g_state.currentAttempt.ToLapCpArray();
      // mark rows as completed if we have stored CP splits for that lap, or as active if it is the current in-progress lap.
      bool completed = lapIdx < g_state.currentLap && int(lapCp.Length) > lapIdx;
      bool active    = isRacing && lapIdx == g_state.currentLap;

      if (completed || active) {
        // for completed or active laps, render each CP cell as either an absolute time or delta vs the chosen reference.
        UI::TableNextColumn(); UI::Text("" + (lapIdx + 1));
        array<int> cpTimes;
        if (lapIdx < int(lapCp.Length)) cpTimes = lapCp[lapIdx];
        for (int cpIdx = 0; cpIdx < numCols; cpIdx++) {
          UI::TableNextColumn();
          if (cpIdx >= int(cpTimes.Length)) { UI::Text("-"); continue; }
          RenderCpCell(cpTimes[cpIdx], GetCpRefTime(lapIdx, cpIdx, bestEverCp), deltaMode);
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

    // one row per CP
    for (int cpIdx = 0; cpIdx < numCols; cpIdx++) {
      UI::TableNextRow();
      UI::TableNextColumn(); UI::Text(cpIdx == numCols - 1 ? "Fin" : "CP" + (cpIdx + 1));
      array<array<int>> lapCp = g_state.currentAttempt.ToLapCpArray();
      for (int lapIdx = 0; lapIdx < MAX_LAPS; lapIdx++) {
        UI::TableNextColumn();
        bool completed = lapIdx < g_state.currentLap && int(lapCp.Length) > lapIdx;
        bool active    = isRacing && lapIdx == g_state.currentLap;
        if (!completed && !active) { UI::Text("-"); continue; }
      array<int> cpTimes;
      if (lapIdx < int(lapCp.Length)) cpTimes = lapCp[lapIdx];
        if (cpIdx >= int(cpTimes.Length)) { UI::Text("-"); continue; }
        RenderCpCell(cpTimes[cpIdx], GetCpRefTime(lapIdx, cpIdx, bestEverCp), deltaMode);
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
#if TMNEXT
  auto map = app.RootMap;
#endif

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
  array<array<int>> lapCp = g_state.currentAttempt.ToLapCpArray();
  int numCols = g_state.numCps;
  for (uint lapIdx = 0; lapIdx < lapCp.Length; lapIdx++) {
    // grow the CP column count to accommodate the longest split list.
    if (int(lapCp[lapIdx].Length) > numCols) numCols = int(lapCp[lapIdx].Length);
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

  g_fmtThousandths = cpUseThousandths;
  UI::PushFont(cpFontStyle == FontStyle::Bold ? UI::Font::DefaultBold : cpFontStyle == FontStyle::Mono ? UI::Font::DefaultMono : UI::Font::Default);
  UI::PushFontSize(cpFontSize);
  if (cpGradientEnabled && g_cpWinSize.x > 0) DrawGradientBg(g_cpWinPos, g_cpWinSize, cpGradientRadial, cpGradientColor1, cpGradientColor2);
  UI::PushStyleColor(UI::Col::WindowBg, cpGradientEnabled ? vec4(0, 0, 0, 0) : cpWindowBgColor);
  UI::PushStyleColor(UI::Col::Text, cpTextColor);
  UI::Begin("CpTimes", windowFlags);

  if (!cpLockPosition) {
    anchorCp = UI::GetWindowPos();
  }
  g_cpWinPos  = UI::GetWindowPos();
  g_cpWinSize = UI::GetWindowSize();

  bool isRacing = !g_state.waitForCarReset && !g_state.resetData && !g_state.isFinished;
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

