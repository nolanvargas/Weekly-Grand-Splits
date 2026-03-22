class RaceHistory {
  private array<Attempt@> _attempts;

  RaceHistory() {}

  // Removes all stored attempts, resetting the race history to empty.
  void Clear() {
    _attempts.RemoveRange(0, _attempts.Length);
  }

  // Returns the total number of attempts stored in this history.
  uint GetAttemptCount() const { return _attempts.Length; }

  // Returns the attempt at the given index, throwing on out-of-bounds.
  Attempt@ GetAttemptByIndex(uint idx) {
    if (idx >= _attempts.Length) throw("GetAttemptByIndex: index out of range (index=" + idx + ", count=" + _attempts.Length + ")");
    return _attempts[idx];
  }

  // Appends a normalized copy of the source attempt to history.
  void AddAttempt(Attempt@ src) {
    Attempt@ at = Attempt();
    array<array<int>> lapCp = LapArraysFromRace(src);
    for (uint lapIndex = 0; lapIndex < lapCp.Length; lapIndex++) {
      array<int> row = lapCp[lapIndex];
      for (uint cpIndex = 0; cpIndex < row.Length; cpIndex++) {
        at.SetCheckpointTime(int(lapIndex), int(cpIndex), row[cpIndex]);
      }
    }
    at.attemptId = src.attemptId;
    _attempts.InsertLast(at);
  }

  // Replaces a matching attempt by ID or appends if not found.
  void UpsertAttempt(Attempt@ src) {
    for (uint attemptSlot = 0; attemptSlot < _attempts.Length; attemptSlot++) {
      if (_attempts[attemptSlot].attemptId == src.attemptId) {
        Attempt@ at = Attempt();
        at.attemptId = src.attemptId;
        array<array<int>> lapCp = LapArraysFromRace(src);
        for (uint lapIndex = 0; lapIndex < lapCp.Length; lapIndex++) {
          array<int> row = lapCp[lapIndex];
          for (uint cpIndex = 0; cpIndex < row.Length; cpIndex++) {
            at.SetCheckpointTime(int(lapIndex), int(cpIndex), row[cpIndex]);
          }
        }
        @_attempts[attemptSlot] = at;
        return;
      }
    }
    AddAttempt(src);
  }

  // Returns one above the highest stored attempt ID in history.
  int ComputeNextAttemptId() const {
    int maxId = 0;
    for (uint i = 0; i < _attempts.Length; i++) {
      if (_attempts[i].attemptId > maxId) maxId = _attempts[i].attemptId;
    }
    return maxId;
  }

  // Serializes all stored attempts into a JSON object for saving.
  Json::Value@ ToJson() {
    Json::Value@ root = Json::Object();
    Json::Value@ attArr = Json::Array();
    for (uint attemptSlot = 0; attemptSlot < _attempts.Length; attemptSlot++) {
      Attempt@ src = _attempts[attemptSlot];
      if (src is null) continue;
      Json::Value@ atObj = Json::Object();
      atObj["id"] = Json::Value(src.attemptId);
      atObj["laps"] = BuildLapsJson2D(LapArraysFromRace(src));
      attArr.Add(atObj);
    }
    root["attempts"] = attArr;
    return root;
  }

  // Populates history from a parsed JSON object, replacing existing data.
  void FromJson(Json::Value@ root) {
    Clear();
    if (root is null || !root.HasKey("attempts")) return;
    Json::Value@ attArr = root["attempts"];
    for (uint attemptSlot = 0; attemptSlot < attArr.Length; attemptSlot++) {
      AddAttempt(Attempt(attArr[attemptSlot]));
    }
  }

  // Writes the history JSON for the given map to disk.
  void SaveToFile(const string&in mapId, int numCps) {
    if (mapId == "" || numCps == 0) return;
    if (_attempts.Length == 0) return;
    Json::ToFile(MapRaceHistoryJsonPath(mapId), ToJson(), true);
  }

  // Loads history from disk for the given map, returns success.
  bool TryLoadFromFile(const string&in mapId) {
    string jsonPath = MapRaceHistoryJsonPath(mapId);
    if (!IO::FileExists(jsonPath)) return false;

    Json::Value@ data = Json::FromFile(jsonPath);
    if (data is null) return false;

    FromJson(data);

    return true;
  }

  // Clears history and resets bests on g_state without touching disk.
  void InitEmptyState() {
    Clear();
    g_state.bests.Clear();
    @g_state.previousAttempt = null;
  }

  // Loads stored history from disk or initializes an empty state.
  void LoadData(const string &in mapId) {
    if (mapId == "" || !TryLoadFromFile(mapId)) {
      InitEmptyState();
      return;
    }
    g_state.bests.ComputeFromHistory(g_state.history, g_state.numLaps, g_state.numCps);
  }

  // Saves the current history data to disk for the active map.
  void SaveData() {
    SaveToFile(GetMapId(), g_state.numCps);
  }
}
