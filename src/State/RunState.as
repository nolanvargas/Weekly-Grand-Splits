// Transient state for a single running attempt.
// This holds only per-run fields; configuration and history live elsewhere.
class RunState {
  int currentLap = 0;         // Index of the lap the player is currently on (0-based).
  bool waitForCarReset = true; // True while we are waiting for the player to respawn at start before timing resumes.
  bool resetData = true;       // Flag indicating that run data should be fully reset on the next update when the player is ready.
  bool isFinished = false;     // True once the current run has been completed and no further timing should occur.
  bool hasFinishedMap = false; // True if the player has ever completed this map in this session.
  bool hasPlayerRaced = false; // True once the player has reached at least the first checkpoint of lap 1 in a run on this map.
  int prevLapRaceTime = 0;     // Race timer value at the end of the previous lap (used as the start time for the current lap).
  int lastCpTime = 0;          // Race timer value when the last checkpoint was recorded.
  int finishRaceTime = 0;      // Race timer value at which the current run finished.
  int playerStartTime = -1;    // Absolute game time (ms) when the current run started; -1 means unknown/not yet set.
  int lastCP = 0;              // Index of the last checkpoint (landmark) the player triggered.

  // Current lap CP splits and all completed laps for this run.
  int[] currLapCpTimes;
  array<array<int>> allLapCpTimes; // [lap][cp]

  // Resets all transient fields so a new attempt can start on the same map.
  void ResetForNewRun() {
    currentLap = 0;
    isFinished = false;
    hasPlayerRaced = false;
    prevLapRaceTime = 0;
    lastCpTime = 0;
    finishRaceTime = 0;
    currLapCpTimes.RemoveRange(0, currLapCpTimes.Length);
    allLapCpTimes.RemoveRange(0, allLapCpTimes.Length);
  }
}