
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
  if (srcAttempt.LapCount <= 0) return null;

  // Build an Attempt that includes ONLY completed laps.
  Attempt@ attempt = Attempt();
  attempt.id = g_state.currentAttemptId;

  for (int lapIdx = 0; lapIdx < completedLapsCount && lapIdx < int(srcAttempt.LapCount); lapIdx++) {
    Lap@ lap = srcAttempt.GetLap(lapIdx);
    uint cpCount = lap.CheckpointCount;
    for (uint cpIdx = 0; cpIdx < cpCount; cpIdx++) {
      int t = lap.GetCheckpointTime(int(cpIdx));
      if (t > 0) attempt.SetCheckpointTime(lapIdx, int(cpIdx), t);
    }
  }

  g_state.history.AddAttempt(attempt);
  // Note: best references are updated at the next ResetRace() boundary (not during the run).
  return attempt;
}
