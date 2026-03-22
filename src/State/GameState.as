class GameState {

  // Map/config
  string currentMap = "";
  int numCps = 0;
  int numLaps = 1;
  RaceHistory history;
  Bests@ bests;
  bool isMultiLap = false;

  // Race state
  // Lap index passed to Attempt.AppendCheckpointTime (0-based). Only OnLapFinished advances it
  // after the closing split is written; intermediate checkpoints keep the same index.
  int currentLap = 0;
  bool waitForCarReset = true;   // True while waiting for the player to respawn at start.
  bool resetData = true;         // Flag indicating that run data should be reset on next update.
  bool isFinished = false;       // True once the current run has been completed.
  int prevLapRaceTime = 0;       // Race timer value at the end of the previous lap.
  int lastCpTime = 0;            // Race timer value when the last checkpoint was recorded.
  int finishRaceTime = 0;       // Race timer value at which the current run finished.
  int playerStartTime = -1;     // Absolute game time (ms) when current run started; -1 unknown.
  int lastCP = 0;               // Index of the last checkpoint the player triggered.
  bool waitingForStart = false;  // True when Player is awaiting at start line (~1500 ms).
  bool notInMultiLapMap = false;          // True if player is not in a multi-lap map.

  Attempt@ currentAttempt;
  Attempt@ previousAttempt;   // holds the last attempt for faded display until the first new CP
  int currentAttemptId = 0;
  bool pendingAttemptCommenced = false;
  bool pendingWaypointUpdate = false;

  // True when displaying old/stale data: player is restarting with data from a previous run,
  // but no new checkpoint has arrived yet to replace it.
  bool IsStale() {
    bool stale = resetData || previousAttempt !is null;
    return stale;
  }

  // Constructor
  GameState() {
    history = RaceHistory();
    @bests = Bests();
  }

  // --- Player event hooks ---

  void OnMapChanged(const string &in mapId) {
    LogEventPlayer("Map changed: " + mapId);
    ResetCommon();
    pendingAttemptCommenced = false;
    currentMap = mapId;
    if (mapId != "") {
      notInMultiLapMap = true;
      pendingWaypointUpdate = true;
      TryCompleteWaypointUpdate();
      playerStartTime = GetPlayerStartTime();
    }
  }

  void onMapLeave() {
    LogEventPlayer("Map left");
    pendingAttemptCommenced = false;
    waitForCarReset = true;
    waitingForStart = false;
    currentMap = "";
    notInMultiLapMap = true;
  }

  // Called immediately on map change and retried each frame until playground is ready.
  void TryCompleteWaypointUpdate() {
    if (!pendingWaypointUpdate) return;
    if (GetPlayground() is null) return;
    UpdateWaypoints();
    pendingWaypointUpdate = false;
    if (isMultiLap) {
      history.LoadData(currentMap);
      currentAttemptId = history.ComputeNextAttemptId();
    } else {
      history.Clear();
    }
    g_uiState.OnReset();
    LogEventPlayer("Checkpoints: " + numCps + ", Laps: " + numLaps);
  }

  void OnNewAttempt() {
    LogEventPlayer("New attempt started");
    currentLap = 0;
    waitingForStart = true;
    isFinished = false;
    currentAttemptId++;
    g_state.resetData = true;

    @previousAttempt = currentAttempt;
    bests.ComputeFromHistory(history, numLaps, numCps);
    g_uiState.OnNewAttempt(previousAttempt);
    @currentAttempt = Attempt(currentAttemptId, numLaps);
  }

  void OnAttemptCommenced() {
    LogEventPlayer("Attempt commenced");
    currentLap = 1;
    pendingAttemptCommenced = true;
    waitingForStart = false;
    lastCpTime = 0;
    prevLapRaceTime = 0;
    lastCP = GetCurrentCheckpoint();
  }

  void OnCheckpointReached(int cpIndex) {
    // -1 when menu UI appears after race completion, so ignore it.
    if (cpIndex == -1) { return; }
    LogEventPlayer("Checkpoint reached");

    lastCP = cpIndex;
    int raceTime = GetPlayerCheckpointTime();
    if (currentAttempt is null) {
      LogEventPlayer("Checkpoint reached: " + cpIndex + " (no active attempt)");
      return;
    }
    ClearPreviousOnCheckpointCrossing();
    g_uiState.OnCheckpointReached(currentAttempt);
    int cpDelta = raceTime - lastCpTime;
    currentAttempt.AppendCheckpointTime(currentLap, cpDelta);
    lastCpTime = raceTime;
  }

  void OnLapFinished() {
    LogEventPlayer("Lap finished");
    lastCP = GetCurrentCheckpoint();
    int raceTime = GetPlayerCheckpointTime();
    int finishSegment = raceTime - lastCpTime;
    lastCpTime = raceTime;
    prevLapRaceTime = raceTime;
    if (currentAttempt !is null) {
      currentAttempt.AppendCheckpointTime(currentLap, finishSegment);
    }
    currentLap++;
    if (currentLap > numLaps) {
      OnAttemptComplete();
    }
  }

  void OnAttemptComplete() {
    LogEventPlayer("Attempt completed");
    if (isFinished) return;
    isFinished = true;
    pendingAttemptCommenced = false;
    waitForCarReset = true;
    int raceTime = GetPlayerCheckpointTime();
    CompleteRun(raceTime);
  }

  void ClearPreviousOnCheckpointCrossing() {
    @previousAttempt = null;
  }

  void ResetLapTimes() {
    @currentAttempt = null;
  }


  void CompleteRun(int raceTime) {
    finishRaceTime = raceTime;
    ArchiveCurrentAttempt();
    g_state.history.SaveData();
  }
}

GameState g_state;
