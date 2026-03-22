class Lap {
  int lapNumber = 0;
  array<Checkpoint@> checkpoints;

  Lap() { checkpoints = {}; }

  Lap(int index, int cp_qty) {
    lapNumber = index < 0 ? 0 : index;
    checkpoints = {};
    checkpoints.InsertLast(Checkpoint()); // phantom at index 0; CPs start at 1
    for (int checkpointSlot = 1; checkpointSlot <= cp_qty; checkpointSlot++) {
      checkpoints.InsertLast(Checkpoint());
    }
  }

  // from JSON (cpIndex in row is 0-based; stored 1-based internally)
  Lap(int lapIndex, Json::Value@ row) {
    lapNumber = lapIndex;
    checkpoints = {};
    checkpoints.InsertLast(Checkpoint()); // phantom at index 0; CPs start at 1
    for (uint cpIndex = 0; cpIndex < row.Length; cpIndex++) {
      checkpoints.InsertLast(Checkpoint(int(row[cpIndex])));
    }
  }

  // cpIndex is 1-based
  int GetCheckpointTime(int cpIndex) const {
    if (cpIndex < 1 || cpIndex >= int(checkpoints.Length)) {
      throw("GetCheckpointTime: checkpoint index out of range (index=" + cpIndex + ", count=" + checkpoints.Length + ")");
    }
    return checkpoints[cpIndex].time;
  }

  // Sums all real CP times (skips phantom at index 0).
  int GetLapTime() const {
    int total = 0;
    for (uint cp_idx = 1; cp_idx < checkpoints.Length; cp_idx++) { // CPs start at 1
      total += checkpoints[cp_idx].time;
    }
    return total;
  }

  // Next sequential split (e.g. live run). Inserts phantom on first call.
  void AppendCheckpointTime(int splitMs) {
    if (checkpoints.Length == 0) {
      checkpoints.InsertLast(Checkpoint()); // phantom at index 0; CPs start at 1
    }
    checkpoints.InsertLast(Checkpoint(splitMs));
  }

  // Overwrite an existing split, or append the next split. cpIndex is 1-based. No sparse gaps.
  void SetCheckpointTime(int cpIndex, int time) {
    if (cpIndex < 1) {
      throw("SetCheckpointTime: checkpoint index must be >= 1 (value=" + cpIndex + ")");
    }
    // ensure phantom exists at [0]
    if (checkpoints.Length == 0) {
      checkpoints.InsertLast(Checkpoint());
    }
    int len = int(checkpoints.Length);
    if (cpIndex < len) {
      checkpoints[cpIndex].time = time;
      return;
    }
    if (cpIndex == len) {
      checkpoints.InsertLast(Checkpoint(time));
      return;
    }
    throw("SetCheckpointTime: checkpoint index out of range (index=" + cpIndex + ", length=" + len + ")");
  }
}
