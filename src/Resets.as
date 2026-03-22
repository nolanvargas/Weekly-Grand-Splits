// Clears run data and session bests for the current map.
void ResetCommon() {
  g_state.waitForCarReset = true;
  g_state.resetData = true;
  ResetRace(null);
  g_state.bests.Clear();
  @g_state.previousAttempt = null;
}

// Clears only the current run data while keeping history and PBs.
// Called when starting a new attempt on the same map.
void ResetRace(Attempt@ previousAttemptForBests) {
  // Update best reference caches only at run boundaries.
  // This keeps UI comparisons stale during the active run.
  if (previousAttemptForBests !is null) {
    g_state.bests.UpdateFromAttempt(previousAttemptForBests);
  }

  g_state.ResetLapTimes();
  g_state.isFinished = false;
  g_state.finishRaceTime = 0;
  g_state.prevLapRaceTime = 0;
  g_state.lastCpTime = 0;

  g_state.lastCP = GetSpawnCheckpoint();
}

