string MapJsonPath(const string&in mapId) {
  return IO::FromStorageFolder(mapId + ".json");
}

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

// Builds the full JSON tree from current in-memory state.
Json::Value@ BuildStateJson() {
  Json::Value@ root = Json::Object();
  root["version"] = Json::Value(1);

  // attempts: all historical + current attempt's complete laps so far
  Json::Value@ attemptsArr = Json::Array();
  for (uint ai = 0; ai < g_state.allAttempts.Length; ai++) {
    Json::Value@ atObj = Json::Object();
    atObj["id"] = Json::Value(g_state.allAttemptIds[ai]);
    atObj["laps"] = Build2DArray(g_state.allAttempts[ai]);
    attemptsArr.Add(atObj);
  }
  if (g_state.currentLap > 0 && g_state.allLapCpTimes.Length > 0) {
    Json::Value@ atObj = Json::Object();
    atObj["id"] = Json::Value(g_state.currentAttemptId);
    Json::Value@ lapsArr = Json::Array();
    for (int li = 0; li < g_state.currentLap && li < int(g_state.allLapCpTimes.Length); li++) {
      Json::Value@ lapArr = Json::Array();
      for (uint ci = 0; ci < g_state.allLapCpTimes[li].Length; ci++) {
        lapArr.Add(Json::Value(g_state.allLapCpTimes[li][ci]));
      }
      lapsArr.Add(lapArr);
    }
    atObj["laps"] = lapsArr;
    attemptsArr.Add(atObj);
  }
  root["attempts"] = attemptsArr;

  // in_progress: partial current lap (only if CPs have been hit)
  if (!g_state.isFinished && g_state.currLapCpTimes.Length > 0) {
    Json::Value@ ip = Json::Object();
    ip["id"] = Json::Value(g_state.currentAttemptId);
    ip["lap"] = Json::Value(g_state.currentLap + 1);
    Json::Value@ cpsArr = Json::Array();
    for (uint ci = 0; ci < g_state.currLapCpTimes.Length; ci++) {
      cpsArr.Add(Json::Value(g_state.currLapCpTimes[ci]));
    }
    ip["cps"] = cpsArr;
    root["in_progress"] = ip;
  }

  // pb
  if (g_state.bestLapCpTimes.Length > 0) {
    Json::Value@ pbObj = Json::Object();
    pbObj["attempt_id"] = Json::Value(g_state.pbAttemptId);
    pbObj["laps"] = Build2DArray(g_state.bestLapCpTimes);
    root["pb"] = pbObj;
  }

  // lap_bests
  Json::Value@ lapBestsArr = Json::Array();
  for (int i = 0; i < MAX_LAPS; i++) lapBestsArr.Add(Json::Value(g_state.bestAllTimeLapTimes[i]));
  root["lap_bests"] = lapBestsArr;

  // cp_bests
  if (g_state.bestAllTimeCpTimes.Length > 0) {
    root["cp_bests"] = Build2DArray(g_state.bestAllTimeCpTimes);
  }

  return root;
}

// Writes all state to JSON. Guarded: won't write before the player has raced.
void SaveData() {
  string mapId = GetMapId();
  if (mapId == "" || g_state.numCps == 0 || !g_state.hasPlayerRaced) return;
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

void PopulateStateFromJson(Json::Value@ root) {
  // attempts
  g_state.allAttempts = {};
  g_state.allAttemptIds = {};
  if (root.HasKey("attempts")) {
    Json::Value@ attArr = root["attempts"];
    for (uint ai = 0; ai < attArr.Length; ai++) {
      Json::Value@ atObj = attArr[ai];
      if (!atObj.HasKey("id") || !atObj.HasKey("laps")) continue;
      g_state.allAttemptIds.InsertLast(int(atObj["id"]));
      g_state.allAttempts.InsertLast(Read2DArray(atObj["laps"]));
    }
  }
  g_state.currentAttemptId = ComputeNextAttemptId();

  // pb
  if (root.HasKey("pb")) {
    Json::Value@ pb = root["pb"];
    g_state.pbAttemptId = pb.HasKey("attempt_id") ? int(pb["attempt_id"]) : -1;
    if (pb.HasKey("laps")) {
      Json::Value@ pbLaps = pb["laps"];
      if (int(pbLaps.Length) == g_state.numLaps) {
        g_state.bestLapCpTimes = {};
        for (uint li = 0; li < pbLaps.Length; li++) {
          array<int> cpRow;
          int sum = 0;
          Json::Value@ cps = pbLaps[li];
          for (uint ci = 0; ci < cps.Length; ci++) {
            int t = int(cps[ci]);
            cpRow.InsertLast(t);
            sum += t;
          }
          g_state.bestLapCpTimes.InsertLast(cpRow);
          g_state.SetBestLapTime(int(li), sum);
        }
      }
    }
  }

  // lap_bests
  if (root.HasKey("lap_bests")) {
    Json::Value@ lb = root["lap_bests"];
    for (uint i = 0; i < lb.Length && i < MAX_LAPS; i++) {
      g_state.SetBestAllTimeLapTime(int(i), int(lb[i]));
    }
  }

  // cp_bests
  if (root.HasKey("cp_bests")) {
    g_state.bestAllTimeCpTimes = Read2DArray(root["cp_bests"]);
  }
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
