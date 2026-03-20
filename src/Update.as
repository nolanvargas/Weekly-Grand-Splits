void Update(float dt) {

  string mapId = GetMapId();

  if (g_state.currentMap != mapId) { // Map_Changed
    g_state.OnMapChanged(mapId);
  }
  if (!g_state.isMultiLap) return;

  if (g_state.waitForCarReset) {
    // Player not in the car yet
    if (!debugPlayerEventsDryRun) PrintOnce("Waiting for spawn");
    g_state.waitForCarReset = !IsPlayerReady(); // Check this works
    return;
  }

  if (g_state.resetData) {
    if (!debugPlayerEventsDryRun) PrintOnce("Restarting...");
    if (IsPlayerReady()) {
      g_state.OnAttemptCommenced();

      if (debugPlayerEventsDryRun) {
        ApplyDryRunRestartSync();
      } else {
        Attempt@ attemptForBests = TryArchivePreviousAttemptForRestart();
        ResetRace(attemptForBests);
      }
      g_state.resetData = false;

      g_state.playerStartTime = GetActualPlayerStartTime();
      g_state.OnNewAttempt();

    }
    return;
  } else {
    if (!IsPlayerReady()) {
      if (!debugPlayerEventsDryRun) PrintOnce("Player retrying");
      g_state.resetData = true;
      return;
    }
  }


  int cp = GetCurrentCheckpoint();

  if (cp != g_state.lastCP) {
    if (IsWaypointFinish(cp)) {
      g_state.OnLapFinished();
    } else {
      g_state.OnCheckpointReached(cp);
    }
    if (g_state.currentLap == g_state.numLaps) {
      g_state.OnAttemptComplete();
    }
  }
  if (!debugPlayerEventsDryRun) PersistCurrentRun();
}
