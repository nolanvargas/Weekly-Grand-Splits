// Snapshots the current run's complete laps into the historical archive
// before the run is cleared. Must be called before ResetRace().
void ArchiveCurrentAttempt() {
  if (g_state.allLapCpTimes.Length == 0) return;
  array<array<int>> copy;
  for (uint i = 0; i < g_state.allLapCpTimes.Length; i++) {
    array<int> lapCopy = g_state.allLapCpTimes[i];
    copy.InsertLast(lapCopy);
  }
  g_state.allAttempts.InsertLast(copy);
  g_state.allAttemptIds.InsertLast(g_state.currentAttemptId);
}

void SaveLapCpTimes(int lapIdx) {
  if (lapIdx < 0 || lapIdx >= MAX_LAPS) return;

  int[] emptySlot;
  while (int(g_state.allLapCpTimes.Length) <= lapIdx) {
    g_state.allLapCpTimes.InsertLast(emptySlot);
  }

  g_state.allLapCpTimes[lapIdx] = g_state.currLapCpTimes;
}

void CreateOrUpdateBestTime(int time) {
  int idx = g_state.currentLap; // currentLap hasn't incremented yet
  if (idx < 0 || idx >= MAX_LAPS) return;

  g_state.SetLapTime(idx, time);

  if (g_state.GetBestAllTimeLapTime(idx) == 0 || time < g_state.GetBestAllTimeLapTime(idx)) {
    g_state.SetBestAllTimeLapTime(idx, time);
    SaveData();
  }
}

// Called when a full run completes. If this run's total beats the current PB
// (or no PB exists), replace bestLapTimes and bestLapCpTimes with this run's data.
void CheckAndUpdatePB() {
  int total = 0;
  for (int i = 0; i < g_state.numLaps; i++) {
    if (g_state.GetLapTime(i) == -1) return; // incomplete
    total += g_state.GetLapTime(i);
  }

  int pbTotal = 0;
  bool hasPB = true;
  for (int i = 0; i < g_state.numLaps; i++) {
    if (g_state.GetBestLapTime(i) == -1) { hasPB = false; break; }
    pbTotal += g_state.GetBestLapTime(i);
  }

  if (!hasPB || total < pbTotal) {
    for (int i = 0; i < g_state.numLaps; i++) {
      g_state.SetBestLapTime(i, g_state.GetLapTime(i));
    }
    g_state.bestLapCpTimes = g_state.allLapCpTimes;
    g_state.pbAttemptId = g_state.currentAttemptId;
    SaveData();
  }
}

// Updates the all-time best for a specific [lap, cp] and saves if improved.
void UpdateCpBest(int lapIdx, int cpIdx, int time) {
  int[] empty;
  while (int(g_state.bestAllTimeCpTimes.Length) <= lapIdx) g_state.bestAllTimeCpTimes.InsertLast(empty);
  while (int(g_state.bestAllTimeCpTimes[lapIdx].Length) <= cpIdx) g_state.bestAllTimeCpTimes[lapIdx].InsertLast(0);

  if (g_state.bestAllTimeCpTimes[lapIdx][cpIdx] == 0 || time < g_state.bestAllTimeCpTimes[lapIdx][cpIdx]) {
    g_state.bestAllTimeCpTimes[lapIdx][cpIdx] = time;
    SaveData();
  }
}
