void Update(float dt) {

  string mapId = GetMapId();
  if (g_state.currentMap != mapId) {            
    g_state.set_currentMap("");
    ResetCommon();

    if (g_state.get_currentMap() == "" || mapId == "") {      
      // capture the new map ID and player start time, rebuild waypoint metadata, and hydrate in-memory history from disk.
      g_state.playerStartTime = GetPlayerStartTime();
      g_state.set_currentMap(mapId);
      UpdateWaypoints();
      LoadData();
    }
  }

  if (g_state.waitForCarReset) {
    // keep waiting, updating the flag when the race timer is valid
#if TMNEXT
    g_state.waitForCarReset = GetCurrentPlayerRaceTime() >= 0;
#endif
    return;
  }

  if (g_state.resetData) {
    if (IsPlayerReady()) {      
      // clear reset flag, archive the just-finished attempt, fully reset run state, fix start time, refresh waypoints for trivial CP maps, and persist the new state.
      g_state.resetData = false;

      if (g_state.hasPlayerRaced) { // first CP of lap 1 reached
        ArchiveCurrentAttempt();
        g_state.currentAttemptId++;
        g_state.hasPlayerRaced = false; // reset flag until the next attempt crosses CP1
      }

      ResetRace();

      g_state.playerStartTime = GetActualPlayerStartTime();

      if (g_state.numCps <= 1) {
        UpdateWaypoints();
        LoadData();
      }

      SaveData();
      
    }
    return;
  } else {
    if (!IsPlayerReady()) {      
      g_state.resetData = true;
      return;
    }
  }

  int cp = GetCurrentCheckpoint();

  if (cp != g_state.lastCP) {    
    // checkpoint crossed
    int raceTime = GetPlayerCheckpointTime();
    g_state.RecordCheckpoint(cp, raceTime);
    if (raceTime <= 0 || raceTime - g_state.prevLapRaceTime <= 0) return;

    if (IsWaypointFinish(cp)) {
      // compute the lap delta from the previous lap start
      int deltaTime = raceTime - g_state.prevLapRaceTime;
      // finalize lap metrics for the current lap (single-lap and multi-lap alike)
      g_state.CompleteLap(deltaTime, raceTime);
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
        CheckAndUpdatePB();
      }
    }

    SaveData();
  }
}