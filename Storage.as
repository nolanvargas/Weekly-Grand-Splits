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
  for (uint ai = 0; ai < g_allAttempts.Length; ai++) {
    Json::Value@ atObj = Json::Object();
    atObj["id"] = Json::Value(g_allAttemptIds[ai]);
    atObj["laps"] = Build2DArray(g_allAttempts[ai]);
    attemptsArr.Add(atObj);
  }
  if (currentLap > 0 && allLapCpTimes.Length > 0) {
    Json::Value@ atObj = Json::Object();
    atObj["id"] = Json::Value(currentAttemptId);
    Json::Value@ lapsArr = Json::Array();
    for (int li = 0; li < currentLap && li < int(allLapCpTimes.Length); li++) {
      Json::Value@ lapArr = Json::Array();
      for (uint ci = 0; ci < allLapCpTimes[li].Length; ci++) {
        lapArr.Add(Json::Value(allLapCpTimes[li][ci]));
      }
      lapsArr.Add(lapArr);
    }
    atObj["laps"] = lapsArr;
    attemptsArr.Add(atObj);
  }
  root["attempts"] = attemptsArr;

  // in_progress: partial current lap (only if CPs have been hit)
  if (!isFinished && currLapCpTimes.Length > 0) {
    Json::Value@ ip = Json::Object();
    ip["id"] = Json::Value(currentAttemptId);
    ip["lap"] = Json::Value(currentLap + 1);
    Json::Value@ cpsArr = Json::Array();
    for (uint ci = 0; ci < currLapCpTimes.Length; ci++) {
      cpsArr.Add(Json::Value(currLapCpTimes[ci]));
    }
    ip["cps"] = cpsArr;
    root["in_progress"] = ip;
  }

  // pb
  if (bestLapCpTimes.Length > 0) {
    Json::Value@ pbObj = Json::Object();
    pbObj["attempt_id"] = Json::Value(g_pbAttemptId);
    pbObj["laps"] = Build2DArray(bestLapCpTimes);
    root["pb"] = pbObj;
  }

  // lap_bests
  Json::Value@ lapBestsArr = Json::Array();
  for (int i = 0; i < 10; i++) lapBestsArr.Add(Json::Value(bestAllTimeLapTimes[i]));
  root["lap_bests"] = lapBestsArr;

  // cp_bests
  if (bestAllTimeCpTimes.Length > 0) {
    root["cp_bests"] = Build2DArray(bestAllTimeCpTimes);
  }

  return root;
}

// Writes all state to JSON. Guarded: won't write before the player has raced.
void SaveData() {
  string mapId = GetMapId();
  if (mapId == "" || numCps == 0 || !hasPlayerRaced) return;
  Json::ToFile(MapJsonPath(mapId), BuildStateJson(), true);
}

// Resets all history/PB state. Called from ResetCommon() on map change.
void InitEmptyState() {
  g_allAttempts = {};
  g_allAttemptIds = {};
  g_pbAttemptId = -1;
  currentAttemptId = 1;
}

int ComputeNextAttemptId() {
  int maxId = 0;
  for (uint i = 0; i < g_allAttemptIds.Length; i++) {
    if (g_allAttemptIds[i] > maxId) maxId = g_allAttemptIds[i];
  }
  return maxId + 1;
}

void PopulateStateFromJson(Json::Value@ root) {
  // attempts
  g_allAttempts = {};
  g_allAttemptIds = {};
  if (root.HasKey("attempts")) {
    Json::Value@ attArr = root["attempts"];
    for (uint ai = 0; ai < attArr.Length; ai++) {
      Json::Value@ atObj = attArr[ai];
      if (!atObj.HasKey("id") || !atObj.HasKey("laps")) continue;
      g_allAttemptIds.InsertLast(int(atObj["id"]));
      g_allAttempts.InsertLast(Read2DArray(atObj["laps"]));
    }
  }
  currentAttemptId = ComputeNextAttemptId();

  // pb
  if (root.HasKey("pb")) {
    Json::Value@ pb = root["pb"];
    g_pbAttemptId = pb.HasKey("attempt_id") ? int(pb["attempt_id"]) : -1;
    if (pb.HasKey("laps")) {
      Json::Value@ pbLaps = pb["laps"];
      if (int(pbLaps.Length) == numLaps) {
        bestLapCpTimes = {};
        for (uint li = 0; li < pbLaps.Length; li++) {
          array<int> cpRow;
          int sum = 0;
          Json::Value@ cps = pbLaps[li];
          for (uint ci = 0; ci < cps.Length; ci++) {
            int t = int(cps[ci]);
            cpRow.InsertLast(t);
            sum += t;
          }
          bestLapCpTimes.InsertLast(cpRow);
          bestLapTimes[li] = sum;
        }
      }
    }
  }

  // lap_bests
  if (root.HasKey("lap_bests")) {
    Json::Value@ lb = root["lap_bests"];
    for (uint i = 0; i < lb.Length && i < 10; i++) {
      bestAllTimeLapTimes[i] = int(lb[i]);
    }
  }

  // cp_bests
  if (root.HasKey("cp_bests")) {
    bestAllTimeCpTimes = Read2DArray(root["cp_bests"]);
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
  } else if (IO::FileExists(IO::FromStorageFolder(mapId + ".csv"))) {
    MigrateFromCsv();
  } else {
    InitEmptyState();
  }
}

// -------------------------------------------------------------------------
// One-time migration from old CSV files. Old files are left intact as backup.
// -------------------------------------------------------------------------

