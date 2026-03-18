vec2 g_lapWinPos;
vec2 g_lapWinSize;
vec2 g_cpWinPos;
vec2 g_cpWinSize;
vec2 anchor = vec2(0, 780);
vec2 anchorCp = vec2(300, 780);

void DrawGradientBg(vec2 pos, vec2 size, bool radial, vec4 color1, vec4 color2) {
  nvg::BeginPath();
  nvg::Rect(pos.x, pos.y, size.x, size.y);
  nvg::Paint paint;
  if (radial) {
    float r = Math::Sqrt(size.x * size.x / 4.0f + size.y * size.y / 4.0f);
    paint = nvg::RadialGradient(
      vec2(pos.x + size.x * 0.5f, pos.y + size.y * 0.5f),
      0.0f, r,
      color1, color2
    );
  } else {
    paint = nvg::LinearGradient(
      vec2(pos.x, pos.y), vec2(pos.x, pos.y + size.y),
      color1, color2
    );
  }
  nvg::FillPaint(paint);
  nvg::Fill();
}

vec4 GetLapDeltaColor(int delta, bool hasBest) {
  if (!hasBest || delta == 0) return COLOR_WHITE;
  return delta < 0 ? COLOR_GREEN : COLOR_RED;
}

vec4 GetLiveDeltaColor(int liveDelta) {
  if (liveDelta < 0) return COLOR_GREEN;
  if (liveDelta > 0) return COLOR_RED;
  return COLOR_GRAY;
}

void RenderCpCell(int cpTime, int refTime, bool deltaMode) {
  if (!deltaMode || refTime == 0) { UI::Text(FormatCpTime(cpTime)); return; }
  int delta = cpTime - refTime;
  vec4 color = delta < 0 ? COLOR_GREEN : (delta > 0 ? COLOR_RED : COLOR_WHITE);
  UI::PushStyleColor(UI::Col::Text, color);
  UI::Text(FormatDelta(delta));
  UI::PopStyleColor();
}

int GetCpRefTime(int lapIdx, int cpIdx, array<int>@ bestEverCp) {
  if (cpDisplayMode == CpDisplayMode::DeltaPB) {
    if (lapIdx < int(g_state.bestLapCpTimes.Length) && cpIdx < int(g_state.bestLapCpTimes[lapIdx].Length))
      return g_state.bestLapCpTimes[lapIdx][cpIdx];
  } else if (cpDisplayMode == CpDisplayMode::DeltaBestLapCp) {
    if (lapIdx < int(g_state.bestAllTimeCpTimes.Length) && cpIdx < int(g_state.bestAllTimeCpTimes[lapIdx].Length))
      return g_state.bestAllTimeCpTimes[lapIdx][cpIdx];
  } else if (cpDisplayMode == CpDisplayMode::DeltaBestAllTime) {
    if (cpIdx < int(bestEverCp.Length)) return bestEverCp[cpIdx];
  }
  return 0;
}

void SetMinWidth(int width) {
  UI::PushStyleVar(UI::StyleVar::ItemSpacing, vec2(0, 0));
  UI::Dummy(vec2(width, 0));
  UI::PopStyleVar();
}


