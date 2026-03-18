// Clears run data and session bests for the current map.
void ResetCommon() {
  g_state.waitForCarReset = true;
  ResetRace();
  g_state.ResetBestLapTimes();
  g_state.bestLapCpTimes = {};
  g_state.bestAllTimeCpTimes = {};
  g_state.ResetBestAllTimeLapTimes();
  g_state.bests.Clear();

  g_state.hasFinishedMap = false;
  g_state.hasPlayerRaced = false;
}

// Clears only the current run data while keeping history and PBs.
// Called when starting a new attempt on the same map.
void ResetRace() {
  g_state.ResetLapTimes();
  g_state.set_isFinished(false);
  g_state.set_currentLap(0);
  g_state.set_finishRaceTime(0);
  g_state.set_prevLapRaceTime(0);
  g_state.set_lastCpTime(0);
  g_state.currLapCpTimes = {};
  g_state.allLapCpTimes = {};

#if TMNEXT
    // on TMNEXT, initialize the last checkpoint index to the player's spawn CP so 
    // future CP changes are detected correctly.
    g_state.lastCP = GetSpawnCheckpoint();
#endif
}
