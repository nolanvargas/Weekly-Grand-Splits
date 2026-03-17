class GameState {
  // --- Map ---
  string currentMap;
  bool isMultiLap = false;

  private int _numCps = 0;
  private int _numLaps = 1;

  int get_numCps() { return _numCps; }
  void set_numCps(int v) { _numCps = Math::Max(0, v); }

  int get_numLaps() { return _numLaps; }
  void set_numLaps(int v) { _numLaps = Math::Max(1, v); }

  // --- Race position ---
  private int _currentLap = 0;

  int get_currentLap() { return _currentLap; }
  void set_currentLap(int v) { _currentLap = Math::Clamp(v, 0, MAX_LAPS); }

  // --- Race flags ---
  bool waitForCarReset = true;
  bool resetData = true;
  bool isFinished = false;
  bool hasFinishedMap = false;
  bool hasPlayerRaced = false;

  // --- Timing ---
  int prevLapRaceTime = 0;
  int lastCpTime = 0;
  int finishRaceTime = 0;
  int playerStartTime = -1;
  int lastCP = 0;

  // --- Current run ---
  // lapTimes: -1 = not yet completed for that lap
  int[] lapTimes = {-1,-1,-1,-1,-1,-1,-1,-1,-1,-1};
  int[] currLapCpTimes;
  array<array<int>> allLapCpTimes; // [lap][cp] splits for the current run

  int GetLapTime(int idx) {
    if (idx < 0 || idx >= MAX_LAPS) return -1;
    return lapTimes[idx];
  }
  void SetLapTime(int idx, int time) {
    if (idx < 0 || idx >= MAX_LAPS) return;
    lapTimes[idx] = time;
  }
  void ResetLapTimes() {
    for (int i = 0; i < MAX_LAPS; i++) lapTimes[i] = -1;
  }

  // --- Session bests (from PB run) ---
  // bestLapTimes: -1 = no data
  int[] bestLapTimes = {-1,-1,-1,-1,-1,-1,-1,-1,-1,-1};
  array<array<int>> bestLapCpTimes; // [lap][cp] splits from the PB run

  int GetBestLapTime(int idx) {
    if (idx < 0 || idx >= MAX_LAPS) return -1;
    return bestLapTimes[idx];
  }
  void SetBestLapTime(int idx, int time) {
    if (idx < 0 || idx >= MAX_LAPS) return;
    bestLapTimes[idx] = time;
  }
  void ResetBestLapTimes() {
    for (int i = 0; i < MAX_LAPS; i++) bestLapTimes[i] = -1;
  }

  // --- All-time bests ---
  // bestAllTimeLapTimes: 0 = no data
  int[] bestAllTimeLapTimes = {0,0,0,0,0,0,0,0,0,0};
  array<array<int>> bestAllTimeCpTimes; // [lap][cp] best individual CP times ever

  int GetBestAllTimeLapTime(int idx) {
    if (idx < 0 || idx >= MAX_LAPS) return 0;
    return bestAllTimeLapTimes[idx];
  }
  void SetBestAllTimeLapTime(int idx, int time) {
    if (idx < 0 || idx >= MAX_LAPS) return;
    bestAllTimeLapTimes[idx] = Math::Max(0, time);
  }
  void ResetBestAllTimeLapTimes() {
    for (int i = 0; i < MAX_LAPS; i++) bestAllTimeLapTimes[i] = 0;
  }

  // --- Attempt history ---
  int currentAttemptId = 0;
  int pbAttemptId = -1;                       // attempt_id of the current PB run
  array<array<array<int>>> allAttempts;        // [attempt][lap][cp]
  array<int> allAttemptIds;                   // parallel attempt ID list

  // --- Font ---
  string loadedFontFace = "";
  int loadedFontSize = 0;
  UI::Font@ font = null;
}

GameState g_state;

void debugText(const string&in text) {
  // print(text);
}
