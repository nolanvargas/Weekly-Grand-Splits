string GetMapName() {
  auto app = GetApp();
  if (app.RootMap is null) return "";
  return app.RootMap.MapName;
}

string GetMapId() {
  auto app = GetApp();
  if (app.RootMap is null) return "";
  return app.RootMap.IdName;
}

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

// Returns the spawn checkpoint index for the current player, or -1 if unknown.
int GetSpawnCheckpoint() {
  CSmPlayer @smPlayer = GetPlayer();
  if (smPlayer is null) return -1;
  return smPlayer.SpawnIndex;
}

// Detects laps and checkpoints for the current map and updates g_state config.
// This is called when the map changes or when the CP count needs to be recomputed.
// See UpdateWaypoints flowchart
void UpdateWaypoints() {
  g_state.numLaps = 1;
  g_state.isMultiLap = false;

  // Start with one CP for the finish.
  g_state.numCps = 1;

  auto playground = GetPlayground();
  if (playground is null) {
    LogWarn("UpdateWaypoints: playground is null");
    return;
  }
  if (playground.Arena is null) {
    LogWarn("UpdateWaypoints: Arena is null");
    return;
  }
  if (playground.Arena.Rules is null) {
    LogWarn("UpdateWaypoints: Rules is null");
    return;
  }

  auto map = playground.Map;
  if (map is null) {
    LogWarn("UpdateWaypoints: map is null");
    return;
  }

  g_state.numLaps = map.TMObjective_NbLaps;
  g_state.isMultiLap = map.TMObjective_IsLapRace;

  // effectively single-lap maps
  if (g_state.numLaps == 1) {
    g_state.isMultiLap = false;
    LogWarn("UpdateWaypoints: single-lap map detected");
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