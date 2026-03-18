// Builds a Json array from a 2D int array.
Json::Value@ Build2DArray(const array<array<int>>@ data) {
  Json::Value@ outer = Json::Array();
  for (uint i = 0; i < data.Length; i++) {
    Json::Value@ inner = Json::Array();
    for (uint j = 0; j < data[i].Length; j++) {
      inner.Add(Json::Value(data[i][j]));
    }
    outer.Add(inner);
  }
  return outer;
}

// Reads a 2D Json array into an array<array<int>>.
array<array<int>> Read2DArray(Json::Value@ outer) {
  array<array<int>> result;
  for (uint i = 0; i < outer.Length; i++) {
    array<int> row;
    Json::Value@ inner = outer[i];
    for (uint j = 0; j < inner.Length; j++) {
      row.InsertLast(int(inner[j]));
    }
    result.InsertLast(row);
  }
  return result;
}

class StorageAttempt {
  int id = 0;
  array<array<int>> laps;
}

class StorageFile {
  int version = 1;
  array<StorageAttempt> attempts;
  int pbAttemptId = -1;
  array<array<int>> pbLaps;
  int[] lapBests = {0,0,0,0,0,0,0,0,0,0};
  array<array<int>> cpBests;

  Json::Value@ ToJson() {
    Json::Value@ root = Json::Object();
    root["version"] = Json::Value(version);

    Json::Value@ attArr = Json::Array();
    for (uint i = 0; i < attempts.Length; i++) {
      Json::Value@ atObj = Json::Object();
      atObj["id"] = Json::Value(attempts[i].id);
      atObj["laps"] = Build2DArray(attempts[i].laps);
      attArr.Add(atObj);
    }
    root["attempts"] = attArr;

    if (pbAttemptId >= 0 && pbLaps.Length > 0) {
      Json::Value@ pbObj = Json::Object();
      pbObj["attempt_id"] = Json::Value(pbAttemptId);
      pbObj["laps"] = Build2DArray(pbLaps);
      root["pb"] = pbObj;
    }

    Json::Value@ lbArr = Json::Array();
    for (int i = 0; i < MAX_LAPS; i++) lbArr.Add(Json::Value(lapBests[i]));
    root["lap_bests"] = lbArr;

    if (cpBests.Length > 0) root["cp_bests"] = Build2DArray(cpBests);

    return root;
  }

  void FromJson(Json::Value@ root) {
    version = root.HasKey("version") ? int(root["version"]) : 1;

    attempts = {};
    if (root.HasKey("attempts")) {
      Json::Value@ attArr = root["attempts"];
      for (uint i = 0; i < attArr.Length; i++) {
        Json::Value@ atObj = attArr[i];
        if (!atObj.HasKey("id") || !atObj.HasKey("laps")) continue;
        StorageAttempt at;
        at.id = int(atObj["id"]);
        at.laps = Read2DArray(atObj["laps"]);
        attempts.InsertLast(at);
      }
    }

    pbAttemptId = -1;
    pbLaps = {};
    if (root.HasKey("pb")) {
      Json::Value@ pb = root["pb"];
      pbAttemptId = pb.HasKey("attempt_id") ? int(pb["attempt_id"]) : -1;
      if (pb.HasKey("laps")) pbLaps = Read2DArray(pb["laps"]);
    }

    lapBests = {0,0,0,0,0,0,0,0,0,0};
    if (root.HasKey("lap_bests")) {
      Json::Value@ lb = root["lap_bests"];
      for (uint i = 0; i < lb.Length && i < MAX_LAPS; i++) lapBests[i] = int(lb[i]);
    }

    cpBests = {};
    if (root.HasKey("cp_bests")) cpBests = Read2DArray(root["cp_bests"]);
  }
}

StorageFile g_storage;

string MapJsonPath(const string&in mapId) {
  IO::CreateFolder(IO::FromStorageFolder("maps"));
  return IO::FromStorageFolder("maps/" + mapId + ".json");
}

