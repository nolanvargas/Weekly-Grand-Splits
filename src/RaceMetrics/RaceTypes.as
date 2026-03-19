// Shared race domain types: attempts, laps, and checkpoint splits.
// These are lightweight wrappers around the underlying int arrays used for storage.

class Checkpoint {
  private int _index = -1; // 0-based CP index within the lap
  private int _time = 0;   // time delta for this CP (ms)

  Checkpoint() {}

  Checkpoint(int index, int time) {
    set_index(index);
    set_time(time);
  }

  Checkpoint(int index) {
    set_index(index);
  }

  int get_index() const { return _index; }

  void set_index(int v) {
    if (v < 0) {
      throw("Checkpoint.set_index: negative index not allowed (value=" + v + ")");
    }
    _index = v;
  }

  int get_time() const { return _time; }

  void set_time(int v) {
    if (v < 0) {
      throw("Checkpoint.set_time: negative time not allowed (value=" + v + ")");
    }
    _time = v;
  }
}

class Lap {
  private int _index = 0; 
  private array<Checkpoint@> checkpoints;

  Lap() {}

  Lap(int index, int cp_qty) {
    set_index(index);
    for (int i = 0; i < cp_qty; i++) {
      Checkpoint@ cp = Checkpoint(i);
      checkpoints.InsertLast(cp);
    }
  }

  int get_index() const { return _index; }
  void set_index(int v) {
    _index = v < 0 ? 0 : v;
  }

  int get_LapTime() const {
    int total = 0;
    for (uint i = 0; i < checkpoints.Length; i++) {
      Checkpoint@ cp = checkpoints[i];
      if (cp is null) continue;
      total += cp.get_time();
    }
    return total;
  }

  uint get_CheckpointCount() const { return checkpoints.Length; }

  int GetCheckpointTime(int cpIndex) const {
    if (cpIndex < 0 || cpIndex >= int(checkpoints.Length)) {
      throw("GetCheckpointTime: checkpoint index out of range (index=" + cpIndex + ", count=" + checkpoints.Length + ")");
    }
    Checkpoint@ cp = checkpoints[cpIndex];
    if (cp is null) {
      throw("GetCheckpointTime: checkpoint is null (index=" + cpIndex + ")");
    }
    return cp.get_time();
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
    cp.set_time(time);
  }
}

// In-memory representation of a single race attempt.
class Attempt {
  private int _id = 0;
  private array<Lap@> _laps;

  Attempt() {}

  Attempt(int id, int lap_qty) {
    if (id < 0) {
      throw("Attempt.set_id: negative id not allowed (value=" + id + ")");
    }
    set_id(id);
    _laps.Resize(lap_qty);
    for (int i = 0; i < lap_qty; i++) {
      Lap@ lap = Lap(i, 0);
      _laps.InsertLast(lap);
    }
  }

  int get_id() const { return _id; }
  
  void set_id(int v) {
    if (v < 0) {
      throw("Attempt.set_id: negative id not allowed (value=" + v + ")");
    }
    _id = v;
  }

  uint get_LapCount() const { return _laps.Length; }

  array<Lap@>@ get_laps() { return _laps; }

  Lap@ GetLap(int lapIndex) const {
    if (lapIndex < 0 || lapIndex >= int(_laps.Length)) {
      throw("Attempt.GetLap: lap index out of range (index=" + lapIndex + ", count=" + _laps.Length + ")");
    }
    Lap@ lap = _laps[lapIndex];
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
    if (lapIndex >= int(_laps.Length)) {
      _laps.Resize(lapIndex + 1);
    }
    @lap = _laps[lapIndex];
    if (lap is null) {
      Lap@ newLap = Lap(lapIndex, 0);
      @lap = newLap;
      @_laps[lapIndex] = lap;
    }
    lap.SetCheckpointTime(cpIndex, time);
  }

  // Returns lap/cp data as a 2D structure: [lap][cp] = time
  array<array<int>> ToLapCpArray() const {
    array<array<int>> result;
    for (uint li = 0; li < _laps.Length; li++) {
      Lap@ lap = _laps[li];
      if (lap is null) {
        throw("Attempt.ToLapCpArray: lap is null (index=" + li + ")");
      }
      array<int> row;
      uint cpCount = lap.get_CheckpointCount();
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
Attempt@ RaceFromLapArrays(int attemptId, const array<array<int>> &in lapCpTimes, const int[] &in lapTotals) {
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

  return race;
}

// Extracts [lap][cp] CP times from a Race into a raw 2D array.
array<array<int>> LapArraysFromRace(Attempt@ race) {
  array<array<int>> result;
  for (uint lapIndex = 0; lapIndex < race.laps.Length; lapIndex++) {
    Lap@ lap = race.laps[lapIndex];
    if (lap is null) continue;
    array<int> row;
    uint cpCount = lap.get_CheckpointCount();
    for (uint cpIndex = 0; cpIndex < cpCount; cpIndex++) {
      row.InsertLast(lap.GetCheckpointTime(int(cpIndex)));
    }
    result.InsertLast(row);
  }
  return result;
}


