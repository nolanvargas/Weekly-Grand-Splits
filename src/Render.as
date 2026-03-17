void SetMinWidth(int width) {
  UI::PushStyleVar(UI::StyleVar::ItemSpacing, vec2(0, 0));
  UI::Dummy(vec2(width, 0));
  UI::PopStyleVar();
}

void LoadFont() {
  string fontFaceToLoad = fontFace.Length == 0 ? "DroidSans.ttf" : fontFace;
  if (fontFaceToLoad != g_state.loadedFontFace || fontSize != g_state.loadedFontSize) {
    @g_state.font = UI::LoadFont(fontFaceToLoad, fontSize);
    if (g_state.font !is null) {
      g_state.loadedFontFace = fontFaceToLoad;
      g_state.loadedFontSize = fontSize;
    }
  }
}

// modified https://github.com/Phlarx/tm-ultimate-medals
void Render() {
  auto app = cast<CTrackMania>(GetApp());

#if TMNEXT || MP4
  auto map = app.RootMap;
#endif

  if (!g_state.isMultiLap) {
    return;
  }

  if (hideWithIFace) {
    auto playground = app.CurrentPlayground;
    if (playground is null || playground.Interface is null ||
        !UI::IsGameUIVisible()) {
      return;
    }
  }

  if (!windowVisible || map is null || map.MapInfo.MapUid == "") {
    return;
  }

  if (lockPosition) {
    UI::SetNextWindowPos(int(anchor.x), int(anchor.y), UI::Cond::Always);
  } else {
    UI::SetNextWindowPos(int(anchor.x), int(anchor.y), UI::Cond::FirstUseEver);
  }

  int windowFlags =
      UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoCollapse |
      UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking;
  if (!UI::IsOverlayShown()) {
    windowFlags |= UI::WindowFlags::NoInputs;
  }

  UI::PushFont(g_state.font);
  UI::Begin("LapTimes", windowFlags);

  if (!lockPosition) {
    anchor = UI::GetWindowPos();
  }

  // Determine racing state
  bool isRacing = !g_state.waitForCarReset && !g_state.resetData && !g_state.isFinished && g_state.hasPlayerRaced;
  int liveTime = 0;
  if (isRacing) {
    liveTime = GetCurrentPlayerRaceTime() - g_state.prevLapRaceTime;
    if (liveTime < 0) liveTime = 0;
  }

  // 3-column table: Lap | +/- | Accumulated time (to tenth)
  if (UI::BeginTable("splits", 3, UI::TableFlags::SizingFixedFit)) {
    UI::TableNextColumn(); SetMinWidth(COL_WIDTH_LAP);   UI::Text("Lap");
    UI::TableNextColumn(); SetMinWidth(COL_WIDTH_DELTA); UI::Text("+/-");
    UI::TableNextColumn(); SetMinWidth(COL_WIDTH_TIME);  UI::Text("Time");

    for (int lapIdx = 0; lapIdx < MAX_LAPS; lapIdx++) {
      UI::TableNextRow();
      bool completed = g_state.GetLapTime(lapIdx) != -1;
      bool active    = isRacing && (lapIdx == g_state.currentLap);

      if (completed) {
        bool hasBest  = g_state.GetBestLapTime(lapIdx) != -1;
        int delta     = hasBest ? (g_state.GetLapTime(lapIdx) - g_state.GetBestLapTime(lapIdx)) : 0;
        bool isGold   = g_state.GetBestAllTimeLapTime(lapIdx) > 0 && g_state.GetLapTime(lapIdx) <= g_state.GetBestAllTimeLapTime(lapIdx);
        vec4 deltaColor;
        if (!hasBest || delta == 0) {
          deltaColor = COLOR_WHITE;
        } else if (delta < 0) {
          deltaColor = COLOR_GREEN;
        } else {
          deltaColor = COLOR_RED;
        }
        UI::TableNextColumn(); UI::Text("" + (lapIdx + 1));
        UI::PushStyleColor(UI::Col::Text, deltaColor);
        UI::TableNextColumn(); UI::Text(hasBest ? FormatDelta(delta) : "-");
        UI::PopStyleColor();
        if (isGold) UI::PushStyleColor(UI::Col::Text, COLOR_GOLD);
        UI::TableNextColumn(); UI::Text(FormatTenth(g_state.GetLapTime(lapIdx)));
        if (isGold) UI::PopStyleColor();

      } else if (active) {
        bool hasBest  = g_state.GetBestLapTime(lapIdx) != -1;
        int liveDelta = hasBest ? (liveTime - g_state.GetBestLapTime(lapIdx)) : 0;
        bool showDelta = hasBest && liveDelta >= -5000;
        UI::TableNextColumn(); UI::Text("" + (lapIdx + 1));
        if (showDelta) {
          vec4 deltaColor;
          if (liveDelta < 0)      deltaColor = COLOR_GREEN;
          else if (liveDelta > 0) deltaColor = COLOR_RED;
          else                    deltaColor = COLOR_GRAY;
          UI::PushStyleColor(UI::Col::Text, deltaColor);
          UI::TableNextColumn(); UI::Text(FormatDelta(liveDelta));
          UI::PopStyleColor();
          UI::TableNextColumn(); UI::Text(FormatTenth(liveTime));
        } else {
          UI::TableNextColumn(); UI::Text("-");
          UI::TableNextColumn(); UI::Text(FormatTenth(liveTime));
        }

      } else {
        UI::TableNextColumn(); UI::Text("" + (lapIdx + 1));
        UI::TableNextColumn(); UI::Text("-");
        UI::TableNextColumn(); UI::Text("-");
      }
    }

    // Separator row then Total
    UI::TableNextRow();
    UI::TableNextColumn(); UI::Text("---");
    UI::TableNextColumn(); UI::Text("---");
    UI::TableNextColumn(); UI::Text("---");

    UI::TableNextRow();
    int totalRun = 0;
    int bestForCompleted = 0;
    bool hasCompletedLap = false;
    bool allCompletedHaveBest = true;
    for (int lapIdx = 0; lapIdx < MAX_LAPS; lapIdx++) {
      if (g_state.GetLapTime(lapIdx) != -1) {
        totalRun += g_state.GetLapTime(lapIdx);
        hasCompletedLap = true;
        if (g_state.GetBestLapTime(lapIdx) != -1) bestForCompleted += g_state.GetBestLapTime(lapIdx);
        else allCompletedHaveBest = false;
      }
    }
    int displayTotal = totalRun + (isRacing ? liveTime : 0);
    bool hasTotal = displayTotal > 0 || g_state.isFinished;
    bool showTotalDelta = hasCompletedLap && allCompletedHaveBest;
    int totalDelta = showTotalDelta ? (totalRun - bestForCompleted) : 0;

    vec4 totalColor;
    if (!showTotalDelta || totalDelta == 0) {
      totalColor = COLOR_WHITE;
    } else if (totalDelta < 0) {
      totalColor = COLOR_GREEN;
    } else {
      totalColor = COLOR_RED;
    }

    UI::TableNextColumn();
    UI::PushStyleColor(UI::Col::Text, totalColor);
    UI::TableNextColumn(); UI::Text(showTotalDelta ? FormatDelta(totalDelta) : "-");
    UI::PopStyleColor();
    UI::TableNextColumn(); UI::Text(hasTotal ? FormatTenth(displayTotal) : "-");

    UI::EndTable();
  }

  UI::End();

  RenderCpTable();

  UI::PopFont();
}

