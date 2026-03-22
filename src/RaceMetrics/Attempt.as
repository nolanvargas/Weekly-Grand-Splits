class Attempt {
  int attemptId = 0;
  array<Lap@> laps;

  Attempt() {
    laps = {};
  }

  Attempt(int id, int lap_qty) {
    this.attemptId = id;
    laps = {};
    for (int lapSlot = 0; lapSlot < lap_qty; lapSlot++) {
      laps.InsertLast(Lap(lapSlot+1, 0)); // Laps start at 1
    }
  }

  // from JSON
  Attempt(Json::Value@ atObj) {
    laps = {};
    attemptId = int(atObj["id"]);
    laps.InsertLast(Lap(0, 0)); // phantom at index 0; Laps start at 1
    Json::Value@ outer = atObj["laps"];
    for (uint lapIndex = 0; lapIndex < outer.Length; lapIndex++) {
      laps.InsertLast(Lap(int(lapIndex + 1), outer[lapIndex]));
    }
  }

  Lap@ GetLap(int lapIndex) const {
    Lap@ lap = laps[lapIndex];
    return lap;
  }

  // Ensures laps[lapIndex] exists (resize + empty Lap) for SetCheckpointTime / AppendCheckpointTime.
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

  // Will auto-add new laps as needed
  void SetCheckpointTime(int lapIndex, int cpIndex, int time) {
    GetOrCreateLap(lapIndex+1).SetCheckpointTime(cpIndex+1, time); // Laps and CPs start at 1
  }

  // Next checkpoint reached in a run
  void AppendCheckpointTime(int lapIndex, int splitMs) {
    GetOrCreateLap(lapIndex).AppendCheckpointTime(splitMs); // Laps start at 1
  }
}
