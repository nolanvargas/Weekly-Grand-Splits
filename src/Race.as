// clears data and session bests — called on map change
void ResetCommon() {
  g_state.waitForCarReset = true;
  ResetRace();
  g_state.ResetBestLapTimes();
  g_state.bestLapCpTimes = {};
  g_state.bestAllTimeCpTimes = {};
  g_state.ResetBestAllTimeLapTimes();

  g_state.hasFinishedMap = false;
  g_state.hasPlayerRaced = false;

  g_state.allAttempts = {};
  g_state.allAttemptIds = {};
  g_state.pbAttemptId = -1;
}

// clears current run data, keeps session bests
void ResetRace() {
  g_state.ResetLapTimes();
  g_state.isFinished = false;
  g_state.currentLap = 0;
  g_state.finishRaceTime = 0;
  g_state.prevLapRaceTime = 0;
  g_state.lastCpTime = 0;
  g_state.currLapCpTimes = {};
  g_state.allLapCpTimes = {};

#if TMNEXT
  g_state.lastCP = GetSpawnCheckpoint();
#endif
}

void Update(float dt) {
  // have we changed map?
  if (g_state.currentMap != GetMapId()) {            

    if (g_state.currentMap != "") {
    }

    g_state.currentMap = "";
    ResetCommon();

    if (g_state.currentMap == "" || GetMapId() == "") {      
      g_state.playerStartTime = GetPlayerStartTime();
      g_state.currentMap = GetMapId();
      UpdateWaypoints();
      LoadData();
    }
  }

  // wait for the car to be back at starting checkpoint
  if (g_state.waitForCarReset) {
#if TMNEXT
    g_state.waitForCarReset = GetCurrentPlayerRaceTime() >= 0;
#endif
    return;
  }

  // wait for car to be driveable to do our final reset
  if (g_state.resetData) {
    if (IsPlayerReady()) {      
      g_state.resetData = false;

      // Archive the just-completed attempt before clearing allLapCpTimes
      if (g_state.hasPlayerRaced) {
        ArchiveCurrentAttempt();
        g_state.currentAttemptId++;
      }
      g_state.hasPlayerRaced = true;

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

  // have we changed checkpoint?
  if (cp != g_state.lastCP) {    

    g_state.lastCP = cp;

    int raceTime = GetPlayerCheckpointTime();
    int deltaTime = raceTime - g_state.prevLapRaceTime;
        

    if (raceTime <= 0 || deltaTime <= 0) {      
#if TMNEXT
      g_state.waitForCarReset = true;
#endif
      return;
    }

    // record split for this checkpoint within the current lap
    int cpDelta = raceTime - g_state.lastCpTime;
    if (cpDelta > 0) {
      g_state.currLapCpTimes.InsertLast(cpDelta);
      int cpIdx = int(g_state.currLapCpTimes.Length) - 1;
      UpdateCpBest(g_state.currentLap, cpIdx, cpDelta);
      print("[WGS] Lap " + (g_state.currentLap + 1) + " CP " + g_state.currLapCpTimes.Length + ": " + Time::Format(cpDelta) + " (race: " + Time::Format(raceTime) + ")");
    }
    g_state.lastCpTime = raceTime;

    // lap finish
    if (g_state.isMultiLap && IsWaypointFinish(cp)) {
      g_state.prevLapRaceTime = raceTime;
      CreateOrUpdateBestTime(deltaTime);
      SaveLapCpTimes(g_state.currentLap);
      g_state.currLapCpTimes = {};
      print("[WGS] Lap " + (g_state.currentLap + 1) + " finished: " + Time::Format(deltaTime));
    }

    // check for race finish
#if TMNEXT
    if (IsWaypointFinish(cp)) {
#endif
      g_state.hasFinishedMap = true;
      g_state.currentLap++;
      if (g_state.isMultiLap) {        
      }

#if TMNEXT
      if (!g_state.isMultiLap || g_state.currentLap == g_state.numLaps) {
#endif        
        g_state.waitForCarReset = true;
        g_state.resetData = true;
        g_state.isFinished = true;
        g_state.finishRaceTime = raceTime;
        if (g_state.isMultiLap) CheckAndUpdatePB();
      }
    }

    SaveData();
  }
}

int BoolToInt(bool value) {
  return value ? 1 : 0;
}
