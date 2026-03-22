class Bests {
  Attempt@ bestSingleAttempt;     // personal-best attempt (best single attempt)
  Lap@ bestSingleLap;             // best single lap at any lap number
  Lap@ bestAnyCp;                 // best cp at cp index disreguarding lap number
  Attempt@ bestLapByLapIndex;     // best lap at lap number
  Attempt@ bestCpByCpLapIndex;    // best cp at cp index and lap number both

  // Cached bounds for safe getters.
  int _numLaps = 0;
  int _numCps = 0;

  Bests() {}

  void Clear() {
    @bestSingleAttempt = null;
    @bestSingleLap = null;
    @bestAnyCp = null;
    @bestLapByLapIndex = null;
    @bestCpByCpLapIndex = null;
    _numLaps = 0;
    _numCps = 0;
  }

  bool IsLapComplete(Lap@ lap) const {
    if (_numCps <= 0) return false;
    return int(lap.checkpoints.Length) == _numCps + 1; // phantom at [0] + numCps real; CPs start at 1
  }

  bool IsAttemptComplete(Attempt@ attempt) const {
    if (_numLaps <= 0 ) return false;
    if (int(attempt.laps.Length) <= _numLaps) return false; // needs phantom [0] + numLaps real
    for (int lapIdx = 1; lapIdx <= _numLaps; lapIdx++) { // Laps start at 1
      Lap@ lap = attempt.GetLap(lapIdx);
      if (!IsLapComplete(lap)) return false;
    }
    return true;
  }

  int AttemptTotalIfComplete(Attempt@ attempt) const {
    if (!IsAttemptComplete(attempt)) return -1;
    int total = 0;
    for (int lapIdx = 1; lapIdx <= _numLaps; lapIdx++) { // Laps start at 1
      Lap@ lap = attempt.GetLap(lapIdx);
      total += lap.GetLapTime();
    }
    return total;
  }

  // Computes all best references from archived attempt data.
  void ComputeFromHistory(RaceHistory@ history, int numLaps, int numCps) {
    Clear();

    _numLaps = Math::Max(0, numLaps);
    _numCps = Math::Max(0, numCps);
    if (_numLaps <= 0 || _numCps <= 0) {
      return;
    }

    // 1) bestSingleAttempt: best complete attempt by total lap sum.
    int bestTotal = 0;
    Attempt@ bestAttempt = null;
    for (uint attemptIndex = 0; attemptIndex < history.GetAttemptCount(); attemptIndex++) {
      Attempt@ attempt = history.GetAttemptByIndex(attemptIndex);
      int total = AttemptTotalIfComplete(attempt);
      if (total <= 0) continue;
      if (bestAttempt is null || bestTotal == 0 || total < bestTotal) {
        bestTotal = total;
        @bestAttempt = attempt;
      }
    }
    @bestSingleAttempt = bestAttempt;

    // 2) bestSingleLap: best complete lap across all attempts.
    Lap@ bestLap = null;
    int bestLapTime = 0;
    for (uint attemptIndex = 0; attemptIndex < history.GetAttemptCount(); attemptIndex++) {
      Attempt@ attempt = history.GetAttemptByIndex(attemptIndex);
      for (int lapIdx = 1; lapIdx <= _numLaps && lapIdx < int(attempt.laps.Length); lapIdx++) { // Laps start at 1
        Lap@ lap = attempt.GetLap(lapIdx);
        if (!IsLapComplete(lap)) continue;
        int lapTime = lap.GetLapTime();
        if (bestLap is null || bestLapTime == 0 || lapTime < bestLapTime) {
          bestLapTime = lapTime;
          @bestLap = lap;
        }
      }
    }
    @bestSingleLap = bestLap;

    // 3) bestAnyCp: per-cp minimum across any lap/attempt.
    Lap@ anyCp = Lap(0, _numCps);
    for (int cpIdx = 1; cpIdx <= _numCps; cpIdx++) { // CPs start at 1
      int bestTime = 0;
      for (uint attemptIndex = 0; attemptIndex < history.GetAttemptCount(); attemptIndex++) {
        Attempt@ attempt = history.GetAttemptByIndex(attemptIndex);
        for (int lapIdx = 1; lapIdx <= _numLaps && lapIdx < int(attempt.laps.Length); lapIdx++) { // Laps start at 1
          Lap@ lap = attempt.GetLap(lapIdx);
          if (cpIdx >= int(lap.checkpoints.Length)) continue;
          int cpTime = lap.GetCheckpointTime(cpIdx);
          if (bestTime == 0 || cpTime < bestTime) bestTime = cpTime;
        }
      }
      if (bestTime > 0) anyCp.SetCheckpointTime(cpIdx, bestTime);
    }
    @bestAnyCp = anyCp;

    // 4) bestLapByLapIndex: for each lapIdx, pick best complete lap at that index and copy its whole checkpoint set.
    Attempt@ lapByIndex = Attempt();
    for (int lapIdx = 1; lapIdx <= _numLaps; lapIdx++) { // Laps start at 1
      Lap@ chosenLap = null;
      int chosenLapTime = 0;
      for (uint attemptIndex = 0; attemptIndex < history.GetAttemptCount(); attemptIndex++) {
        Attempt@ attempt = history.GetAttemptByIndex(attemptIndex);
        if (lapIdx >= int(attempt.laps.Length)) continue;
        Lap@ lap = attempt.GetLap(lapIdx);
        if (!IsLapComplete(lap)) continue;
        int lapTime = lap.GetLapTime();
        if (chosenLap is null || chosenLapTime == 0 || lapTime < chosenLapTime) {
          chosenLapTime = lapTime;
          @chosenLap = lap;
        }
      }
      if (chosenLap !is null) {
        for (int cpIdx = 1; cpIdx <= _numCps; cpIdx++) { // CPs start at 1
          lapByIndex.SetCheckpointTime(lapIdx - 1, cpIdx - 1, chosenLap.GetCheckpointTime(cpIdx));
        }
      }
    }
    @bestLapByLapIndex = lapByIndex;

    // 5) bestCpByCpLapIndex: independent per-slot minima for (lapIdx, cpIdx).
    Attempt@ cpByLapIndex = Attempt();
    for (int lapIdx = 1; lapIdx <= _numLaps; lapIdx++) { // Laps start at 1
      for (int cpIdx = 1; cpIdx <= _numCps; cpIdx++) { // CPs start at 1
        int bestTime = 0;
        for (uint attemptIndex = 0; attemptIndex < history.GetAttemptCount(); attemptIndex++) {
          Attempt@ attempt = history.GetAttemptByIndex(attemptIndex);
          if (lapIdx >= int(attempt.laps.Length)) continue;
          Lap@ lap = attempt.GetLap(lapIdx);
          if (cpIdx >= int(lap.checkpoints.Length)) continue;
          int cpTime = lap.GetCheckpointTime(cpIdx);
          if (bestTime == 0 || cpTime < bestTime) bestTime = cpTime;
        }
        if (bestTime > 0) cpByLapIndex.SetCheckpointTime(lapIdx - 1, cpIdx - 1, bestTime);
      }
    }
    @bestCpByCpLapIndex = cpByLapIndex;
  }

  // Incrementally updates best caches from a single archived attempt.
  // This is used so we do not recompute/adjust best references during an active run.
  void UpdateFromAttempt(Attempt@ attempt) {
    // Ensure reference containers exist.
    if (bestAnyCp is null || int(bestAnyCp.checkpoints.Length) != _numCps + 1) { // phantom + numCps real; CPs start at 1
      @bestAnyCp = Lap(0, _numCps);
    }
    if (bestLapByLapIndex is null) @bestLapByLapIndex = Attempt();
    if (bestCpByCpLapIndex is null) @bestCpByCpLapIndex = Attempt();

    // 1) bestSingleAttempt: best complete attempt by total lap sum.
    int candidateTotal = AttemptTotalIfComplete(attempt);
    int currentTotal = 0;
    if (bestSingleAttempt !is null) currentTotal = AttemptTotalIfComplete(bestSingleAttempt);
    if (candidateTotal > 0 && (bestSingleAttempt is null || currentTotal == 0 || candidateTotal < currentTotal)) {
      @bestSingleAttempt = attempt;
    }

    // 2) bestSingleLap: best complete lap across all attempts.
    int currentBestLapTime = 0;
    if (bestSingleLap !is null && IsLapComplete(bestSingleLap)) currentBestLapTime = bestSingleLap.GetLapTime();

    for (int lapIdx = 1; lapIdx <= _numLaps && lapIdx < int(attempt.laps.Length); lapIdx++) { // Laps start at 1
      Lap@ lap = attempt.GetLap(lapIdx);
      if (!IsLapComplete(lap)) continue;
      int lapTime = lap.GetLapTime();
      if (bestSingleLap is null || currentBestLapTime == 0 || lapTime < currentBestLapTime) {
        @bestSingleLap = lap;
        currentBestLapTime = lapTime;
      }
    }

    // 3) bestAnyCp: per-cp minimum across any lap/attempt.
    for (int cpIdx = 1; cpIdx <= _numCps; cpIdx++) { // CPs start at 1
      // Keep the loop symmetric with ComputeFromHistory: scan all laps for this attempt.
      for (int lapIdx = 1; lapIdx <= _numLaps && lapIdx < int(attempt.laps.Length); lapIdx++) { // Laps start at 1
        Lap@ lap = attempt.GetLap(lapIdx);
        if (cpIdx >= int(lap.checkpoints.Length)) continue;
        int cpTime = lap.GetCheckpointTime(cpIdx);
        int bestTime = bestAnyCp.GetCheckpointTime(cpIdx);
        if (bestTime == 0 || cpTime < bestTime) bestAnyCp.SetCheckpointTime(cpIdx, cpTime);
      }
    }

    // 4) bestLapByLapIndex: best complete lap at each lap index, then copy its whole checkpoint set.
    for (int lapIdx = 1; lapIdx <= _numLaps; lapIdx++) { // Laps start at 1
      if (lapIdx >= int(attempt.laps.Length)) continue;
      Lap@ lap = attempt.GetLap(lapIdx);
      if (!IsLapComplete(lap)) continue;

      int candidateLapTime = lap.GetLapTime();

      int currentLapTime = 0;
      if (lapIdx < int(bestLapByLapIndex.laps.Length)) {
        Lap@ curLap = bestLapByLapIndex.GetLap(lapIdx);
        if (IsLapComplete(curLap)) currentLapTime = curLap.GetLapTime();
      }

      if (currentLapTime == 0 || candidateLapTime < currentLapTime) {
        for (int cpIdx = 1; cpIdx <= _numCps; cpIdx++) { // CPs start at 1
          bestLapByLapIndex.SetCheckpointTime(lapIdx - 1, cpIdx - 1, lap.GetCheckpointTime(cpIdx));
        }
      }
    }

    // 5) bestCpByCpLapIndex: independent per-slot minima for (lapIdx, cpIdx).
    for (int lapIdx = 1; lapIdx <= _numLaps && lapIdx < int(attempt.laps.Length); lapIdx++) { // Laps start at 1
      Lap@ lap = attempt.GetLap(lapIdx);
      for (int cpIdx = 1; cpIdx <= _numCps; cpIdx++) { // CPs start at 1
        if (cpIdx >= int(lap.checkpoints.Length)) continue;
        int cpTime = lap.GetCheckpointTime(cpIdx);

        int currentBest = 0;
        if (lapIdx < int(bestCpByCpLapIndex.laps.Length)) {
          Lap@ curLap = bestCpByCpLapIndex.GetLap(lapIdx);
          if (cpIdx < int(curLap.checkpoints.Length)) currentBest = curLap.GetCheckpointTime(cpIdx);
        }

        if (currentBest == 0 || cpTime < currentBest) {
          bestCpByCpLapIndex.SetCheckpointTime(lapIdx - 1, cpIdx - 1, cpTime);
        }
      }
    }
  }

  // PB lap totals for DeltaPB comparison (return -1 when missing). lapIdx is 1-based.
  int GetBestSingleAttemptLapTotal(int lapIdx) const {
    if (bestSingleAttempt is null) return -1;
    if (lapIdx < 1 || lapIdx > _numLaps) return -1;
    if (lapIdx >= int(bestSingleAttempt.laps.Length)) return -1;
    Lap@ lap = bestSingleAttempt.GetLap(lapIdx);
    if (!IsLapComplete(lap)) return -1;
    return lap.GetLapTime();
  }

  // Best lap totals by lap index (property 4). Return 0 when missing. lapIdx is 1-based.
  int GetBestLapTotalByLapIndex(int lapIdx) const {
    if (bestLapByLapIndex is null) return 0;
    if (lapIdx < 1 || lapIdx > _numLaps) return 0;
    if (lapIdx >= int(bestLapByLapIndex.laps.Length)) return 0;
    Lap@ lap = bestLapByLapIndex.GetLap(lapIdx);
    if (!IsLapComplete(lap)) return 0;
    return lap.GetLapTime();
  }

  // PB cp refs (return 0 when missing). cpIdx is 1-based.
  int GetBestSingleAttemptCpTime(int lapIdx, int cpIdx) const {
    if (bestSingleAttempt is null) return 0;
    if (lapIdx < 1 || lapIdx > _numLaps) return 0;
    if (lapIdx >= int(bestSingleAttempt.laps.Length)) return 0;
    Lap@ lap = bestSingleAttempt.GetLap(lapIdx);
    if (cpIdx < 1 || cpIdx >= int(lap.checkpoints.Length)) return 0;
    return lap.GetCheckpointTime(cpIdx);
  }

  // Best cp per (lapIdx, cpIdx) (property 5). Return 0 when missing. cpIdx is 1-based.
  int GetBestCpByCpLapIndexTime(int lapIdx, int cpIdx) const {
    if (bestCpByCpLapIndex is null) return 0;
    if (lapIdx < 1 || lapIdx > _numLaps) return 0;
    if (lapIdx >= int(bestCpByCpLapIndex.laps.Length)) return 0;
    Lap@ lap = bestCpByCpLapIndex.GetLap(lapIdx);
    if (cpIdx < 1 || cpIdx >= int(lap.checkpoints.Length)) return 0;
    return lap.GetCheckpointTime(cpIdx);
  }

  // Best cp across any lap for cpIdx (property 3). Return 0 when missing. cpIdx is 1-based.
  int GetBestAnyCpTime(int cpIdx) const {
    if (bestAnyCp is null) return 0;
    if (cpIdx < 1 || cpIdx >= int(bestAnyCp.checkpoints.Length)) return 0;
    return bestAnyCp.GetCheckpointTime(cpIdx);
  }
}