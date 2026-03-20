// Renders the lap table in vertical form: one row per lap.
// Shows completed laps, the currently active lap with live delta, and a total row.
void RenderLapTableNormal(bool isRacing, int liveTime) {
  if (UI::BeginTable("splits", 3, UI::TableFlags::SizingFixedFit)) {
    // open a 3-column ImGui table for lap index, delta vs PB, and lap time using fixed column widths.
    UI::TableNextColumn(); SetMinWidth(styleColWidthLap);   UI::Text("Lap");
    UI::TableNextColumn(); SetMinWidth(styleColWidthDelta); UI::Text("+/-");
    UI::TableNextColumn(); SetMinWidth(styleColWidthTime);  UI::Text("Time");

    for (int lapIdx = 0; lapIdx < MAX_LAPS; lapIdx++) {
      UI::TableNextRow();
      bool completed = g_state.GetDisplayLapTime(lapIdx) != -1;
      bool active    = isRacing && (lapIdx == g_state.currentLap);

      if (completed) {
        // show final time for a completed lap plus its delta vs PB, highlighting golds where the time beats the all-time best.
        int lapTime   = g_state.GetDisplayLapTime(lapIdx);
        bool hasBest = g_state.bests.GetBestSingleAttemptLapTotal(lapIdx) != -1;
        int bestLap   = g_state.bests.GetBestSingleAttemptLapTotal(lapIdx);
        int delta     = hasBest ? (lapTime - bestLap) : 0;
        int bestAll   = g_state.bests.GetBestLapTotalByLapIndex(lapIdx);
        bool isGold  = bestAll > 0 && lapTime <= bestAll;
        UI::TableNextColumn(); UI::Text("" + (lapIdx + 1));
        UI::PushStyleColor(UI::Col::Text, GetLapDeltaColor(delta, hasBest));
        UI::TableNextColumn(); UI::Text(hasBest ? FormatDelta(delta) : "-");
        UI::PopStyleColor();
        if (isGold) UI::PushStyleColor(UI::Col::Text, COLOR_GOLD);
        UI::TableNextColumn(); UI::Text(FormatTenth(lapTime));
        if (isGold) UI::PopStyleColor();

      } else if (active) {
        // for the currently racing lap, display a live delta vs PB (if reasonable) and the live lap timer.
        bool hasBest   = g_state.bests.GetBestSingleAttemptLapTotal(lapIdx) != -1;
        int bestLap    = g_state.bests.GetBestSingleAttemptLapTotal(lapIdx);
        int liveDelta  = hasBest ? (liveTime - bestLap) : 0;
        bool showDelta = hasBest && liveDelta >= -5000;
        UI::TableNextColumn(); UI::Text("" + (lapIdx + 1));
        if (showDelta) {
          // when the live delta is within a reasonable window, color it green/red and show both delta and live time.
          UI::PushStyleColor(UI::Col::Text, GetLiveDeltaColor(liveDelta));
          UI::TableNextColumn(); UI::Text(FormatDelta(liveDelta));
          UI::PopStyleColor();
          UI::TableNextColumn(); UI::Text(FormatTenth(liveTime));
        } else {
          // otherwise, hide the delta column and only show the live time for the lap.
          UI::TableNextColumn(); UI::Text("-");
          UI::TableNextColumn(); UI::Text(FormatTenth(liveTime));
        }

      } else {
        // for laps that have not started yet, draw placeholder "-" cells for readability.
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
      int lapTime = g_state.GetDisplayLapTime(lapIdx);
      if (lapTime != -1) {
        // accumulate total run time only for laps that have been completed.
        totalRun += lapTime;
        hasCompletedLap = true;
        int bestLap = g_state.bests.GetBestSingleAttemptLapTotal(lapIdx);
        if (bestLap != -1) bestForCompleted += bestLap;
        else allCompletedHaveBest = false;
        // if any completed lap lacks a PB, mark that we cannot compute a meaningful total delta.
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

// Renders the lap table transposed: one column per lap.
// Useful when horizontal space is available and many laps are visible at once.
void RenderLapTableTransposed(bool isRacing, int liveTime) {
  int totalRun = 0, bestForCompleted = 0;
  bool hasCompletedLap = false, allCompletedHaveBest = true;
  for (int lapIdx = 0; lapIdx < MAX_LAPS; lapIdx++) {
    int lapTime = g_state.GetDisplayLapTime(lapIdx);
    if (lapTime != -1) {
      // for each completed lap, add its time to the total and, when available, its PB to the comparison baseline.
      totalRun += lapTime; hasCompletedLap = true;
      int bestLap = g_state.bests.GetBestSingleAttemptLapTotal(lapIdx);
      if (bestLap != -1) bestForCompleted += bestLap;
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
    UI::TableNextColumn(); SetMinWidth(styleColWidthDelta);
    for (int lapIdx = 0; lapIdx < MAX_LAPS; lapIdx++) {
      UI::TableNextColumn(); SetMinWidth(styleColWidthTime); UI::Text("" + (lapIdx + 1));
    }
    UI::TableNextColumn(); SetMinWidth(styleColWidthTime);

    // +/- row
    UI::TableNextRow();
    UI::TableNextColumn(); UI::Text("+/-");
    for (int lapIdx = 0; lapIdx < MAX_LAPS; lapIdx++) {
      UI::TableNextColumn();
      bool completed = g_state.GetDisplayLapTime(lapIdx) != -1;
      bool active    = isRacing && (lapIdx == g_state.currentLap);
      if (completed) {
        int lapTime  = g_state.GetDisplayLapTime(lapIdx);
        int bestLap = g_state.bests.GetBestSingleAttemptLapTotal(lapIdx);
        bool hasBest = bestLap != -1;
        int delta    = hasBest ? (lapTime - bestLap) : 0;
        UI::PushStyleColor(UI::Col::Text, GetLapDeltaColor(delta, hasBest));
        UI::Text(hasBest ? FormatDelta(delta) : "-");
        UI::PopStyleColor();
      } else if (active) {
        int bestLap   = g_state.bests.GetBestSingleAttemptLapTotal(lapIdx);
        bool hasBest  = bestLap != -1;
        int liveDelta = hasBest ? (liveTime - bestLap) : 0;
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
      bool completed = g_state.GetDisplayLapTime(lapIdx) != -1;
      bool active    = isRacing && (lapIdx == g_state.currentLap);
      if (completed) {
        int lapTime  = g_state.GetDisplayLapTime(lapIdx);
        int bestAll = g_state.bests.GetBestLapTotalByLapIndex(lapIdx);
        bool isGold = bestAll > 0 && lapTime <= bestAll;
        if (isGold) UI::PushStyleColor(UI::Col::Text, COLOR_GOLD);
        UI::Text(FormatTenth(lapTime));
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

