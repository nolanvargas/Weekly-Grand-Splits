class Attempt {
  int attemptId = 0;
  array<Lap@> laps;

  // Constructs a default empty attempt with no laps or ID.
  Attempt() {
    laps = {};
  }

  // Constructs an attempt with a given ID and pre-built lap slots.
  Attempt(int id, int lapQty) {
    this.attemptId = id;
    laps = {};
    for (int lapSlot = 0; lapSlot < lapQty; lapSlot++) {
      laps.InsertLast(Lap(lapSlot+1, 0)); // Laps start at 1
    }
  }

  // Deserializes an attempt from a JSON object read from disk.
  Attempt(Json::Value@ atObj) {
    laps = {};
    attemptId = int(atObj["id"]);
    laps.InsertLast(Lap(0, 0)); // phantom at index 0; Laps start at 1
    Json::Value@ outer = atObj["laps"];
    for (uint lapIndex = 0; lapIndex < outer.Length; lapIndex++) {
      laps.InsertLast(Lap(int(lapIndex + 1), outer[lapIndex]));
    }
  }

  // Returns the lap object stored at the given one-based index.
  Lap@ GetLap(int lapIndex) const {
    Lap@ lap = laps[lapIndex];
    return lap;
  }

  // Returns or creates the lap at the given index as needed.
  private Lap@ GetOrCreateLap(int lapIndex) {
    if (lapIndex >= int(laps.Length)) {
      laps.Resize(lapIndex + 1);
    }
    Lap@ lap = laps[lapIndex];
    if (lap is null) {
      @lap = Lap(lapIndex, 0);
      @laps[lapIndex] = lap;
    }
    return lap;
  }

  // Writes a checkpoint time using zero-based lap and CP indices.
  void SetCheckpointTime(int lapIndex, int cpIndex, int time) {
    GetOrCreateLap(lapIndex+1).SetCheckpointTime(cpIndex+1, time); // Laps and CPs start at 1
  }

  // Returns true if any lap has at least one real checkpoint recorded.
  bool HasAnyCheckpoints() const {
    for (uint i = 0; i < laps.Length; i++) {
      if (laps[i] !is null && laps[i].checkpoints.Length > 1) return true;
    }
    return false;
  }

  // Appends the next sequential checkpoint split to the current lap.
  void AppendCheckpointTime(int lapIndex, int splitMs) {
    GetOrCreateLap(lapIndex).AppendCheckpointTime(splitMs); // Laps start at 1
  }
}
