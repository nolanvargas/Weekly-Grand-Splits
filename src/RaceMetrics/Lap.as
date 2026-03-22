class Lap {
  int lapNumber = 0;
  array<Checkpoint@> checkpoints;

  // Creates an empty lap and initializes an empty checkpoint array.
  Lap() { checkpoints = {}; }

  // Constructs a lap with a phantom slot and cpQty real checkpoints.
  Lap(int index, int cpQty) {
    lapNumber = index < 0 ? 0 : index;
    checkpoints = {};
    checkpoints.InsertLast(Checkpoint()); // phantom at index 0; CPs start at 1
    for (int checkpointSlot = 1; checkpointSlot <= cpQty; checkpointSlot++) {
      checkpoints.InsertLast(Checkpoint());
    }
  }

  // Deserializes a lap from a JSON array of checkpoint times.
  Lap(int lapIndex, Json::Value@ row) {
    lapNumber = lapIndex;
    checkpoints = {};
    checkpoints.InsertLast(Checkpoint()); // phantom at index 0; CPs start at 1
    for (uint cpIndex = 0; cpIndex < row.Length; cpIndex++) {
      checkpoints.InsertLast(Checkpoint(int(row[cpIndex])));
    }
  }

  // Returns the checkpoint split time at the given one-based index.
  int GetCheckpointTime(int cpIndex) const {
    if (cpIndex < 1 || cpIndex >= int(checkpoints.Length)) {
      throw("GetCheckpointTime: checkpoint index out of range (index=" + cpIndex + ", count=" + checkpoints.Length + ")");
    }
    return checkpoints[cpIndex].time;
  }

  // Sums all real checkpoint times, skipping the phantom at index zero.
  int GetLapTime() const {
    int total = 0;
    for (uint cpIdx = 1; cpIdx < checkpoints.Length; cpIdx++) { // CPs start at 1
      total += checkpoints[cpIdx].time;
    }
    return total;
  }

  // Appends the next sequential split to this lap's checkpoint list.
  void AppendCheckpointTime(int splitMs) {
    if (checkpoints.Length == 0) {
      checkpoints.InsertLast(Checkpoint()); // phantom at index 0; CPs start at 1
    }
    checkpoints.InsertLast(Checkpoint(splitMs));
  }

  // Overwrites or appends a checkpoint time at the given index.
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
