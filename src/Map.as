// Returns the display name string of the currently loaded map.
string GetMapName() {
  auto app = GetApp();
  if (app.RootMap is null) return "";
  return app.RootMap.MapName;
}

// Returns the author display name for the currently loaded map.
string GetMapAuthor() {
  auto app = GetApp();
  if (app.RootMap is null) return "";
  return app.RootMap.AuthorNickName;
}

// Returns the unique identifier string for the currently loaded map.
string GetMapId() {
  auto app = GetApp();
  if (app.RootMap is null) return "";
  return app.RootMap.IdName;
}

// Returns true if the given landmark index refers to a finish.
bool IsWaypointFinish(int landmarkIdx) {
  // -1 is an indication that CSmPlayer @smPlayer = GetPlayer() is null
  if (landmarkIdx == -1) return false;
  auto playground = GetPlayground();
  if (playground is null) return false;
  MwFastBuffer<CGameScriptMapLandmark @> landmarks = playground.Arena.MapLandmarks;
  // Guard against out-of-bounds landmark access.
  if (landmarkIdx < 0 || landmarkIdx >= int(landmarks.Length)) return false;
  auto landmark = landmarks[landmarkIdx];
  return landmark.Waypoint !is null && landmark.Waypoint.IsFinish;
}

// Returns the current player's spawn checkpoint index or -1 if unknown.
int GetSpawnCheckpoint() {
  CSmPlayer @smPlayer = GetPlayer();
  if (smPlayer is null) return -1;
  return smPlayer.SpawnIndex;
}

// Detects lap count and checkpoint count for the current map.
void UpdateWaypoints() {
  g_state.numLaps = 1;
  g_state.isMultiLap = false;

  // Start with one CP for the finish.
  g_state.numCps = 1;

  auto playground = GetPlayground();
  if (playground is null) return;
  if (playground.Arena is null) return;
  if (playground.Arena.Rules is null) return;

  auto map = playground.Map;
  if (map is null) return;

  g_state.numLaps = map.TMObjective_NbLaps;
  g_state.isMultiLap = map.TMObjective_IsLapRace;

  // effectively single-lap maps
  if (g_state.numLaps == 1) {
    g_state.isMultiLap = false;
    return;
  }

  MwFastBuffer<CGameScriptMapLandmark @> landmarks = playground.Arena.MapLandmarks;

  // Count checkpoints
  array<int> links;
  for (uint landmarkIndex = 0; landmarkIndex < landmarks.Length; landmarkIndex++) {
    auto landmark = landmarks[landmarkIndex];
    if (landmark.Waypoint is null) continue;

    if (landmark.Tag == "Checkpoint") {
      g_state.numCps += 1;
    } else if (landmark.Tag == "LinkedCheckpoint") {
      if (links.Find(landmark.Order) < 0) {
        g_state.numCps += 1;
        links.InsertLast(landmark.Order);
      }
    }
  }
}
