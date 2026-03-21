class GameState {

  // Map/config
  string currentMap = "";
  int numCps = 0;
  int numLaps = 1;
  RaceHistory history;
  Bests bests;
  bool isMultiLap = false;

  // Race state
  // Lap index passed to Attempt.AppendCheckpointTime (0-based). Only OnLapFinished advances it
  // after the closing split is written; intermediate checkpoints keep the same index.
  int currentLap = 0;
  bool waitForCarReset = true;   // True while waiting for the player to respawn at start.
  bool resetData = true;         // Flag indicating that run data should be reset on next update.
  bool isFinished = false;       // True once the current run has been completed.
  bool hasPlayerRaced = false;   // True once player reached at least first checkpoint of lap 1.
  int prevLapRaceTime = 0;       // Race timer value at the end of the previous lap.
  int lastCpTime = 0;            // Race timer value when the last checkpoint was recorded.
  int finishRaceTime = 0;       // Race timer value at which the current run finished.
  int playerStartTime = -1;     // Absolute game time (ms) when current run started; -1 unknown.
  int lastCP = 0;               // Index of the last checkpoint the player triggered.
  bool waitingForStart = false;  // True when Player is awaiting at start line (~1500 ms).

  Attempt@ currentAttempt;
  Attempt@ previousAttempt;   // holds the last attempt for faded display until the first new CP
  int currentAttemptId = 0;
  bool pendingAttemptCommenced = false;
  bool pendingWaypointUpdate = false;

  // True when displaying old/stale data: player is restarting with data from a previous run,
  // but no new checkpoint has arrived yet to replace it.
  bool IsStale() {
    bool stale = (resetData && hasPlayerRaced) || previousAttempt !is null;
    return stale;
  }

  // Like GetLapTime but falls back to previousAttempt when present.
  int GetDisplayLapTime(int idx) const {
    Attempt@ src = previousAttempt !is null ? previousAttempt : currentAttempt;
    if (src is null || idx < 0 || idx >= int(src.laps.Length)) return -1;
    Lap@ lap = src.GetLap(idx);
    int expectedCpCount = numCps;
    if (expectedCpCount > 0 && int(lap.checkpoints.Length) != expectedCpCount) return -1;
    return lap.GetLapTime();
  }

  // Constructor
  GameState() {
    history = RaceHistory();
    bests = Bests();
  }

  // --- Player event hooks ---

  void OnMapChanged(const string &in mapId) {
    LogEventMap("Map changed: " + mapId);
    ResetCommon();
    pendingAttemptCommenced = false;
    currentMap = mapId;
    if (mapId != "") {
      pendingWaypointUpdate = true;
      TryCompleteWaypointUpdate();
      playerStartTime = GetPlayerStartTime();
    }
  }

  void onMapLeave() {
    LogEventMap("Map left");
    pendingAttemptCommenced = false;
    waitForCarReset = true;
    waitingForStart = false;
    currentMap = "";
  }

  // Called immediately on map change and retried each frame until playground is ready.
  void TryCompleteWaypointUpdate() {
    if (!pendingWaypointUpdate) return;
    if (GetPlayground() is null) return;
    UpdateWaypoints();
    pendingWaypointUpdate = false;
    if (isMultiLap) {
      history.LoadData(currentMap);
    } else {
      history.Clear();
    }
    g_uiState.OnReset();
  }

  void OnNewAttempt() {
    LogEventRace("OnNewAttempt");
    currentLap = 0;
    waitingForStart = true;
    isFinished = false;
    currentAttemptId++;
    g_state.resetData = true;

    // @previousAttempt = currentAttempt;
    // g_uiState.OnNewAttempt(previousAttempt);
    // If plugin was loaded mid-run, this would make currentAttempt null
    // if (currentAttempt is null) {
    //   @currentAttempt = Attempt(currentAttemptId, numLaps);
    // } else if (currentAttempt.tracked) {
    //   @currentAttempt = Attempt(currentAttemptId + 1, numLaps);
    //   bests.UpdateFromAttempt(previousAttempt);
    // }
  }

  void OnAttemptCommenced() {
    LogEventRace("OnAttemptCommenced");
    currentLap = 1;
    pendingAttemptCommenced = true;
    waitingForStart = false;
    lastCP = GetCurrentCheckpoint();
  }

  void OnCheckpointReached(int cpIndex) {
    // -1 when menu UI appears after race completion, so ignore it.
    if (cpIndex == -1) { return; }

    lastCP = cpIndex;
    int raceTime = GetPlayerCheckpointTime();
    LogEventRace("OnCheckpointReached");
    if (currentAttempt is null) {
      LogWarn("OnCheckpointReached: currentAttempt is null at cp=" + cpIndex + ", skipping record");
      return;
    }
    g_uiState.OnCheckpointReached(currentAttempt);
    currentAttempt.tracked = true;
    int cpDelta = raceTime - lastCpTime;
    currentAttempt.AppendCheckpointTime(currentLap, cpDelta);
    lastCpTime = raceTime;
  }

  void OnLapFinished() {
    LogEventRace("OnLapFinished");
    currentLap++;
    if (currentLap > numLaps) {
      OnAttemptComplete();
      return;
    }
    // check for attempt complete
    lastCP = GetCurrentCheckpoint();
    int raceTime = GetPlayerCheckpointTime();
    int lapDelta = raceTime - prevLapRaceTime;
    if (currentAttempt is null) {
      LogWarn("OnLapFinished: currentAttempt is null at lap=" + currentLap + ", skipping record");
      return;
    }
    int finishSegment = raceTime - lastCpTime;
    currentAttempt.AppendCheckpointTime(currentLap, finishSegment);
    lastCpTime = raceTime;
    prevLapRaceTime = raceTime;
  }

  void OnAttemptComplete() {
    LogEventRace("OnAttemptComplete");
    if (isFinished) return;
    isFinished = true;
    pendingAttemptCommenced = false;
    waitForCarReset = true;
    return;
    int raceTime = GetPlayerCheckpointTime();
    CompleteRun(raceTime);
  }

  void ClearPreviousOnCheckpointCrossing() {
    @previousAttempt = null;
  }

  // Current run CP splits
  // Attempt-backed helpers for current run splits.

  // Lap time accessors backed by the current Attempt.
  int GetLapTime(int idx) const {
    if (currentAttempt is null) return -1;
    if (idx < 0 || idx >= int(currentAttempt.laps.Length)) return -1;
    Lap@ lap = currentAttempt.GetLap(idx);
    int expectedCpCount = numCps;
    if (expectedCpCount > 0 && int(lap.checkpoints.Length) != expectedCpCount) return -1;
    return lap.GetLapTime();
  }
  
  void ResetLapTimes() {
    @currentAttempt = null;
  }


  void CompleteRun(int raceTime) {
    waitForCarReset = true;
    // resetData = true;
    isFinished = true;
    finishRaceTime = raceTime;
    pendingAttemptCommenced = false;
  }
}

GameState g_state;
