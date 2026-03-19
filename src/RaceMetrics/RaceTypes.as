class Checkpoint {
  int index = -1; // 0-based CP index within the lap
  int time = 0;   // time delta for this CP (ms)

  Checkpoint() {}

  Checkpoint(int index, int time) {
    this.index = index;
    this.time = time;
  }

  Checkpoint(int index) {
    this.index = index;
  }
}

class Lap {
  int index = 0;
  array<Checkpoint@> checkpoints;
  int LapTime = 0;            // sum of checkpoint times
  uint CheckpointCount = 0;

  Lap() {
    checkpoints = {};
    LapTime = 0;
    CheckpointCount = 0;
  }

  Lap(int index, int cp_qty) {
    this.index = index < 0 ? 0 : index;
    checkpoints = {};
    LapTime = 0;
    for (int i = 0; i < cp_qty; i++) checkpoints.InsertLast(Checkpoint(i));
    CheckpointCount = uint(checkpoints.Length);
  }

  int GetCheckpointTime(int cpIndex) const {
    if (cpIndex < 0 || cpIndex >= int(checkpoints.Length)) {
      throw("GetCheckpointTime: checkpoint index out of range (index=" + cpIndex + ", count=" + checkpoints.Length + ")");
    }
    Checkpoint@ cp = checkpoints[cpIndex];
    if (cp is null) {
      throw("GetCheckpointTime: checkpoint is null (index=" + cpIndex + ")");
    }
    return cp.time;
  }

  void SetCheckpointTime(int cpIndex, int time) {
    if (cpIndex < 0) {
      throw("SetCheckpointTime: negative checkpoint index not allowed (value=" + cpIndex + ")");
    }
    while (cpIndex >= int(checkpoints.Length)) {
      Checkpoint@ placeholder = Checkpoint(int(checkpoints.Length));
      checkpoints.InsertLast(placeholder);
    }
    Checkpoint@ cp = checkpoints[cpIndex];
    if (cp is null) {
      throw("SetCheckpointTime: checkpoint is null (index=" + cpIndex + ")");
    }
    // Actions: update LapTime incrementally instead of recomputing the full sum each time.
    int prev = cp.time;
    cp.time = time;
    LapTime += (time - prev);
    CheckpointCount = uint(checkpoints.Length);
  }
}

class Attempt {
  int id = 0;
  array<Lap@> laps;
  uint LapCount = 0;

  Attempt() {
    laps = {};
    LapCount = 0;
  }

  Attempt(int id, int lap_qty) {
    if (id < 0) throw("Attempt.ctor: negative id not allowed (value=" + id + ")");
    this.id = id;
    laps = {};
    LapCount = 0;
    for (int i = 0; i < lap_qty; i++) laps.InsertLast(Lap(i, 0));
    LapCount = uint(laps.Length);
  }

  Lap@ GetLap(int lapIndex) const {
    if (lapIndex < 0 || lapIndex >= int(laps.Length)) {
      throw("Attempt.GetLap: lap index out of range (index=" + lapIndex + ", count=" + laps.Length + ")");
    }
    Lap@ lap = laps[lapIndex];
    if (lap is null) {
      throw("Attempt.GetLap: lap is null (index=" + lapIndex + ")");
    }
    return lap;
  }

  void SetCheckpointTime(int lapIndex, int cpIndex, int time) {
    if (lapIndex < 0) {
      throw("Attempt.SetCheckpointTime: negative lap index not allowed (value=" + lapIndex + ")");
    }
    Lap@ lap;
    if (lapIndex >= int(laps.Length)) {
      laps.Resize(lapIndex + 1);
      LapCount = uint(laps.Length);
    }
    @lap = laps[lapIndex];
    if (lap is null) {
      @lap = Lap(lapIndex, 0);
      @laps[lapIndex] = lap;
    }
    lap.SetCheckpointTime(cpIndex, time);
  }

  // Returns lap/cp data as a 2D structure: [lap][cp] = time
  array<array<int>> ToLapCpArray() const {
    array<array<int>> result;
    for (uint li = 0; li < laps.Length; li++) {
      Lap@ lap = laps[li];
      if (lap is null) {
        throw("Attempt.ToLapCpArray: lap is null (index=" + li + ")");
      }
      array<int> row;
      uint cpCount = lap.CheckpointCount;
      for (uint ci = 0; ci < cpCount; ci++) {
        row.InsertLast(lap.GetCheckpointTime(int(ci)));
      }
      result.InsertLast(row);
    }
    return result;
  }
}

// Conversion helpers between raw 2D arrays and rich race types.

// Builds a Race from a [lap][cp] 2D array of CP deltas and an array of per-lap totals.
// Note: lap totals are derived by `Lap.get_LapTime()` summing checkpoint times.
Attempt@ RaceFromLapArrays(int attemptId, const array<array<int>> &in lapCpTimes) {
  Attempt@ race = Attempt();
  race.id = attemptId;

  uint numLaps = lapCpTimes.Length;
  for (uint lapIndex = 0; lapIndex < numLaps; lapIndex++) {
    array<int> cpRow = lapCpTimes[lapIndex];
    Lap@ lap = Lap(int(lapIndex), int(cpRow.Length));

    for (uint cpIndex = 0; cpIndex < cpRow.Length; cpIndex++) {
      // In-progress placeholders are stored as negative values (e.g. -1).
      // Skip them so the lap/attempt remains incomplete rather than throwing on negative checkpoint times.
      int cpTime = cpRow[cpIndex];
      if (cpTime < 0) continue;
      lap.SetCheckpointTime(int(cpIndex), cpTime);
    }

    race.laps.InsertLast(lap);
  }
  // Keep LapCount in sync when laps are inserted outside Attempt.SetCheckpointTime().
  race.LapCount = uint(race.laps.Length);

  return race;
}

// Extracts [lap][cp] CP times from a Race into a raw 2D array.
array<array<int>> LapArraysFromRace(Attempt@ race) {
  array<array<int>> result;
  for (uint lapIndex = 0; lapIndex < race.laps.Length; lapIndex++) {
    Lap@ lap = race.laps[lapIndex];
    if (lap is null) continue;
    array<int> row;
    uint cpCount = lap.CheckpointCount;
    for (uint cpIndex = 0; cpIndex < cpCount; cpIndex++) {
      row.InsertLast(lap.GetCheckpointTime(int(cpIndex)));
    }
    result.InsertLast(row);
  }
  return result;
}


