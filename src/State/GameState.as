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

  // Returns true when the UI is displaying data from a previous run.
  bool IsStale() {
    bool stale = resetData || previousAttempt !is null;
    return stale;
  }

  // Constructs a GameState and initializes the history and bests objects.
  GameState() {
    history = RaceHistory();
    @bests = Bests();
  }

  // --- Player event hooks ---

  // Handles map change by resetting state and triggering waypoint update.
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

  // Handles map exit by clearing the current map and race state.
  void OnMapLeave() {
    LogEventPlayer("Map left");
    pendingAttemptCommenced = false;
    waitForCarReset = true;
    waitingForStart = false;
    currentMap = "";
    notInMultiLapMap = true;
  }

  // Completes the pending waypoint update once the playground is ready.
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

  // Resets per-run state and saves the previous attempt for display.
  void OnNewAttempt() {
    LogEventPlayer("New attempt started");
    currentLap = 0;
    waitingForStart = true;
    isFinished = false;
    currentAttemptId++;
    g_state.resetData = true;

    // no need to persist the previous attempt if it has no checkpoints
    if (currentAttempt !is null && currentAttempt.HasAnyCheckpoints()) {
      @previousAttempt = currentAttempt;
      bests.ComputeFromHistory(history, numLaps, numCps);
    }
    g_uiState.OnNewAttempt(previousAttempt);
    @currentAttempt = Attempt(currentAttemptId, numLaps);
  }

  // Fires when the player leaves the start line to begin racing.
  void OnAttemptCommenced() {
    LogEventPlayer("Attempt commenced");
    currentLap = 1;
    pendingAttemptCommenced = true;
    waitingForStart = false;
    lastCpTime = 0;
    prevLapRaceTime = 0;
    lastCP = GetCurrentCheckpoint();
  }

  // Records a checkpoint split and clears the stale display flag.
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

  // Records the closing split for a lap and advances the counter.
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

  // Fires when all laps are done, archiving and flagging the run complete.
  void OnAttemptComplete() {
    LogEventPlayer("Attempt completed");
    if (isFinished) return;
    isFinished = true;
    pendingAttemptCommenced = false;
    waitForCarReset = true;
    int raceTime = GetPlayerCheckpointTime();
    CompleteRun(raceTime);
  }

  // Clears the previous attempt reference when a checkpoint is crossed.
  void ClearPreviousOnCheckpointCrossing() {
    @previousAttempt = null;
  }

  // Nulls the current attempt reference, discarding any unsaved lap data.
  void ResetLapTimes() {
    @currentAttempt = null;
  }

  // Saves the finish time and archives the completed run to history.
  void CompleteRun(int raceTime) {
    finishRaceTime = raceTime;
    ArchiveCurrentAttempt();
    g_state.history.SaveData();
  }
}

GameState g_state;
