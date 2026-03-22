// Snapshots the current run's complete laps into the historical archive
// before the run is cleared. Must be called before ResetRace().
// A run is considered a valid attempt once the player has reached
// at least the first checkpoint of lap 1, which is when the first
// entry is written into the current Attempt's lap/cp checkpoint times.
Attempt@ ArchiveCurrentAttempt() {
  // We only archive completed laps.
  int completedLapsCount = g_state.currentLap; // laps are completed when currentLap points to the next one
  if (completedLapsCount <= 0) return null;

  Attempt@ srcAttempt = g_state.currentAttempt;
  if (srcAttempt is null || srcAttempt.laps.Length <= 0) return null;

  // Build an Attempt that includes ONLY completed laps.
  Attempt@ attempt = Attempt();
  attempt.attemptId = g_state.currentAttemptId;

  for (int lapIdx = 1; lapIdx < completedLapsCount && lapIdx < int(srcAttempt.laps.Length); lapIdx++) { // Laps start at 1
    Lap@ lap = srcAttempt.GetLap(lapIdx);
    uint cpCount = lap.checkpoints.Length;
    for (uint cpIdx = 1; cpIdx < cpCount; cpIdx++) { // CPs start at 1; skip phantom at 0
      int checkpointTimeMs = lap.GetCheckpointTime(int(cpIdx));
      attempt.SetCheckpointTime(lapIdx - 1, int(cpIdx) - 1, checkpointTimeMs); // SetCheckpointTime takes 0-based indices
    }
  }

  g_state.history.UpsertAttempt(attempt);
  // Note: best references are updated at the next ResetRace() boundary (not during the run).
  return attempt;
}

// Upserts the full current-run state (including in-progress lap) into history.
// Called at every checkpoint so mid-run data survives a crash or reload.
void ArchiveCurrentRun() {
  Attempt@ src = g_state.currentAttempt;
  if (src is null || src.laps.Length <= 0) return;
  g_state.history.UpsertAttempt(src);
}

void PersistCurrentRun() {
  ArchiveCurrentRun();
  g_state.history.SaveData();
}
