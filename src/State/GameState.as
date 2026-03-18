// High-level orchestrator for race configuration, run state, and metrics/history.
// Exposes a backwards-compatible facade (g_state) used throughout the plugin.
class GameState {
  // Configuration and mode.
  RaceConfig config;
  bool isMultiLap {
    get const { return config.get_IsMultiLap(); }
    set { config.set_IsMultiLap(value); }
  }

  // Transient run state.
  RunState run;

  // Lap-level metrics for the current run and PB run.
  LapTimeSeries lapTimes;       // current run lap totals
  LapTimeSeries bestLapTimes;   // best per-lap times for PB

  // PB attempt splits and best-ever metrics across all attempts.
  array<array<int>> bestLapCpTimes; // [lap][cp] splits from the PB run

  RaceHistory history;
  Bests bests; // Derived best/reference baselines computed from archived attempts.

  // Attempt tracking.
  int currentAttemptId = 0;
  Attempt@ currentAttempt;

  GameState() {
    config = RaceConfig();
    history = RaceHistory();
    bests = Bests();
  }

  RaceHistory@ GetHistory() {
    return history;
  }

  Bests@ GetBests() {
    return bests;
  }

  // --- Backwards-compatible field-style accessors used throughout the codebase ---

  // Map / config facade
  string get_currentMap() const { return config.get_MapId(); }
  void set_currentMap(const string &in v) { config.set_MapId(v); }

  int get_numCps() const { return config.get_NumCps(); }
  void set_numCps(int v) { config.set_NumCps(v); }

  int get_numLaps() const { return config.get_NumLaps(); }
  void set_numLaps(int v) { config.set_NumLaps(v); }

  int get_currentLap() const { return run.currentLap; }
  void set_currentLap(int v) { run.currentLap = Math::Clamp(v, 0, MAX_LAPS); }

  // Flags and transient state (delegated to RunState)
  bool get_waitForCarReset() const { return run.waitForCarReset; }
  void set_waitForCarReset(bool v) { run.waitForCarReset = v; }

  bool get_resetData() const { return run.resetData; }
  void set_resetData(bool v) { run.resetData = v; }

  bool get_isFinished() const { return run.isFinished; }
  void set_isFinished(bool v) { run.isFinished = v; }

  bool get_hasFinishedMap() const { return run.hasFinishedMap; }
  void set_hasFinishedMap(bool v) { run.hasFinishedMap = v; }

  bool get_hasPlayerRaced() const { return run.hasPlayerRaced; }
  void set_hasPlayerRaced(bool v) { run.hasPlayerRaced = v; }

  int get_prevLapRaceTime() const { return run.prevLapRaceTime; }
  void set_prevLapRaceTime(int v) { run.prevLapRaceTime = v; }

  int get_lastCpTime() const { return run.lastCpTime; }
  void set_lastCpTime(int v) { run.lastCpTime = v; }

  int get_finishRaceTime() const { return run.finishRaceTime; }
  void set_finishRaceTime(int v) { run.finishRaceTime = v; }

  int get_playerStartTime() const { return run.playerStartTime; }
  void set_playerStartTime(int v) { run.playerStartTime = v; }

  int get_lastCP() const { return run.lastCP; }
  void set_lastCP(int v) { run.lastCP = v; }

  // Current run CP splits
  int[]@ get_currLapCpTimes() { return run.currLapCpTimes; }
  void set_currLapCpTimes(const int[] &in v) {
    run.currLapCpTimes.RemoveRange(0, run.currLapCpTimes.Length);
    for (uint i = 0; i < v.Length; i++) run.currLapCpTimes.InsertLast(v[i]);
    // Actions: rebuild the current lap CP list from the provided array so it exactly mirrors the serialized data.
  }

  array<array<int>>@ get_allLapCpTimes() { return run.allLapCpTimes; }
  void set_allLapCpTimes(const array<array<int>> &in v) {
    run.allLapCpTimes = v;
  }

  // Attempt-backed helpers for current run splits.
  Attempt@ GetCurrentAttempt() const { return currentAttempt; }

  array<array<int>> GetCurrentAttemptLapCpTimes() const {
    if (currentAttempt is null) {
      return run.allLapCpTimes;
    }
    return currentAttempt.ToLapCpArray();
  }

  // Best-ever CP times are stored in history.
  array<array<int>>@ get_bestAllTimeCpTimes() { return history.GetBestAllTimeCpTimes(); }
  void set_bestAllTimeCpTimes(const array<array<int>> &in v) {
    auto @dest = history.GetBestAllTimeCpTimes();
    dest.RemoveRange(0, dest.Length);
    for (uint i = 0; i < v.Length; i++) {
      dest.InsertLast(v[i]);
    }
  }

