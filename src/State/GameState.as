class GameState {

  // Map/config
  string currentMap = "";
  int numCps = 0;
  int numLaps = 1;
  RaceHistory history;
  Bests bests;
  bool isMultiLap = false;

  // Race state
  int currentLap = 0;             // Index of the lap the player is currently on (0-based).
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
  int currentAttemptId = 0;

  // Constructor
  GameState() {
    history = RaceHistory();
    bests = Bests();
    @currentAttempt = Attempt();
  }

  // Current run CP splits
  // Attempt-backed helpers for current run splits.

  // Lap time accessors backed by the current Attempt.
  int GetLapTime(int idx) const {
    if (idx < 0 || idx >= int(currentAttempt.LapCount)) return -1;
    Lap@ lap = currentAttempt.GetLap(idx);
    int n = numCps;
    if (n > 0 && int(lap.CheckpointCount) < n) return -1;
    int t = lap.LapTime;
    return (t > 0) ? t : -1;
  }
  
  void ResetLapTimes() {
    @currentAttempt = Attempt();
  }

  void RecordCheckpoint(int cpIndex, int raceTime) {
    lastCP = cpIndex;
    int deltaTime = raceTime - prevLapRaceTime;
    if (raceTime <= 0 || deltaTime <= 0) {
      waitForCarReset = true;
      return;
    }
    int cpDelta = raceTime - lastCpTime;
    if (cpDelta > 0) {
      // Actions: append a CP split when the time has advanced since the previous CP.
      // We derive the next sequential CP index from the current Lap checkpoint count.
      if (currentAttempt !is null) {
        int lapIdx = currentLap;
        int cpIdx = 0;
        if (lapIdx >= 0 && lapIdx < int(currentAttempt.LapCount)) {
          Lap@ lap = currentAttempt.GetLap(lapIdx);
          cpIdx = int(lap.CheckpointCount);
        }
        if (lapIdx >= 0) currentAttempt.SetCheckpointTime(lapIdx, cpIdx, cpDelta);

        // Actions: once the player records the first checkpoint of lap 1,
        // flag that this attempt is now valid and should be archived when it finishes.
        if (lapIdx == 0 && cpIdx == 0) hasPlayerRaced = true;
      }
    }
    lastCpTime = raceTime;
  }

  void CompleteLap(int lapTime, int raceTime) {
    prevLapRaceTime = raceTime;
    int idx = currentLap;
    if (idx < 0 || idx >= MAX_LAPS) return;
  }

  void CompleteRun(int raceTime) {
    currentLap = currentLap + 1;
    waitForCarReset = true;
    resetData = true;
    isFinished = true;
    finishRaceTime = raceTime;
  }
}

GameState g_state;
