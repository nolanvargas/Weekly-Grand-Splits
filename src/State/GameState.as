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

  Attempt@ currentAttempt;
  Attempt@ previousAttempt;   // holds the last attempt for faded display until the first new CP
  int currentAttemptId = 0;
  bool pendingAttemptCommenced = false;

  // True when displaying old/stale data: player is restarting with data from a previous run,
  // but no new checkpoint has arrived yet to replace it.
  bool IsStale() {
    return (resetData && hasPlayerRaced) || previousAttempt !is null;
  }

  // Returns the best attempt to read display data from: previousAttempt during the stale phase,
  // currentAttempt otherwise.
  Attempt@ GetDisplayAttempt() {
    return previousAttempt !is null ? previousAttempt : currentAttempt;
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
    HookEventPrint("Map changed: " + mapId);
    if (debugPlayerEventsDryRun) {
      pendingAttemptCommenced = false;
      currentMap = mapId;
      UpdateWaypoints();
      playerStartTime = GetPlayerStartTime();
      return;
    }
    ResetCommon();
    pendingAttemptCommenced = false;
    currentMap = mapId;
    UpdateWaypoints();
    if (isMultiLap) {
      history.LoadData(mapId);
    } else {
      history.Clear();
    }
    playerStartTime = GetPlayerStartTime();
  }

  void OnNewAttempt() {
    HookEventPrint("New attempt: " + (currentAttemptId + 1));
    if (debugPlayerEventsDryRun) return;
    previousAttempt = currentAttempt;
    //UI needs to switch to previousAttempt
    if (currentAttempt.tracked) {
      @currentAttempt = Attempt(currentAttemptId + 1, numLaps);
      bests.UpdateFromAttempt(previousAttempt, numLaps, numCps);
    }
  }

  void OnAttemptCommenced() {
    HookEventPrint("Attempt commenced: " + currentAttemptId);
    if (debugPlayerEventsDryRun) return;
    pendingAttemptCommenced = true;
  }

  void OnCheckpointReached(int cpIndex) {
    int raceTime = GetPlayerCheckpointTime();
    HookEventPrint("Checkpoint reached: " + cpIndex + " | " + raceTime + " ms");
    if (debugPlayerEventsDryRun) {
      lastCP = cpIndex;
      lastCpTime = raceTime;
      return;
    }
    //Swtich UI to currentAttempt
    //Record value in json file
    currentAttempt.tracked = true;
    lastCP = cpIndex;
    int cpDelta = raceTime - lastCpTime;
    currentAttempt.AppendCheckpointTime(currentLap, cpDelta);
    lastCpTime = raceTime;
  }

  void OnLapFinished() {
    int raceTime = GetPlayerCheckpointTime();
    int lapDelta = raceTime - prevLapRaceTime;
    HookEventPrint("Lap finished: " + currentLap + " | total " + raceTime + " ms | lap " + lapDelta + " ms");
    if (debugPlayerEventsDryRun) {
      lastCP = GetCurrentCheckpoint();
      lastCpTime = raceTime;
      prevLapRaceTime = raceTime;
      currentLap = currentLap + 1;
      return;
    }
    // record value in json file
    int finishSegment = raceTime - lastCpTime;
    currentAttempt.AppendCheckpointTime(currentLap, finishSegment);
    lastCP = GetCurrentCheckpoint();
    lastCpTime = raceTime;
    prevLapRaceTime = raceTime;
    currentLap = currentLap + 1;
  }

  void OnAttemptComplete() {
    int raceTime = GetPlayerCheckpointTime();
    HookEventPrint("Attempt complete: " + raceTime + " ms");
    if (debugPlayerEventsDryRun) return;
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
    resetData = true;
    isFinished = true;
    finishRaceTime = raceTime;
  }
}

GameState g_state;
