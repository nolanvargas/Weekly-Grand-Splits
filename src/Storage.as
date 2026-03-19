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

// Returns the absolute path on disk where JSON for a given mapId is stored.
string MapJsonPath(const string&in mapId) {
  IO::CreateFolder(IO::FromStorageFolder("maps"));
  return IO::FromStorageFolder("maps/" + mapId + ".json");
}

// Syncs g_state into g_storage, then serializes to JSON.
Json::Value@ BuildStateJson() {
  g_storage.attempts = {};
  for (uint ai = 0; ai < g_state.history.GetAttemptCount(); ai++) {
    Attempt@ src = g_state.history.GetAttemptByIndex(ai);
    if (src is null) continue;
    StorageAttempt at;
    at.id = src.id;
    at.laps = LapArraysFromRace(src);
    g_storage.attempts.InsertLast(at);
  }

  // in-progress attempt with -1 placeholders for unvisited CPs
  Attempt@ curAttempt = g_state.currentAttempt;
  bool hasCurrentData = (curAttempt !is null && curAttempt.LapCount > 0) || g_state.currentLap > 0;
  if (hasCurrentData && !g_state.isFinished) {
    // Actions: when there is an in-progress attempt with at least one lap or CP split and the run is not finished, append a synthetic "current attempt" entry with -1 placeholders.
    StorageAttempt at;
    at.id = g_state.currentAttemptId;

    array<array<int>> lapCp = (curAttempt is null) ? array<array<int>>() : curAttempt.ToLapCpArray();

    // Append completed laps (variable checkpoint count, matching archived attempts).
    for (int li = 0; li < g_state.currentLap && li < int(lapCp.Length); li++) {
      at.laps.InsertLast(lapCp[li]);
    }

    // Append current lap, padded with -1 for unvisited CPs.
    array<int> curLap;
    int curLapIdx = g_state.currentLap;
    if (curAttempt !is null && curLapIdx >= 0 && curLapIdx < int(lapCp.Length)) {
      for (uint ci = 0; ci < lapCp[curLapIdx].Length; ci++) curLap.InsertLast(lapCp[curLapIdx][ci]);
    }
    int remaining = g_state.numCps - int(curLap.Length);
    for (int pi = 0; pi < remaining; pi++) curLap.InsertLast(-1);
    at.laps.InsertLast(curLap);

    g_storage.attempts.InsertLast(at);
  }

  return g_storage.ToJson();
}

// Minimum archived attempt count we must not go below when writing.
// Set after each LoadData so we never overwrite disk data with fewer attempts.
int g_minAttemptCount = 0;

// Writes all state to JSON.
// Guarded: won't write until there is a valid map and some runs/splits to store.
void SaveData() {
  string mapId = GetMapId();
  // avoid writing to disk when there is no valid map ID or no checkpoints configured
  if (mapId == "" || g_state.numCps == 0) return;
  Attempt@ curAttempt = g_state.currentAttempt;
  bool hasCurrent = (curAttempt !is null && curAttempt.LapCount > 0) || g_state.currentLap > 0;
  if (g_state.history.GetAttemptCount() == 0 && !hasCurrent) return;
  // Safety: never write fewer archived attempts than what was loaded from disk.
  if (int(g_state.history.GetAttemptCount()) < g_minAttemptCount) return;
  Json::ToFile(MapJsonPath(mapId), BuildStateJson(), true);
}

// Resets all history/PB state.
// Called from ResetCommon() on map change to start fresh for a new map.
void InitEmptyState() {
  g_state.history.Clear();
  g_state.currentAttemptId = 1;
  g_state.bests.Clear();
  g_minAttemptCount = 0;
}

// Computes the next attempt id based on attempts already present in history.
// Ensures newly loaded attempts don't clash with existing ids.
int ComputeNextAttemptId() {
  int maxId = 0;
  for (uint i = 0; i < g_state.history.GetAttemptCount(); i++) {
    Attempt@ at = g_state.history.GetAttemptByIndex(i);
    if (at is null) continue;
    if (at.id > maxId) maxId = at.id;
  }
  return maxId + 1;
}

// Populates g_storage from JSON, then syncs that data into g_state so the rest of the plugin
// can work with a strongly-typed in-memory representation instead of raw JSON.
void PopulateStateFromJson(Json::Value@ root) {
  // deserialize the raw JSON
  g_storage.FromJson(root);

  g_state.history.Clear();

  // Copy each stored attempt into an Attempt instance
  for (uint attemptIndex = 0; attemptIndex < g_storage.attempts.Length; attemptIndex++) {
    StorageAttempt@ storageAttempt = g_storage.attempts[attemptIndex];
    int[] dummyTotals; // not used by RaceFromLapArrays
    Attempt@ attempt = RaceFromLapArrays(storageAttempt.id, storageAttempt.laps, dummyTotals);
    g_state.history.AddAttempt(attempt);
  }

  // Ensure future attempts get an id that does not collide with anything we just loaded.
  g_state.currentAttemptId = ComputeNextAttemptId();

  // Derive best/reference baselines from the loaded attempts.
  g_state.bests.ComputeFromHistory(g_state.history, g_state.numLaps, g_state.numCps);
}

// Entry point to load persisted data for the current map into g_state.
// If no valid JSON exists, initializes an empty state instead.
void LoadData() {
  string mapId = GetMapId();
  if (mapId == "") { InitEmptyState(); return; }

  string jsonPath = MapJsonPath(mapId);
  if (IO::FileExists(jsonPath)) {
    // parse and populate g_state
    Json::Value@ data = Json::FromFile(jsonPath);
    if (data is null) { InitEmptyState(); return; }
    PopulateStateFromJson(data);
    g_minAttemptCount = int(g_state.history.GetAttemptCount());
  } else { InitEmptyState(); }
}
