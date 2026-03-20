class Lap {
  int lapNumber = 0;
  array<Checkpoint@> checkpoints;

  Lap() { checkpoints = {}; }

  Lap(int index, int cp_qty) {
    lapNumber = index < 0 ? 0 : index;
    checkpoints = {};
    for (int checkpointSlot = 0; checkpointSlot < cp_qty; checkpointSlot++) {
      checkpoints.InsertLast(Checkpoint(checkpointSlot));
    }
  }

  // from JSON
  Lap(int lapIndex, Json::Value@ row) {
    lapNumber = lapIndex;
    checkpoints = {};
    for (uint cpIndex = 0; cpIndex < row.Length; cpIndex++) {
      checkpoints.InsertLast(Checkpoint(int(cpIndex), int(row[cpIndex])));
    }
  }

  int GetCheckpointTime(int cpIndex) const {
    if (cpIndex < 0 || cpIndex >= int(checkpoints.Length)) {
      throw("GetCheckpointTime: checkpoint index out of range (index=" + cpIndex + ", count=" + checkpoints.Length + ")");
    }
    return checkpoints[cpIndex].time;
  }

  int GetLapTime() const {
    int total = 0;
    for (uint cp_idx = 0; cp_idx < checkpoints.Length; cp_idx++) {
      Checkpoint@ cp = checkpoints[cp_idx];
      total += cp.time;
    }
    return total;
  }

  // Next sequential split (e.g. live run)
  void AppendCheckpointTime(int splitMs) {
    checkpoints.InsertLast(Checkpoint(int(checkpoints.Length), splitMs));
  }

  // Overwrite an existing split, or append the next split (cpIndex must be current Length). No sparse gaps.
  void SetCheckpointTime(int cpIndex, int time) {
    if (cpIndex < 0) {
      throw("SetCheckpointTime: negative checkpoint index not allowed (value=" + cpIndex + ")");
    }
    int len = int(checkpoints.Length);
    if (cpIndex < len) {
      checkpoints[cpIndex].time = time;
      return;
    }
    if (cpIndex == len) {
      checkpoints.InsertLast(Checkpoint(cpIndex, time));
      return;
    }
    throw("SetCheckpointTime: checkpoint index out of range (index=" + cpIndex + ", length=" + len + ")");
  }
}
