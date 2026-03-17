void Main() {
  LoadFont();
  playerStartTime = GetPlayerStartTime();
}

void OnSettingsChanged() {
  //
}

// clears data and session bests — called on map change
void ResetCommon() {
  waitForCarReset = true;
  ResetRace();
  for (int i = 0; i < 10; i++) bestLapTimes[i] = -1;
  bestLapCpTimes = {};
  bestAllTimeCpTimes = {};
  for (int i = 0; i < 10; i++) bestAllTimeLapTimes[i] = 0;

  hasFinishedMap = false;
  hasPlayerRaced = false;

  g_allAttempts = {};
  g_allAttemptIds = {};
  g_pbAttemptId = -1;
}

// clears current run data, keeps session bests
void ResetRace() {
  for (int i = 0; i < 10; i++) lapTimes[i] = -1;
  isFinished = false;
  currentLap = 0;
  finishRaceTime = 0;
  prevLapRaceTime = 0;
  lastCpTime = 0;
  currLapCpTimes = {};
  allLapCpTimes = {};

#if TMNEXT
  lastCP = GetSpawnCheckpoint();
#endif
}

void Update(float dt) {
  // have we changed map?
  if (currentMap != GetMapId()) {
    debugText("map mismatch");
    debugText("MapID: " + GetMapId());
    debugText("CurrentMap: " + currentMap);

    if (currentMap != "") {
    }

    currentMap = "";
    ResetCommon();

    if (currentMap == "" || GetMapId() == "") {
      debugText("map found - " + GetMapName());
      playerStartTime = GetPlayerStartTime();
      currentMap = GetMapId();
      UpdateWaypoints();
      LoadData();
    }
  }

  // wait for the car to be back at starting checkpoint
  if (waitForCarReset) {
#if TMNEXT
    waitForCarReset = GetCurrentPlayerRaceTime() >= 0;
#endif
    return;
  }

  // wait for car to be driveable to do our final reset
  if (resetData) {
    if (IsPlayerReady()) {
      debugText("Running reset");
      resetData = false;

      // Archive the just-completed attempt before clearing allLapCpTimes
      if (hasPlayerRaced) {
        ArchiveCurrentAttempt();
        currentAttemptId++;
      }
      hasPlayerRaced = true;

      ResetRace();

      playerStartTime = GetActualPlayerStartTime();

      if (numCps <= 1) {
        UpdateWaypoints();
        LoadData();
      }

      SaveData();

      debugText("Ready to read checkpoints");
    }
    return;
  } else {
    if (!IsPlayerReady()) {
      debugText("Car no longer valid..");
      resetData = true;
      return;
    }
  }

  int cp = GetCurrentCheckpoint();

  // have we changed checkpoint?
  if (cp != lastCP) {
    debugText("- Checkpoint change " + lastCP + " to " + cp);

    lastCP = cp;

    int raceTime = GetPlayerCheckpointTime();
    int deltaTime = raceTime - prevLapRaceTime;

    debugText("Delta time: " + deltaTime);
    debugText("Race time: " + raceTime);

    if (raceTime <= 0 || deltaTime <= 0) {
      debugText("Checkpoint time negative..");
#if TMNEXT
      waitForCarReset = true;
#endif
      return;
    }

    // record split for this checkpoint within the current lap
    int cpDelta = raceTime - lastCpTime;
    if (cpDelta > 0) {
      currLapCpTimes.InsertLast(cpDelta);
      int cpIdx = int(currLapCpTimes.Length) - 1;
      UpdateCpBest(currentLap, cpIdx, cpDelta);
      print("[WGS] Lap " + (currentLap + 1) + " CP " + currLapCpTimes.Length + ": " + Time::Format(cpDelta) + " (race: " + Time::Format(raceTime) + ")");
    }
    lastCpTime = raceTime;

    // lap finish
    if (isMultiLap && IsWaypointFinish(cp)) {
      prevLapRaceTime = raceTime;
      CreateOrUpdateBestTime(deltaTime);
      SaveLapCpTimes(currentLap);
      currLapCpTimes = {};
      print("[WGS] Lap " + (currentLap + 1) + " finished: " + Time::Format(deltaTime));
    }

    // check for race finish
#if TMNEXT
    if (IsWaypointFinish(cp)) {
#endif
      hasFinishedMap = true;
      currentLap++;
      if (isMultiLap) {
        debugText("Lap finish: " + currentLap + "/" + numLaps);
      }

#if TMNEXT
      if (!isMultiLap || currentLap == numLaps) {
#endif
        debugText("Race Finished");
        waitForCarReset = true;
        resetData = true;
        isFinished = true;
        finishRaceTime = raceTime;
        if (isMultiLap) CheckAndUpdatePB();
      }
    }

    SaveData();
  }
}

// Snapshots the current run's complete laps into the historical archive
// before the run is cleared. Must be called before ResetRace().
void ArchiveCurrentAttempt() {
  if (allLapCpTimes.Length == 0) return;
  array<array<int>> copy;
  for (uint i = 0; i < allLapCpTimes.Length; i++) {
    array<int> lapCopy = allLapCpTimes[i];
    copy.InsertLast(lapCopy);
  }
  g_allAttempts.InsertLast(copy);
  g_allAttemptIds.InsertLast(currentAttemptId);
}

void CreateOrUpdateBestTime(int time) {
  int idx = currentLap; // currentLap hasn't incremented yet
  if (idx < 0 || idx >= 10) return;

  lapTimes[idx] = time;

  if (bestAllTimeLapTimes[idx] == 0 || time < bestAllTimeLapTimes[idx]) {
    bestAllTimeLapTimes[idx] = time;
    SaveData();
  }
}

void SaveLapCpTimes(int lapIdx) {
  if (lapIdx < 0 || lapIdx >= 10) return;

  int[] emptySlot;
  while (int(allLapCpTimes.Length) <= lapIdx) {
    allLapCpTimes.InsertLast(emptySlot);
  }

  allLapCpTimes[lapIdx] = currLapCpTimes;
}

// Called when a full run completes. If this run's total beats the current PB
// (or no PB exists), replace bestLapTimes and bestLapCpTimes with this run's data.
void CheckAndUpdatePB() {
  int total = 0;
  for (int i = 0; i < numLaps; i++) {
    if (lapTimes[i] == -1) return; // incomplete
    total += lapTimes[i];
  }

  int pbTotal = 0;
  bool hasPB = true;
  for (int i = 0; i < numLaps; i++) {
    if (bestLapTimes[i] == -1) { hasPB = false; break; }
    pbTotal += bestLapTimes[i];
  }

  if (!hasPB || total < pbTotal) {
    for (int i = 0; i < numLaps; i++) {
      bestLapTimes[i] = lapTimes[i];
    }
    bestLapCpTimes = allLapCpTimes;
    g_pbAttemptId = currentAttemptId;
    SaveData();
  }
}

// Updates the all-time best for a specific [lap, cp] and saves if improved.
void UpdateCpBest(int lapIdx, int cpIdx, int time) {
  int[] empty;
  while (int(bestAllTimeCpTimes.Length) <= lapIdx) bestAllTimeCpTimes.InsertLast(empty);
  while (int(bestAllTimeCpTimes[lapIdx].Length) <= cpIdx) bestAllTimeCpTimes[lapIdx].InsertLast(0);

  if (bestAllTimeCpTimes[lapIdx][cpIdx] == 0 || time < bestAllTimeCpTimes[lapIdx][cpIdx]) {
    bestAllTimeCpTimes[lapIdx][cpIdx] = time;
    SaveData();
  }
}

int BoolToInt(bool value) {
  return value ? 1 : 0;
}
