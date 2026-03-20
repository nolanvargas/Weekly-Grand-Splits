string g_lastPrint = "";

void PrintOnce(const string&in msg) {
  if (!debugPrintEvents || msg == g_lastPrint) return;
  g_lastPrint = msg;
  print(msg);
}

void Update(float dt) {

  string mapId = GetMapId();
  if (g_state.currentMap != mapId) {
    g_state.currentMap = "";
    ResetCommon();

    if (g_state.currentMap == "" || mapId == "") {
      PrintOnce("Map loaded: " + mapId);
      g_state.playerStartTime = GetPlayerStartTime();
      g_state.currentMap = mapId;
      UpdateWaypoints();
      if (g_state.isMultiLap) {
        LoadData();
      } else {
        InitEmptyState();
      }
    }
  }

  if (g_state.waitForCarReset) {
    PrintOnce("Waiting for respawn...");
    // keep waiting, updating the flag when the race timer is valid
#if TMNEXT
    g_state.waitForCarReset = GetCurrentPlayerRaceTime() >= 0;
#endif
    return;
  }

  if (g_state.resetData) {
    PrintOnce("Restarting...");
    if (IsPlayerReady()) {
      PrintOnce("At start line");
      // archive the just-finished attempt, fully reset run state, then clear the flag
      Attempt@ attemptForBests = null;
      if (g_state.hasPlayerRaced) { // first CP of lap 1 reached
        @g_state.staleAttempt = g_state.currentAttempt; // keep for faded display until first new CP
        attemptForBests = ArchiveCurrentAttempt();
        g_state.currentAttemptId++;
        g_state.hasPlayerRaced = false; // reset flag until the next attempt crosses CP1
        PrintOnce("Attempt saved");
      }

      ResetRace(attemptForBests);
      g_state.resetData = false;

      g_state.playerStartTime = GetActualPlayerStartTime();

      if (g_state.numCps <= 1) {
        UpdateWaypoints();
        if (g_state.isMultiLap) {
          LoadData();
        }
      }

      SaveData();

    }
    return;
  } else {
    if (!IsPlayerReady()) {
      PrintOnce("Left start / respawning...");
      g_state.resetData = true;
      return;
    }
  }

  if (!g_state.isMultiLap) return;

  int cp = GetCurrentCheckpoint();

  if (cp != g_state.lastCP) {
    // checkpoint crossed — clear stale display unconditionally on any CP event
    @g_state.staleAttempt = null;
    int raceTime = GetPlayerCheckpointTime();
    PrintOnce("CP " + cp + " | " + raceTime + " ms");
    g_state.RecordCheckpoint(cp, raceTime);
    if (raceTime <= 0 || raceTime - g_state.prevLapRaceTime <= 0) {
      PrintOnce("Respawn detected at cp=" + cp);
      return;
    }

    if (IsWaypointFinish(cp)) {
      // compute the lap delta from the previous lap start
      int deltaTime = raceTime - g_state.prevLapRaceTime;
      // finalize lap metrics for the current lap (single-lap and multi-lap alike)
      g_state.CompleteLap(deltaTime, raceTime);
      PrintOnce("Lap " + (g_state.currentLap + 1) + " | " + deltaTime + " ms");
    }

#if TMNEXT
    if (IsWaypointFinish(cp)) {   // lap finished
#endif
      g_state.currentLap = g_state.currentLap + 1;
#if TMNEXT
      if (g_state.currentLap == g_state.numLaps) {
#endif
        // mark the whole run as completed
        g_state.CompleteRun(raceTime);
        PrintOnce("Finish | " + raceTime + " ms");
      }
    }

    ArchiveCurrentRun();
    SaveData();
  }
}