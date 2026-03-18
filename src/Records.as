// Race metrics helpers.
// These functions keep race history, PBs, and per-CP bests in sync with g_state.

// Snapshots the current run's complete laps into the historical archive
// before the run is cleared. Must be called before ResetRace().
// A run is considered a valid attempt once the player has reached
// at least the first checkpoint of lap 1, which is when the first
// entry is written into g_state.currLapCpTimes / g_state.allLapCpTimes.
void ArchiveCurrentAttempt() {
  if (g_state.allLapCpTimes.Length == 0) return;
  // Actions: if there are no completed lap CP splits yet, skip archiving because there is nothing meaningful to store.

  // Build a rich Attempt from the stored lap/CP arrays and archive it.
  array<array<int>> lapCp = g_state.allLapCpTimes;
  int[] dummyTotals; // not used by RaceFromLapArrays
  Attempt@ attempt = RaceFromLapArrays(g_state.currentAttemptId, lapCp, dummyTotals);
  g_state.GetHistory().AddAttempt(attempt);
  // Recompute best/reference baselines from archived attempts only.
  g_state.bests.ComputeFromHistory(g_state.GetHistory(), g_state.numLaps, g_state.numCps);
}

// Persists the current lap's CP splits into the all-lap buffer for the given lap.
// Called when a lap completes.
void SaveLapCpTimes(int lapIdx) {
  if (lapIdx < 0 || lapIdx >= MAX_LAPS) return;
  // Actions: if the requested lap index is outside the valid range, ignore the call and avoid touching the lap buffers.

  int[] emptySlot;
  while (int(g_state.allLapCpTimes.Length) <= lapIdx) {
    // Actions: grow the outer lap array with empty slots until it can hold an entry at this lap index.
    g_state.allLapCpTimes.InsertLast(emptySlot);
  }

  g_state.allLapCpTimes[lapIdx] = g_state.currLapCpTimes;
}

// Updates per-lap PB and all-time best for the current lap if time is better.
// Used when a lap completes to maintain best-per-lap aggregates.
void CreateOrUpdateBestTime(int time) {
  int idx = g_state.currentLap; // currentLap hasn't incremented yet
  if (idx < 0 || idx >= MAX_LAPS) return;
  // Actions: if the derived lap index is invalid, bail out without writing to best-time structures.

  g_state.SetLapTime(idx, time);

  if (g_state.GetBestAllTimeLapTime(idx) == 0 || time < g_state.GetBestAllTimeLapTime(idx)) {
    // Actions: when there is no prior best or this time is faster, update the stored all-time best for this lap and immediately persist to disk.
    g_state.SetBestAllTimeLapTime(idx, time);
    SaveData();
  }
}

// Called when a full run completes.
// If this run's total beats the current PB (or no PB exists),
// replaces bestLapTimes and bestLapCpTimes with this run's data.
void CheckAndUpdatePB() {
  int total = 0;
  for (int i = 0; i < g_state.numLaps; i++) {
    if (g_state.GetLapTime(i) == -1) return; // incomplete
    // Actions: if any lap time is missing (sentinel -1), treat the run as incomplete and skip PB comparison entirely.
    total += g_state.GetLapTime(i);
  }

  int pbTotal = 0;
  bool hasPB = true;
  for (int i = 0; i < g_state.numLaps; i++) {
    if (g_state.GetBestLapTime(i) == -1) { hasPB = false; break; }
    // Actions: when a best-lap slot is unset, mark that no full PB exists and stop summing PB lap times early.
    pbTotal += g_state.GetBestLapTime(i);
  }

  if (!hasPB || total < pbTotal) {
    // Actions: when there is no existing PB or this total run is faster, copy current lap times and CP splits into PB storage and persist the new record.
    for (int i = 0; i < g_state.numLaps; i++) {
      g_state.SetBestLapTime(i, g_state.GetLapTime(i));
    }
    g_state.bestLapCpTimes = g_state.allLapCpTimes;
    g_state.GetHistory().set_PbAttemptId(g_state.currentAttemptId);
    SaveData();
  }
}

// Updates the all-time best for a specific [lap, cp] and saves if improved.
// Invoked when a CP time is recorded and beats the previous best.
void UpdateCpBest(int lapIdx, int cpIdx, int time) {
  g_state.GetHistory().UpdateCpBest(lapIdx, cpIdx, time);
  SaveData();
}
