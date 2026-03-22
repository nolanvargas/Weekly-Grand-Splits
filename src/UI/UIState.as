// Pre-computed display values for a single CP cell.
class CpCellData {
  bool hasData = false;
  int  cpTime  = 0;
  int  refTime = 0;
}

// Pre-computed display values for a single lap row.
class LapDisplayData {
  bool completed = false;
  bool active    = false;
  // completed lap
  int  lapTime   = -1;
  bool hasBest   = false;
  int  delta     = 0;   // lapTime - PB lap time
  bool isGold    = false;
  // active lap
  int  liveDelta  = 0;
  bool showDelta  = false;
}

class UIState {
  Attempt@ displayAttempt = null;
  Bests@   bests           = null;
  bool isStale    = false;
  bool lapIsStale = false;
  bool cpIsStale  = false;
  bool isRacing   = false;
  int  liveTime   = 0;
  int  currentLap = 0;
  bool isFinished = false;
  int  numCps     = 0;
  int  numLaps    = 0;

  // Per-lap display data, indexed 1..numLaps (index 0 unused).
  array<LapDisplayData@> lapData;

  // Per-cell CP data, indexed [lapIdx][cpIdx], both 1-based (index 0 unused in each dimension).
  array<array<CpCellData@>> cpData;
  int  numCpCols   = 0;
  bool cpDeltaMode = false;

  // Pre-computed total row values.
  int  displayTotal   = 0;
  bool hasTotal       = false;
  bool showTotalDelta = false;
  int  totalDelta     = 0;
  vec4 totalColor;

  // Switches the display to the previous attempt on new attempt start.
  void OnNewAttempt(Attempt@ prev) {
    @displayAttempt = prev;
  }

  // Switches the display to the current attempt on checkpoint crossing.
  void OnCheckpointReached(Attempt@ current) {
    @displayAttempt = current;
  }

  // Clears all display state on map change or waypoint update.
  void OnReset() {
    @displayAttempt = null;
    isStale  = false;
    isRacing = false;
    liveTime = 0;
    lapData.Resize(0);
    cpData.Resize(0);
    numCpCols = 0;
  }

  // Refreshes all derived display values from game state each frame.
  void Update() {
    @bests      = g_state.bests;
    currentLap  = g_state.currentLap;
    isFinished  = g_state.isFinished;
    numCps      = g_state.numCps;
    numLaps     = g_state.numLaps;

    bool newStale   = g_state.IsStale();
    bool newRacing  = !g_state.waitForCarReset && !g_state.resetData && !g_state.isFinished && !newStale;
    int  newLive    = newRacing ? Math::Max(0, GetCurrentPlayerRaceTime() - g_state.prevLapRaceTime) : 0;

    isStale  = newStale;
    isRacing = newRacing;
    liveTime = newLive;

    // Fallback: if displayAttempt was never set by an event (e.g. plugin loaded mid-race),
    // derive it the old way so the UI is never blank when it shouldn't be.
    if (displayAttempt is null && (g_state.currentAttempt !is null || g_state.previousAttempt !is null)) {
      @displayAttempt = g_state.previousAttempt !is null ? g_state.previousAttempt : g_state.currentAttempt;
    }

    // "commenced but no CP yet" — OnAttemptCommenced has fired but the player hasn't hit a CP.
    // When the per-window "keep previous" setting is OFF, switch immediately to currentAttempt.
    bool commenced = g_state.previousAttempt !is null && !g_state.resetData;

    Attempt@ lapAttempt;
    if (!lapKeepPreviousAttempt && commenced) {
      @lapAttempt = g_state.currentAttempt;
      lapIsStale  = false;
    } else {
      @lapAttempt = displayAttempt;
      lapIsStale  = newStale;
    }

    Attempt@ cpAttempt;
    if (!cpKeepPreviousAttempt && commenced) {
      @cpAttempt = g_state.currentAttempt;
      cpIsStale  = false;
    } else {
      @cpAttempt = displayAttempt;
      cpIsStale  = newStale;
    }

    ComputeLapData(lapAttempt);
    ComputeCpData(cpAttempt);
  }