  // Legacy lap array-style accessors backed by LapTimeSeries.
  int GetLapTime(int idx) const {
    return lapTimes.Get(idx);
  }
  void SetLapTime(int idx, int time) {
    lapTimes.Set(idx, time);
  }
  void ResetLapTimes() {
    lapTimes.Reset(-1);
  }

  int GetBestLapTime(int idx) const {
    return bestLapTimes.Get(idx);
  }
  void SetBestLapTime(int idx, int time) {
    bestLapTimes.Set(idx, time);
  }
  void ResetBestLapTimes() {
    bestLapTimes.Reset(-1);
  }

  int GetBestAllTimeLapTime(int idx) const {
    return history.GetBestAllTimeLapTotal(idx);
  }
  void SetBestAllTimeLapTime(int idx, int time) {
    history.SetBestAllTimeLapTotal(idx, time);
  }
  void ResetBestAllTimeLapTimes() {
    for (int i = 0; i < MAX_LAPS; i++) history.SetBestAllTimeLapTotal(i, 0);
  }

  // Higher-level façade API for race lifecycle.

  void ConfigureRace(const string &in mapId, int numLaps, int numCps, bool isMultiLapRace) {
    config.Configure(mapId, numLaps, numCps, isMultiLapRace);
  }

  void StartAttempt(int attemptId, int startTime, int spawnCp) {
    currentAttemptId = attemptId;
    @currentAttempt = Attempt();
    currentAttempt.id = currentAttemptId;
    run.ResetForNewRun();
    run.playerStartTime = startTime;
    run.lastCP = spawnCp;
    run.waitForCarReset = false;
    run.resetData = false;
    run.hasPlayerRaced = false;
    run.isFinished = false;
  }

  void RecordCheckpoint(int cpIndex, int raceTime) {
    run.lastCP = cpIndex;
    int deltaTime = raceTime - run.prevLapRaceTime;
    if (raceTime <= 0 || deltaTime <= 0) {
      // Actions: when the CP time or lap delta is non-positive, treat the run as invalid and force a reset rather than recording bogus splits.
      run.waitForCarReset = true;
      return;
    }
    int cpDelta = raceTime - run.lastCpTime;
    if (cpDelta > 0) {
      // Actions: only append a CP split when the time has advanced since the previous CP, then update the best-ever metrics for that position.
      run.currLapCpTimes.InsertLast(cpDelta);
      // Mirror into the current Attempt model if available.
      if (currentAttempt !is null) {
        int lapIdx = run.currentLap;
        int cpIdx = int(run.currLapCpTimes.Length) - 1;
        if (lapIdx >= 0) {
          currentAttempt.SetCheckpointTime(lapIdx, cpIdx, cpDelta);
        }
      }
      if (run.currentLap == 0 && run.currLapCpTimes.Length == 1) {
        // Actions: once the player reaches the first checkpoint of lap 1,
        // flag that this attempt is now valid and should be archived
        // when it finishes.
        run.hasPlayerRaced = true;
      }
      int cpIdx = int(run.currLapCpTimes.Length) - 1;
      GetHistory().UpdateCpBest(run.currentLap, cpIdx, cpDelta);
    }
    run.lastCpTime = raceTime;
  }

  void CompleteLap(int lapTime, int raceTime) {
    run.prevLapRaceTime = raceTime;
    int idx = run.currentLap;
    if (idx < 0 || idx >= MAX_LAPS) return;
    // Actions: guard against out-of-range lap indices so we do not write beyond the fixed-size lap arrays.
    SetLapTime(idx, lapTime);
    if (GetBestAllTimeLapTime(idx) == 0 || lapTime < GetBestAllTimeLapTime(idx)) {
      // Actions: whenever this lap time beats the stored all-time best (or no best exists), update the best-total record for that lap.
      SetBestAllTimeLapTime(idx, lapTime);
    }
    SaveLapCpTimes(idx);
    run.currLapCpTimes.RemoveRange(0, run.currLapCpTimes.Length);
  }

  void CompleteRun(int raceTime) {
    run.hasFinishedMap = true;
    run.currentLap = run.currentLap + 1;
    run.waitForCarReset = true;
    run.resetData = true;
    run.isFinished = true;
    run.finishRaceTime = raceTime;
  }
}

GameState g_state;