int MigStoI(const string&in s) {
  int result = 0;
  bool neg = false;
  uint64 i = 0;
  if (s.Length > 0 && s.SubStr(0, 1) == "-") { neg = true; i = 1; }
  for (; i < s.Length; i++) {
    uint8 c = s[i];
    if (c < uint8(48) || c > uint8(57)) break;
    result = result * 10 + int(c - uint8(48));
  }
  return neg ? -result : result;
}

void MigrateFromCsv() {
  string mapId = GetMapId();

  // 1. Main CSV → g_allAttempts / g_allAttemptIds
  string csvPath = IO::FromStorageFolder(mapId + ".csv");
  if (IO::FileExists(csvPath)) {
    IO::File f(csvPath, IO::FileMode::Read);
    f.ReadLine(); // skip header

    dictionary attemptIndex; // string(attemptId) → index in g_allAttempts

    while (!f.EOF()) {
      string line = f.ReadLine();
      if (line.Length == 0) continue;
      string[] cols = line.Split(",");
      if (cols.Length < 3) continue;

      int attemptId = MigStoI(cols[0]);
      int lapNum    = MigStoI(cols[1]) - 1;
      if (lapNum < 0 || lapNum >= 10) continue;

      bool hasZero = false;
      int[] cpTimes;
      for (uint j = 2; j < cols.Length; j++) {
        if (cols[j].Length > 0) {
          int t = MigStoI(cols[j]);
          if (t == 0) { hasZero = true; break; }
          cpTimes.InsertLast(t);
        }
      }
      if (hasZero || cpTimes.Length == 0) continue;

      string key = "" + attemptId;
      int idx;
      if (attemptIndex.Exists(key)) {
        attemptIndex.Get(key, idx);
      } else {
        idx = int(g_allAttempts.Length);
        array<array<int>> emptyAttempt;
        g_allAttempts.InsertLast(emptyAttempt);
        g_allAttemptIds.InsertLast(attemptId);
        attemptIndex[key] = idx;
      }
      while (int(g_allAttempts[idx].Length) <= lapNum) {
        int[] empty;
        g_allAttempts[idx].InsertLast(empty);
      }
      g_allAttempts[idx][lapNum] = cpTimes;
    }
    f.Close();
  }

  // 2. PB CSV → bestLapCpTimes / bestLapTimes
  string pbPath = IO::FromStorageFolder(mapId + "_pb.csv");
  if (IO::FileExists(pbPath)) {
    IO::File f(pbPath, IO::FileMode::Read);
    while (!f.EOF()) {
      string line = f.ReadLine();
      if (line.Length == 0) continue;
      string[] cols = line.Split(",");
      if (cols.Length < 2) continue;
      int lapIdx = MigStoI(cols[0]) - 1;
      if (lapIdx < 0 || lapIdx >= 10) continue;

      bool hasZero = false;
      int[] cpTimes;
      int sum = 0;
      for (uint j = 1; j < cols.Length; j++) {
        if (cols[j].Length > 0) {
          int t = MigStoI(cols[j]);
          if (t == 0) { hasZero = true; break; }
          cpTimes.InsertLast(t);
          sum += t;
        }
      }
      if (hasZero || sum == 0) continue;

      while (int(bestLapCpTimes.Length) <= lapIdx) {
        int[] empty;
        bestLapCpTimes.InsertLast(empty);
      }
      bestLapCpTimes[lapIdx] = cpTimes;
      bestLapTimes[lapIdx] = sum;
    }
    f.Close();
    if (int(bestLapCpTimes.Length) != numLaps) {
      bestLapCpTimes = {};
      for (int i = 0; i < 10; i++) bestLapTimes[i] = -1;
    }
  }

  // 3. Lap bests CSV → bestAllTimeLapTimes
  string lapBestsPath = IO::FromStorageFolder(mapId + "_lap_bests.csv");
  if (IO::FileExists(lapBestsPath)) {
    IO::File f(lapBestsPath, IO::FileMode::Read);
    while (!f.EOF()) {
      string line = f.ReadLine();
      if (line.Length == 0) continue;
      string[] cols = line.Split(",");
      if (cols.Length < 2) continue;
      int lapIdx = MigStoI(cols[0]) - 1;
      if (lapIdx < 0 || lapIdx >= 10) continue;
      int t = MigStoI(cols[1]);
      if (t > 0) bestAllTimeLapTimes[lapIdx] = t;
    }
    f.Close();
  }

  // 4. CP bests CSV → bestAllTimeCpTimes
  string cpBestsPath = IO::FromStorageFolder(mapId + "_cp_bests.csv");
  if (IO::FileExists(cpBestsPath)) {
    IO::File f(cpBestsPath, IO::FileMode::Read);
    while (!f.EOF()) {
      string line = f.ReadLine();
      if (line.Length == 0) continue;
      string[] cols = line.Split(",");
      if (cols.Length < 2) continue;
      int lapIdx = MigStoI(cols[0]) - 1;
      if (lapIdx < 0 || lapIdx >= 10) continue;

      bool hasZero = false;
      int[] cpTimes;
      for (uint j = 1; j < cols.Length; j++) {
        if (cols[j].Length > 0) {
          int t = MigStoI(cols[j]);
          if (t == 0) { hasZero = true; break; }
          cpTimes.InsertLast(t);
        }
      }
      if (hasZero || cpTimes.Length == 0) continue;

      while (int(bestAllTimeCpTimes.Length) <= lapIdx) {
        int[] empty;
        bestAllTimeCpTimes.InsertLast(empty);
      }
      bestAllTimeCpTimes[lapIdx] = cpTimes;
    }
    f.Close();
  }

  // 5. Write JSON (direct, bypasses hasPlayerRaced guard)
  currentAttemptId = ComputeNextAttemptId();
  Json::ToFile(MapJsonPath(mapId), BuildStateJson(), true);
}