// Syncs g_state into g_storage, then serializes to JSON.
Json::Value@ BuildStateJson() {
  g_storage.version = 1;
  g_storage.attempts = {};
  for (uint ai = 0; ai < g_state.allAttempts.Length; ai++) {
    StorageAttempt at;
    at.id = g_state.allAttemptIds[ai];
    at.laps = g_state.allAttempts[ai];
    g_storage.attempts.InsertLast(at);
  }

  // in-progress attempt with -1 placeholders for unvisited CPs
  bool hasCurrentData = g_state.currLapCpTimes.Length > 0 || g_state.currentLap > 0;
  if (hasCurrentData && !g_state.isFinished) {
    StorageAttempt at;
    at.id = g_state.currentAttemptId;

    for (int li = 0; li < g_state.currentLap && li < int(g_state.allLapCpTimes.Length); li++) {
      at.laps.InsertLast(g_state.allLapCpTimes[li]);
    }

    array<int> curLap;
    for (uint ci = 0; ci < g_state.currLapCpTimes.Length; ci++) curLap.InsertLast(g_state.currLapCpTimes[ci]);
    int remaining = g_state.numCps - int(g_state.currLapCpTimes.Length);
    for (int pi = 0; pi < remaining; pi++) curLap.InsertLast(-1);
    at.laps.InsertLast(curLap);

    g_storage.attempts.InsertLast(at);
  }

  g_storage.pbAttemptId = g_state.pbAttemptId;
  g_storage.pbLaps = g_state.bestLapCpTimes;
  for (int i = 0; i < MAX_LAPS; i++) g_storage.lapBests[i] = g_state.bestAllTimeLapTimes[i];
  g_storage.cpBests = g_state.bestAllTimeCpTimes;

  return g_storage.ToJson();
}

// Writes all state to JSON. Guarded: won't write until there is something to save.
void SaveData() {
  string mapId = GetMapId();
  if (mapId == "" || g_state.numCps == 0) return;
  if (g_state.allAttempts.Length == 0 && g_state.currLapCpTimes.Length == 0 && g_state.allLapCpTimes.Length == 0) return;
  Json::ToFile(MapJsonPath(mapId), BuildStateJson(), true);
}

// Resets all history/PB state. Called from ResetCommon() on map change.
void InitEmptyState() {
  g_state.allAttempts = {};
  g_state.allAttemptIds = {};
  g_state.pbAttemptId = -1;
  g_state.currentAttemptId = 1;
}

int ComputeNextAttemptId() {
  int maxId = 0;
  for (uint i = 0; i < g_state.allAttemptIds.Length; i++) {
    if (g_state.allAttemptIds[i] > maxId) maxId = g_state.allAttemptIds[i];
  }
  return maxId + 1;
}

// Populates g_storage from JSON, then syncs into g_state.
void PopulateStateFromJson(Json::Value@ root) {
  g_storage.FromJson(root);

  g_state.allAttempts = {};
  g_state.allAttemptIds = {};
  for (uint i = 0; i < g_storage.attempts.Length; i++) {
    g_state.allAttemptIds.InsertLast(g_storage.attempts[i].id);
    g_state.allAttempts.InsertLast(g_storage.attempts[i].laps);
  }
  g_state.currentAttemptId = ComputeNextAttemptId();

  g_state.pbAttemptId = g_storage.pbAttemptId;
  if (g_storage.pbLaps.Length > 0 && int(g_storage.pbLaps.Length) == g_state.numLaps) {
    g_state.bestLapCpTimes = {};
    for (uint li = 0; li < g_storage.pbLaps.Length; li++) {
      int sum = 0;
      for (uint ci = 0; ci < g_storage.pbLaps[li].Length; ci++) sum += g_storage.pbLaps[li][ci];
      g_state.bestLapCpTimes.InsertLast(g_storage.pbLaps[li]);
      g_state.SetBestLapTime(int(li), sum);
    }
  }

  for (int i = 0; i < MAX_LAPS; i++) g_state.SetBestAllTimeLapTime(i, g_storage.lapBests[i]);
  g_state.bestAllTimeCpTimes = g_storage.cpBests;
}

void LoadData() {
  string mapId = GetMapId();
  if (mapId == "") { InitEmptyState(); return; }

  string jsonPath = MapJsonPath(mapId);
  if (IO::FileExists(jsonPath)) {
    Json::Value@ data = Json::FromFile(jsonPath);
    if (data is null || !data.HasKey("version")) {
      InitEmptyState();
      return;
    }
    PopulateStateFromJson(data);
  } else {
    InitEmptyState();
  }
}