void RenderCpTable() {
  if (!cpTableVisible) return;

  auto app = cast<CTrackMania>(GetApp());
#if TMNEXT || MP4
  auto map = app.RootMap;
#endif

  if (!g_state.isMultiLap) return;

  if (hideWithIFace) {
    auto playground = app.CurrentPlayground;
    if (playground is null || playground.Interface is null ||
        !UI::IsGameUIVisible()) {
      return;
    }
  }

  if (map is null || map.MapInfo.MapUid == "") return;

  // determine column count from data
  int numCols = g_state.numCps;
  for (uint lapIdx = 0; lapIdx < g_state.allLapCpTimes.Length; lapIdx++) {
    if (int(g_state.allLapCpTimes[lapIdx].Length) > numCols) numCols = int(g_state.allLapCpTimes[lapIdx].Length);
  }
  if (int(g_state.currLapCpTimes.Length) > numCols) numCols = int(g_state.currLapCpTimes.Length);
  if (numCols == 0) return;

  if (lockPosition) {
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

  UI::Begin("CpTimes", windowFlags);

  if (!lockPosition) {
    anchorCp = UI::GetWindowPos();
  }

  bool isRacing = !g_state.waitForCarReset && !g_state.resetData && !g_state.isFinished && g_state.hasPlayerRaced;

  // precompute best-ever per CP position across all laps (mode 3)
  array<int> bestEverCp;
  for (int cpIdx = 0; cpIdx < numCols; cpIdx++) {
    int bestTime = 0;
    for (uint bestLapIdx = 0; bestLapIdx < g_state.bestAllTimeCpTimes.Length; bestLapIdx++) {
      if (cpIdx < int(g_state.bestAllTimeCpTimes[bestLapIdx].Length)) {
        int cpTime = g_state.bestAllTimeCpTimes[bestLapIdx][cpIdx];
        if (cpTime > 0 && (bestTime == 0 || cpTime < bestTime)) bestTime = cpTime;
      }
    }
    bestEverCp.InsertLast(bestTime);
  }

  bool deltaMode = cpDisplayMode > 0;
  int colWidth = deltaMode ? COL_WIDTH_CP_DELTA : COL_WIDTH_CP_ABS;

  if (UI::BeginTable("cptable", numCols + 1, UI::TableFlags::SizingFixedFit)) {
    // header row
    UI::TableNextColumn(); SetMinWidth(COL_WIDTH_CP_LAP); UI::Text("Lap");
    for (int cpIdx = 0; cpIdx < numCols; cpIdx++) {
      UI::TableNextColumn(); SetMinWidth(colWidth);
      UI::Text(cpIdx == numCols - 1 ? "Fin" : "CP" + (cpIdx + 1));
    }

    // 10 lap rows
    for (int lapIdx = 0; lapIdx < MAX_LAPS; lapIdx++) {
      UI::TableNextRow();
      bool completed = lapIdx < g_state.currentLap && int(g_state.allLapCpTimes.Length) > lapIdx;
      bool active    = isRacing && lapIdx == g_state.currentLap;

      if (completed || active) {
        UI::TableNextColumn(); UI::Text("" + (lapIdx + 1));
        array<int>@ cpTimes = active ? g_state.currLapCpTimes : g_state.allLapCpTimes[lapIdx];
        for (int cpIdx = 0; cpIdx < numCols; cpIdx++) {
          UI::TableNextColumn();
          if (cpIdx >= int(cpTimes.Length)) { UI::Text("-"); continue; }
          int cpTime = cpTimes[cpIdx];
          if (!deltaMode) {
            UI::Text(FormatCpTime(cpTime));
            continue;
          }
          int refTime = 0;
          if (cpDisplayMode == 1) {
            if (lapIdx < int(g_state.bestLapCpTimes.Length) && cpIdx < int(g_state.bestLapCpTimes[lapIdx].Length))
              refTime = g_state.bestLapCpTimes[lapIdx][cpIdx];
          } else if (cpDisplayMode == 2) {
            if (lapIdx < int(g_state.bestAllTimeCpTimes.Length) && cpIdx < int(g_state.bestAllTimeCpTimes[lapIdx].Length))
              refTime = g_state.bestAllTimeCpTimes[lapIdx][cpIdx];
          } else if (cpDisplayMode == 3) {
            if (cpIdx < int(bestEverCp.Length)) refTime = bestEverCp[cpIdx];
          }
          if (refTime == 0) { UI::Text(FormatCpTime(cpTime)); continue; }
          int delta = cpTime - refTime;
          vec4 color;
          if (delta < 0)      color = COLOR_GREEN;
          else if (delta > 0) color = COLOR_RED;
          else                color = COLOR_WHITE;
          UI::PushStyleColor(UI::Col::Text, color);
          UI::Text(FormatDelta(delta));
          UI::PopStyleColor();
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

  UI::End();
}