  // Computes per-lap display values and the total row for rendering.
  private void ComputeLapData(Attempt@ att) {
    lapData.Resize(numLaps + 1); // index 0 unused; laps start at 1

    int totalRun          = 0;
    int bestForCompleted  = 0;
    bool hasCompletedLap  = false;
    bool allHaveBest      = true;

    for (int lapIdx = 1; lapIdx <= numLaps; lapIdx++) {
      LapDisplayData@ d = LapDisplayData();
      int lapTime  = GetLapTimeFrom(att, lapIdx);
      int bestLap  = bests.GetBestSingleAttemptLapTotal(lapIdx);
      d.completed  = lapTime != -1;
      d.active     = isRacing && lapIdx == currentLap;

      if (d.completed) {
        d.lapTime  = lapTime;
        d.hasBest  = bestLap != -1;
        d.delta    = d.hasBest ? (lapTime - bestLap) : 0;
        int bestAll = bests.GetBestLapTotalByLapIndex(lapIdx);
        d.isGold   = bestAll > 0 && lapTime <= bestAll;

        totalRun += lapTime;
        hasCompletedLap = true;
        if (bestLap != -1) bestForCompleted += bestLap;
        else allHaveBest = false;
      } else if (d.active) {
        d.hasBest   = bestLap != -1;
        d.liveDelta = d.hasBest ? (liveTime - bestLap) : 0;
        d.showDelta = d.hasBest && d.liveDelta >= -5000;
      }

      @lapData[lapIdx] = d;
    }

    displayTotal   = totalRun + (isRacing ? liveTime : 0);
    hasTotal       = displayTotal > 0 || isFinished;
    showTotalDelta = hasCompletedLap && allHaveBest;
    totalDelta     = showTotalDelta ? (totalRun - bestForCompleted) : 0;
    totalColor     = GetLapDeltaColor(totalDelta, showTotalDelta);
  }

  // Computes per-cell CP display values for all lap and CP pairs.
  private void ComputeCpData(Attempt@ att) {
    numCpCols = numCps;
    if (att !is null) {
      for (int lapIdx = 1; lapIdx < int(att.laps.Length); lapIdx++) { // Laps start at 1
        Lap@ lap = att.laps[lapIdx];
        if (lap is null) continue;
        int realCps = int(lap.checkpoints.Length) - 1; // subtract phantom at [0]; CPs start at 1
        if (realCps > numCpCols) numCpCols = realCps;
      }
    }
    cpDeltaMode = cpDisplayMode != CpDisplayMode::Absolute;

    cpData.Resize(numLaps + 1); // index 0 unused; laps start at 1
    for (int lapIdx = 1; lapIdx <= numLaps; lapIdx++) {
      cpData[lapIdx].Resize(numCpCols + 1); // index 0 unused; CPs start at 1

      if (lapIdx >= int(lapData.Length)) continue;
      LapDisplayData@ ld = lapData[lapIdx];

      Lap@ lap = null;
      if (att !is null && lapIdx < int(att.laps.Length)) {
        @lap = att.GetLap(lapIdx);
      }

      for (int cpIdx = 1; cpIdx <= numCpCols; cpIdx++) { // CPs start at 1
        CpCellData@ cell = CpCellData();
        if ((ld.completed || ld.active) && lap !is null && cpIdx < int(lap.checkpoints.Length)) {
          cell.hasData = true;
          cell.cpTime  = lap.GetCheckpointTime(cpIdx);
          cell.refTime = GetCpRefTimeForIdx(lapIdx, cpIdx);
        }
        @cpData[lapIdx][cpIdx] = cell;
      }
    }
  }

  // Returns the reference CP time for a cell based on display mode.
  private int GetCpRefTimeForIdx(int lapIdx, int cpIdx) {
    if (cpDisplayMode == CpDisplayMode::DeltaPB)          return bests.GetBestSingleAttemptCpTime(lapIdx, cpIdx);
    if (cpDisplayMode == CpDisplayMode::DeltaBestLapCp)   return bests.GetBestCpByCpLapIndexTime(lapIdx, cpIdx);
    if (cpDisplayMode == CpDisplayMode::DeltaBestAllTime)  return bests.GetBestAnyCpTime(cpIdx);
    return 0;
  }

  // Returns the lap time from an attempt or -1 if unavailable.
  private int GetLapTimeFrom(Attempt@ att, int lapIdx) const {
    if (att is null) return -1;
    if (lapIdx < 0 || lapIdx >= int(att.laps.Length)) return -1;
    Lap@ lap = att.GetLap(lapIdx);
    if (numCps > 0 && int(lap.checkpoints.Length) != numCps + 1) return -1; // phantom at [0] + numCps real; CPs start at 1
    return lap.GetLapTime();
  }

}

UIState g_uiState;
