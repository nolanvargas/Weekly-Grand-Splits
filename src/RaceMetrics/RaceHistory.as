class RaceHistory {
  private array<Attempt@> _attempts;

  RaceHistory() {}

  void Clear() {
    _attempts.RemoveRange(0, _attempts.Length);
  }


  uint GetAttemptCount() const { return _attempts.Length; }

  Attempt@ GetAttemptByIndex(uint idx) {
    if (idx >= _attempts.Length) throw("GetAttemptByIndex: index out of range (index=" + idx + ", count=" + _attempts.Length + ")");
    return _attempts[idx];
  }

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

  // If a player does not reach any checkpoints, we may end up with an empty attempt
  // (e.g. if they quit immediately after starting). We are not recording these attempts
  // so the length of the array is not a reliable attempt count
  int ComputeNextAttemptId() const {
    int maxId = 0;
    for (uint i = 0; i < _attempts.Length; i++) {
      if (_attempts[i].attemptId > maxId) maxId = _attempts[i].attemptId;
    }
    return maxId;
  }

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

  void FromJson(Json::Value@ root) {
    Clear();
    if (root is null || !root.HasKey("attempts")) return;
    Json::Value@ attArr = root["attempts"];
    for (uint attemptSlot = 0; attemptSlot < attArr.Length; attemptSlot++) {
      AddAttempt(Attempt(attArr[attemptSlot]));
    }
  }

  void SaveToFile(const string&in mapId, int numCps) {
    if (mapId == "" || numCps == 0) return;
    if (_attempts.Length == 0) return;
    Json::ToFile(MapRaceHistoryJsonPath(mapId), ToJson(), true);
  }

  bool TryLoadFromFile(const string&in mapId) {
    string jsonPath = MapRaceHistoryJsonPath(mapId);
    if (!IO::FileExists(jsonPath)) return false;

    Json::Value@ data = Json::FromFile(jsonPath);
    if (data is null) return false;
    
    FromJson(data);

    return true;
  }

  // Clears history and related session fields on g_state (no JSON).
  void InitEmptyState() {
    Clear();
    g_state.bests.Clear();
    @g_state.previousAttempt = null;
  }

  void LoadData(const string &in mapId) {
    if (mapId == "" || !TryLoadFromFile(mapId)) {
      InitEmptyState();
      return;
    }
    g_state.bests.ComputeFromHistory(g_state.history, g_state.numLaps, g_state.numCps);
  }

  void SaveData() {
    SaveToFile(GetMapId(), g_state.numCps);
  }
}
