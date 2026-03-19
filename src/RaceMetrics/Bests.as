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

  bool HasBestAttempt() const {
    return bestSingleAttempt !is null;
  }

  bool IsLapComplete(Lap@ lap) const {
    if (_numCps <= 0) return false;
    if (int(lap.CheckpointCount) < _numCps) return false;
    for (int cpIdx = 0; cpIdx < _numCps; cpIdx++) {
      int cpTime = lap.GetCheckpointTime(cpIdx);
      if (cpTime <= 0) return false;
    }
    return true;
  }

  bool IsAttemptComplete(Attempt@ a) const {
    if (_numLaps <= 0 ) return false;
    if (int(a.LapCount) < _numLaps) return false;
    for (int lapIdx = 0; lapIdx < _numLaps; lapIdx++) {
      Lap@ lap = a.GetLap(lapIdx);
      if (!IsLapComplete(lap)) return false;
    }
    return true;
  }

  int AttemptTotalIfComplete(Attempt@ a) const {
    if (!IsAttemptComplete(a)) return -1;
    int total = 0;
    for (int lapIdx = 0; lapIdx < _numLaps; lapIdx++) {
      Lap@ lap = a.GetLap(lapIdx);
      total += lap.LapTime;
    }
    return total;
  }

  // Computes all best references from archived attempt data.
  void ComputeFromHistory(RaceHistory@ history, int numLaps, int numCps) {
    Clear();

    _numLaps = Math::Max(0, numLaps);
    _numCps = Math::Max(0, numCps);
    if (_numLaps <= 0 || _numCps <= 0) return;

    // 1) bestSingleAttempt: best complete attempt by total lap sum.
    int bestTotal = 0;
    Attempt@ bestAttempt = null;
    for (uint ai = 0; ai < history.GetAttemptCount(); ai++) {
      Attempt@ a = history.GetAttemptByIndex(ai);
      int total = AttemptTotalIfComplete(a);
      if (total <= 0) continue;
      if (bestAttempt is null || bestTotal == 0 || total < bestTotal) {
        bestTotal = total;
        @bestAttempt = a;
      }
    }
    @bestSingleAttempt = bestAttempt;

    // 2) bestSingleLap: best complete lap across all attempts.
    Lap@ bestLap = null;
    int bestLapTime = 0;
    for (uint ai = 0; ai < history.GetAttemptCount(); ai++) {
      Attempt@ a = history.GetAttemptByIndex(ai);
      for (int lapIdx = 0; lapIdx < _numLaps && lapIdx < int(a.LapCount); lapIdx++) {
        Lap@ lap = a.GetLap(lapIdx);
        if (!IsLapComplete(lap)) continue;
        int lapTime = lap.LapTime;
        if (lapTime <= 0) continue;
        if (bestLap is null || bestLapTime == 0 || lapTime < bestLapTime) {
          bestLapTime = lapTime;
          @bestLap = lap;
        }
      }
    }
    @bestSingleLap = bestLap;

    // 3) bestAnyCp: per-cp minimum across any lap/attempt.
    Lap@ anyCp = Lap(0, _numCps);
    for (int cpIdx = 0; cpIdx < _numCps; cpIdx++) {
      int bestTime = 0;
      for (uint ai = 0; ai < history.GetAttemptCount(); ai++) {
        Attempt@ a = history.GetAttemptByIndex(ai);
        for (int lapIdx = 0; lapIdx < _numLaps && lapIdx < int(a.LapCount); lapIdx++) {
          Lap@ lap = a.GetLap(lapIdx);
          if (cpIdx >= int(lap.CheckpointCount)) continue;
          int cpTime = lap.GetCheckpointTime(cpIdx);
          if (cpTime <= 0) continue;
          if (bestTime == 0 || cpTime < bestTime) bestTime = cpTime;
        }
      }
      if (bestTime > 0) anyCp.SetCheckpointTime(cpIdx, bestTime);
    }
    @bestAnyCp = anyCp;

    // 4) bestLapByLapIndex: for each lapIdx, pick best complete lap at that index and copy its whole checkpoint set.
    Attempt@ lapByIndex = Attempt();
    for (int lapIdx = 0; lapIdx < _numLaps; lapIdx++) {
      Lap@ chosenLap = null;
      int chosenLapTime = 0;
      for (uint ai = 0; ai < history.GetAttemptCount(); ai++) {
        Attempt@ a = history.GetAttemptByIndex(ai);
        if (lapIdx >= int(a.LapCount)) continue;
        Lap@ lap = a.GetLap(lapIdx);
        if (!IsLapComplete(lap)) continue;
        int lapTime = lap.LapTime;
        if (lapTime <= 0) continue;
        if (chosenLap is null || chosenLapTime == 0 || lapTime < chosenLapTime) {
          chosenLapTime = lapTime;
          @chosenLap = lap;
        }
      }
      if (chosenLap !is null) {
        for (int cpIdx = 0; cpIdx < _numCps; cpIdx++) {
          int cpTime = chosenLap.GetCheckpointTime(cpIdx);
          if (cpTime > 0) lapByIndex.SetCheckpointTime(lapIdx, cpIdx, cpTime);
        }
      }
    }
    @bestLapByLapIndex = lapByIndex;

    // 5) bestCpByCpLapIndex: independent per-slot minima for (lapIdx, cpIdx).
    Attempt@ cpByLapIndex = Attempt();
    for (int lapIdx = 0; lapIdx < _numLaps; lapIdx++) {
      for (int cpIdx = 0; cpIdx < _numCps; cpIdx++) {
        int bestTime = 0;
        for (uint ai = 0; ai < history.GetAttemptCount(); ai++) {
          Attempt@ a = history.GetAttemptByIndex(ai);
          if (lapIdx >= int(a.LapCount)) continue;
          Lap@ lap = a.GetLap(lapIdx);
          if (cpIdx >= int(lap.CheckpointCount)) continue;
          int cpTime = lap.GetCheckpointTime(cpIdx);
          if (cpTime <= 0) continue;
          if (bestTime == 0 || cpTime < bestTime) bestTime = cpTime;
        }
        if (bestTime > 0) cpByLapIndex.SetCheckpointTime(lapIdx, cpIdx, bestTime);
      }
    }
    @bestCpByCpLapIndex = cpByLapIndex;
  }

  // Incrementally updates best caches from a single archived attempt.
  // This is used so we do not recompute/adjust best references during an active run.
  void UpdateFromAttempt(Attempt@ a, int numLaps, int numCps) {
    int newNumLaps = Math::Max(0, numLaps);
    int newNumCps = Math::Max(0, numCps);
    if (newNumLaps <= 0 || newNumCps <= 0) {
      Clear();
      return;
    }

    // If config changes (e.g., map change without full reload), reset caches to avoid mixing shapes.
    if (newNumLaps != _numLaps || newNumCps != _numCps) {
      Clear();
      _numLaps = newNumLaps;
      _numCps = newNumCps;
    }

    // Ensure reference containers exist.
    if (bestAnyCp is null || int(bestAnyCp.CheckpointCount) != _numCps) {
      @bestAnyCp = Lap(0, _numCps);
    }
    if (bestLapByLapIndex is null) @bestLapByLapIndex = Attempt();
    if (bestCpByCpLapIndex is null) @bestCpByCpLapIndex = Attempt();

    // 1) bestSingleAttempt: best complete attempt by total lap sum.
    int candidateTotal = AttemptTotalIfComplete(a);
    int currentTotal = 0;
    if (bestSingleAttempt !is null) currentTotal = AttemptTotalIfComplete(bestSingleAttempt);
    if (candidateTotal > 0 && (bestSingleAttempt is null || currentTotal == 0 || candidateTotal < currentTotal)) {
      @bestSingleAttempt = a;
    }

    // 2) bestSingleLap: best complete lap across all attempts.
    int currentBestLapTime = 0;
    if (bestSingleLap !is null && IsLapComplete(bestSingleLap)) currentBestLapTime = bestSingleLap.LapTime;

    for (int lapIdx = 0; lapIdx < _numLaps && lapIdx < int(a.LapCount); lapIdx++) {
      Lap@ lap = a.GetLap(lapIdx);
      if (!IsLapComplete(lap)) continue;
      int lapTime = lap.LapTime;
      if (lapTime <= 0) continue;
      if (bestSingleLap is null || currentBestLapTime == 0 || lapTime < currentBestLapTime) {
        @bestSingleLap = lap;
        currentBestLapTime = lapTime;
      }
    }

    // 3) bestAnyCp: per-cp minimum across any lap/attempt.
    for (int cpIdx = 0; cpIdx < _numCps; cpIdx++) {
      // Keep the loop symmetric with ComputeFromHistory: scan all laps for this attempt.
      for (int lapIdx = 0; lapIdx < _numLaps && lapIdx < int(a.LapCount); lapIdx++) {
        Lap@ lap = a.GetLap(lapIdx);
        if (cpIdx >= int(lap.CheckpointCount)) continue;
        int cpTime = lap.GetCheckpointTime(cpIdx);
        if (cpTime <= 0) continue;
        int bestTime = bestAnyCp.GetCheckpointTime(cpIdx);
        if (bestTime == 0 || cpTime < bestTime) bestAnyCp.SetCheckpointTime(cpIdx, cpTime);
      }
    }

    // 4) bestLapByLapIndex: best complete lap at each lap index, then copy its whole checkpoint set.
    for (int lapIdx = 0; lapIdx < _numLaps; lapIdx++) {
      if (lapIdx >= int(a.LapCount)) continue;
      Lap@ lap = a.GetLap(lapIdx);
      if (!IsLapComplete(lap)) continue;

      int candidateLapTime = lap.LapTime;
      if (candidateLapTime <= 0) continue;

      int currentLapTime = 0;
      if (lapIdx < int(bestLapByLapIndex.LapCount)) {
        Lap@ curLap = bestLapByLapIndex.GetLap(lapIdx);
        if (IsLapComplete(curLap)) currentLapTime = curLap.LapTime;
      }

      if (currentLapTime == 0 || candidateLapTime < currentLapTime) {
        for (int cpIdx = 0; cpIdx < _numCps; cpIdx++) {
          int cpTime = lap.GetCheckpointTime(cpIdx);
          if (cpTime > 0) bestLapByLapIndex.SetCheckpointTime(lapIdx, cpIdx, cpTime);
        }
      }
    }

    // 5) bestCpByCpLapIndex: independent per-slot minima for (lapIdx, cpIdx).
    for (int lapIdx = 0; lapIdx < _numLaps && lapIdx < int(a.LapCount); lapIdx++) {
      Lap@ lap = a.GetLap(lapIdx);
      for (int cpIdx = 0; cpIdx < _numCps; cpIdx++) {
        if (cpIdx >= int(lap.CheckpointCount)) continue;
        int cpTime = lap.GetCheckpointTime(cpIdx);
        if (cpTime <= 0) continue;

        int currentBest = 0;
        if (lapIdx < int(bestCpByCpLapIndex.LapCount)) {
          Lap@ curLap = bestCpByCpLapIndex.GetLap(lapIdx);
          if (cpIdx < int(curLap.CheckpointCount)) currentBest = curLap.GetCheckpointTime(cpIdx);
        }

        if (currentBest == 0 || cpTime < currentBest) {
          bestCpByCpLapIndex.SetCheckpointTime(lapIdx, cpIdx, cpTime);
        }
      }
    }
  }

  // PB lap totals for DeltaPB comparison (return -1 when missing).
  int GetBestSingleAttemptLapTotal(int lapIdx) const {
    if (bestSingleAttempt is null) return -1;
    if (lapIdx < 0 || lapIdx >= _numLaps) return -1;
    if (lapIdx >= int(bestSingleAttempt.LapCount)) return -1;
    Lap@ lap = bestSingleAttempt.GetLap(lapIdx);
    if (!IsLapComplete(lap)) return -1;
    return lap.LapTime;
  }

  // Best lap totals by lap index (property 4). Return 0 when missing.
  int GetBestLapTotalByLapIndex(int lapIdx) const {
    if (bestLapByLapIndex is null) return 0;
    if (lapIdx < 0 || lapIdx >= _numLaps) return 0;
    if (lapIdx >= int(bestLapByLapIndex.LapCount)) return 0;
    Lap@ lap = bestLapByLapIndex.GetLap(lapIdx);
    if (!IsLapComplete(lap)) return 0;
    return lap.LapTime;
  }

  // PB cp refs (return 0 when missing).
  int GetBestSingleAttemptCpTime(int lapIdx, int cpIdx) const {
    if (bestSingleAttempt is null) return 0;
    if (lapIdx < 0 || lapIdx >= _numLaps) return 0;
    if (lapIdx >= int(bestSingleAttempt.LapCount)) return 0;
    Lap@ lap = bestSingleAttempt.GetLap(lapIdx);
    if (cpIdx < 0 || cpIdx >= int(lap.CheckpointCount)) return 0;
    int t = lap.GetCheckpointTime(cpIdx);
    return (t > 0) ? t : 0;
  }

  // Best cp per (lapIdx, cpIdx) (property 5). Return 0 when missing.
  int GetBestCpByCpLapIndexTime(int lapIdx, int cpIdx) const {
    if (bestCpByCpLapIndex is null) return 0;
    if (lapIdx < 0 || lapIdx >= _numLaps) return 0;
    if (lapIdx >= int(bestCpByCpLapIndex.LapCount)) return 0;
    Lap@ lap = bestCpByCpLapIndex.GetLap(lapIdx);
    if (cpIdx < 0 || cpIdx >= int(lap.CheckpointCount)) return 0;
    int t = lap.GetCheckpointTime(cpIdx);
    return (t > 0) ? t : 0;
  }

  // Best cp across any lap for cpIdx (property 3). Return 0 when missing.
  int GetBestAnyCpTime(int cpIdx) const {
    if (bestAnyCp is null) return 0;
    if (cpIdx < 0 || cpIdx >= int(bestAnyCp.CheckpointCount)) return 0;
    int t = bestAnyCp.GetCheckpointTime(cpIdx);
    return (t > 0) ? t : 0;
  }
}