void RenderLapTableNormal(bool isRacing, int liveTime) {
  if (UI::BeginTable("splits", 3, UI::TableFlags::SizingFixedFit)) {
    UI::TableNextColumn(); SetMinWidth(COL_WIDTH_LAP);   UI::Text("Lap");
    UI::TableNextColumn(); SetMinWidth(COL_WIDTH_DELTA); UI::Text("+/-");
    UI::TableNextColumn(); SetMinWidth(COL_WIDTH_TIME);  UI::Text("Time");

    for (int lapIdx = 0; lapIdx < MAX_LAPS; lapIdx++) {
      UI::TableNextRow();
      bool completed = g_state.GetLapTime(lapIdx) != -1;
      bool active    = isRacing && (lapIdx == g_state.currentLap);

      if (completed) {
        bool hasBest = g_state.GetBestLapTime(lapIdx) != -1;
        int delta    = hasBest ? (g_state.GetLapTime(lapIdx) - g_state.GetBestLapTime(lapIdx)) : 0;
        bool isGold  = g_state.GetBestAllTimeLapTime(lapIdx) > 0 && g_state.GetLapTime(lapIdx) <= g_state.GetBestAllTimeLapTime(lapIdx);
        UI::TableNextColumn(); UI::Text("" + (lapIdx + 1));
        UI::PushStyleColor(UI::Col::Text, GetLapDeltaColor(delta, hasBest));
        UI::TableNextColumn(); UI::Text(hasBest ? FormatDelta(delta) : "-");
        UI::PopStyleColor();
        if (isGold) UI::PushStyleColor(UI::Col::Text, COLOR_GOLD);
        UI::TableNextColumn(); UI::Text(FormatTenth(g_state.GetLapTime(lapIdx)));
        if (isGold) UI::PopStyleColor();

      } else if (active) {
        bool hasBest   = g_state.GetBestLapTime(lapIdx) != -1;
        int liveDelta  = hasBest ? (liveTime - g_state.GetBestLapTime(lapIdx)) : 0;
        bool showDelta = hasBest && liveDelta >= -5000;
        UI::TableNextColumn(); UI::Text("" + (lapIdx + 1));
        if (showDelta) {
          UI::PushStyleColor(UI::Col::Text, GetLiveDeltaColor(liveDelta));
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
    vec4 totalColor = GetLapDeltaColor(totalDelta, showTotalDelta);

    UI::TableNextColumn();
    UI::PushStyleColor(UI::Col::Text, totalColor);
    UI::TableNextColumn(); UI::Text(showTotalDelta ? FormatDelta(totalDelta) : "-");
    UI::PopStyleColor();
    UI::TableNextColumn(); UI::Text(hasTotal ? FormatTenth(displayTotal) : "-");

    UI::EndTable();
  }
}

void RenderLapTableTransposed(bool isRacing, int liveTime) {
  int totalRun = 0, bestForCompleted = 0;
  bool hasCompletedLap = false, allCompletedHaveBest = true;
  for (int i = 0; i < MAX_LAPS; i++) {
    if (g_state.GetLapTime(i) != -1) {
      totalRun += g_state.GetLapTime(i); hasCompletedLap = true;
      if (g_state.GetBestLapTime(i) != -1) bestForCompleted += g_state.GetBestLapTime(i);
      else allCompletedHaveBest = false;
    }
  }
  int displayTotal = totalRun + (isRacing ? liveTime : 0);
  bool hasTotal = displayTotal > 0 || g_state.isFinished;
  bool showTotalDelta = hasCompletedLap && allCompletedHaveBest;
  int totalDelta = showTotalDelta ? (totalRun - bestForCompleted) : 0;
  vec4 totalColor = GetLapDeltaColor(totalDelta, showTotalDelta);

  // cols: label | Lap1..Lap10 | Total = 12
  if (UI::BeginTable("splits_t", 1 + MAX_LAPS + 1, UI::TableFlags::SizingFixedFit)) {
    // Header row: blank | 1 | 2 | ... | 10 | blank
    UI::TableNextColumn(); SetMinWidth(COL_WIDTH_DELTA);
    for (int lapIdx = 0; lapIdx < MAX_LAPS; lapIdx++) {
      UI::TableNextColumn(); SetMinWidth(COL_WIDTH_TIME); UI::Text("" + (lapIdx + 1));
    }
    UI::TableNextColumn(); SetMinWidth(COL_WIDTH_TIME);

    // +/- row
    UI::TableNextRow();
    UI::TableNextColumn(); UI::Text("+/-");
    for (int lapIdx = 0; lapIdx < MAX_LAPS; lapIdx++) {
      UI::TableNextColumn();
      bool completed = g_state.GetLapTime(lapIdx) != -1;
      bool active    = isRacing && (lapIdx == g_state.currentLap);
      if (completed) {
        bool hasBest = g_state.GetBestLapTime(lapIdx) != -1;
        int delta    = hasBest ? (g_state.GetLapTime(lapIdx) - g_state.GetBestLapTime(lapIdx)) : 0;
        UI::PushStyleColor(UI::Col::Text, GetLapDeltaColor(delta, hasBest));
        UI::Text(hasBest ? FormatDelta(delta) : "-");
        UI::PopStyleColor();
      } else if (active) {
        bool hasBest   = g_state.GetBestLapTime(lapIdx) != -1;
        int liveDelta  = hasBest ? (liveTime - g_state.GetBestLapTime(lapIdx)) : 0;
        bool showDelta = hasBest && liveDelta >= -5000;
        if (showDelta) {
          UI::PushStyleColor(UI::Col::Text, GetLiveDeltaColor(liveDelta));
          UI::Text(FormatDelta(liveDelta));
          UI::PopStyleColor();
        } else {
          UI::Text("-");
        }
      } else {
        UI::Text("-");
      }
    }
    UI::TableNextColumn();
    UI::PushStyleColor(UI::Col::Text, totalColor);
    UI::Text(showTotalDelta ? FormatDelta(totalDelta) : "-");
    UI::PopStyleColor();

    // Time row
    UI::TableNextRow();
    UI::TableNextColumn(); UI::Text("Time");
    for (int lapIdx = 0; lapIdx < MAX_LAPS; lapIdx++) {
      UI::TableNextColumn();
      bool completed = g_state.GetLapTime(lapIdx) != -1;
      bool active    = isRacing && (lapIdx == g_state.currentLap);
      if (completed) {
        bool isGold = g_state.GetBestAllTimeLapTime(lapIdx) > 0 && g_state.GetLapTime(lapIdx) <= g_state.GetBestAllTimeLapTime(lapIdx);
        if (isGold) UI::PushStyleColor(UI::Col::Text, COLOR_GOLD);
        UI::Text(FormatTenth(g_state.GetLapTime(lapIdx)));
        if (isGold) UI::PopStyleColor();
      } else if (active) {
        UI::Text(FormatTenth(liveTime));
      } else {
        UI::Text("-");
      }
    }
    UI::TableNextColumn();
    UI::Text(hasTotal ? FormatTenth(displayTotal) : "-");

    UI::EndTable();
  }
}

// modified https://github.com/Phlarx/tm-ultimate-medals
void Render() {
  StorageFile@ storage = g_storage;
  auto app = cast<CTrackMania>(GetApp());

#if TMNEXT || MP4
  auto map = app.RootMap;
#endif

  if (!g_state.isMultiLap) {
    return;
  }

  if (lapHideWithIFace) {
    auto playground = app.CurrentPlayground;
    if (playground is null || playground.Interface is null ||
        !UI::IsGameUIVisible()) {
      return;
    }
  }

  if (!windowVisible || map is null || map.MapInfo.MapUid == "") {
    return;
  }

  if (lapLockPosition) {
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

  g_fmtThousandths = lapUseThousandths;
  UI::PushFont(lapFontStyle == FontStyle::Bold ? UI::Font::DefaultBold : lapFontStyle == FontStyle::Mono ? UI::Font::DefaultMono : UI::Font::Default);
  UI::PushFontSize(lapFontSize);
  if (lapGradientEnabled && g_lapWinSize.x > 0) DrawGradientBg(g_lapWinPos, g_lapWinSize, lapGradientRadial, lapGradientColor1, lapGradientColor2);
  UI::PushStyleColor(UI::Col::WindowBg, lapGradientEnabled ? vec4(0, 0, 0, 0) : lapWindowBgColor);
  UI::PushStyleColor(UI::Col::Text, lapTextColor);
  UI::Begin("LapTimes", windowFlags);

  if (!lapLockPosition) {
    anchor = UI::GetWindowPos();
  }
  g_lapWinPos  = UI::GetWindowPos();
  g_lapWinSize = UI::GetWindowSize();

  bool isRacing = !g_state.waitForCarReset && !g_state.resetData && !g_state.isFinished && g_state.hasPlayerRaced;
  int liveTime = 0;
  if (isRacing) {
    liveTime = GetCurrentPlayerRaceTime() - g_state.prevLapRaceTime;
    if (liveTime < 0) liveTime = 0;
  }

  if (lapTableTransposed) RenderLapTableTransposed(isRacing, liveTime);
  else                    RenderLapTableNormal(isRacing, liveTime);

  UI::End();
  UI::PopStyleColor(2);
  UI::PopFontSize();
  UI::PopFont();

  RenderCpTable();
}

void RenderCpTableNormal(bool isRacing, int numCols, bool deltaMode, int colWidth, array<int>@ bestEverCp) {
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

void RenderCpTableTransposed(bool isRacing, int numCols, bool deltaMode, int colWidth, array<int>@ bestEverCp) {
  // cols: CP label | Lap1..Lap10 = 1 + MAX_LAPS = 11
  if (UI::BeginTable("cptable_t", 1 + MAX_LAPS, UI::TableFlags::SizingFixedFit)) {
    // header row: "Lap" | 1 | 2 | ... | 10
    UI::TableNextColumn(); SetMinWidth(COL_WIDTH_CP_ABS); UI::Text("Lap");
    for (int lapIdx = 0; lapIdx < MAX_LAPS; lapIdx++) {
      UI::TableNextColumn(); SetMinWidth(colWidth); UI::Text("" + (lapIdx + 1));
    }

    // one row per CP
    for (int cpIdx = 0; cpIdx < numCols; cpIdx++) {
      UI::TableNextRow();
      UI::TableNextColumn(); UI::Text(cpIdx == numCols - 1 ? "Fin" : "CP" + (cpIdx + 1));
      for (int lapIdx = 0; lapIdx < MAX_LAPS; lapIdx++) {
        UI::TableNextColumn();
        bool completed = lapIdx < g_state.currentLap && int(g_state.allLapCpTimes.Length) > lapIdx;
        bool active    = isRacing && lapIdx == g_state.currentLap;
        if (!completed && !active) { UI::Text("-"); continue; }
        array<int>@ cpTimes = active ? g_state.currLapCpTimes : g_state.allLapCpTimes[lapIdx];
        if (cpIdx >= int(cpTimes.Length)) { UI::Text("-"); continue; }
        RenderCpCell(cpTimes[cpIdx], GetCpRefTime(lapIdx, cpIdx, bestEverCp), deltaMode);
      }
    }

    UI::EndTable();
  }
}

void RenderCpTable() {
  if (!cpTableVisible) return;

  auto app = cast<CTrackMania>(GetApp());
#if TMNEXT || MP4
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

  // determine column count from data
  int numCols = g_state.numCps;
  for (uint lapIdx = 0; lapIdx < g_state.allLapCpTimes.Length; lapIdx++) {
    if (int(g_state.allLapCpTimes[lapIdx].Length) > numCols) numCols = int(g_state.allLapCpTimes[lapIdx].Length);
  }
  if (int(g_state.currLapCpTimes.Length) > numCols) numCols = int(g_state.currLapCpTimes.Length);
  if (numCols == 0) return;

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

  bool deltaMode = cpDisplayMode != CpDisplayMode::Absolute;
  int colWidth = deltaMode ? COL_WIDTH_CP_DELTA : COL_WIDTH_CP_ABS;

  if (cpTableTransposed) RenderCpTableTransposed(isRacing, numCols, deltaMode, colWidth, bestEverCp);
  else                   RenderCpTableNormal(isRacing, numCols, deltaMode, colWidth, bestEverCp);

  UI::End();
  UI::PopStyleColor(2);
  UI::PopFontSize();
  UI::PopFont();
}
