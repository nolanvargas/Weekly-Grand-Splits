string GetMapName() {
#if TMNEXT || MP4
  if (GetApp().RootMap is null) {
    return "";
  }
  return GetApp().RootMap.MapName;
#endif
}

string GetMapId() {
#if TMNEXT || MP4
  if (GetApp().RootMap is null) {
    return "";
  }
  return GetApp().RootMap.IdName;
#endif
}

#if TMNEXT
bool IsWaypointFinish(int index) {
  if (index == -1) {
    return false;
  }
  auto playground = GetPlayground();
  if (playground is null) {
    return false;
  }
  MwFastBuffer<CGameScriptMapLandmark @> landmarks =
      playground.Arena.MapLandmarks;
  if (index >= int(landmarks.Length)) {
    return false;
  }
  return landmarks[index].Waypoint !is null ? landmarks[index].Waypoint.IsFinish
                                            : false;
}

bool IsWaypointStart(int index) { return GetSpawnCheckpoint() == index; }

bool IsWaypointValid(int index) {
  if (index == -1) {
    return false;
  }
  auto playground = GetPlayground();
  MwFastBuffer<CGameScriptMapLandmark @> landmarks =
      playground.Arena.MapLandmarks;
  if (index >= int(landmarks.Length)) {
    return false;
  }
  bool valid = false;
  if (landmarks[index].Waypoint !is null ? landmarks[index].Waypoint.IsFinish
                                         : false)
    valid = true;
  if ((landmarks[index].Tag == "Checkpoint"))
    valid = true;
  return valid;
}

int GetSpawnCheckpoint() {
  CSmPlayer @smPlayer = GetPlayer();
  if (smPlayer is null) {
    return -1;
  }
  return smPlayer.SpawnIndex;
}
#endif

void UpdateWaypoints() {
#if TMNEXT
  g_state.numCps = 1; // one for finish
#endif
  g_state.numLaps = 1;
  g_state.isMultiLap = false;

  array<int> links = {};
  bool strictMode = true;

#if TMNEXT
  auto playground = GetPlayground();
  if (playground is null || playground.Arena is null ||
      playground.Arena.Rules is null) {
    return;
  }

  auto map = playground.Map;
#endif
  if (map is null) {
    return;
  }
  g_state.numLaps = map.TMObjective_NbLaps;
  g_state.isMultiLap = map.TMObjective_IsLapRace;
#if TMNEXT
  MwFastBuffer<CGameScriptMapLandmark @> landmarks =
      playground.Arena.MapLandmarks;
  for (uint i = 0; i < landmarks.Length; i++) {
    if (landmarks[i].Waypoint is null) {
      continue;
    }
    if (landmarks[i].Waypoint.IsMultiLap) {
      continue;
    }
    if (landmarks[i].Waypoint.IsFinish) {
      continue;
    }
    if (landmarks[i].Tag == "Checkpoint") {
      g_state.numCps++;
    } else if (landmarks[i].Tag == "LinkedCheckpoint") {
      if (links.Find(landmarks[i].Order) < 0) {
        g_state.numCps++;
        links.InsertLast(landmarks[i].Order);
      }
    } else {
      if (strictMode) {
        warn("The current map, " + string(playground.Map.MapName) + " (" +
             playground.Map.IdName +
             "), is not compliant with checkpoint naming rules.");
      }
      g_state.numCps++;
      strictMode = false;
    }
  }

  if (g_state.isMultiLap && g_state.numLaps == 1) {
    g_state.numCps--;
    g_state.isMultiLap = false;
  }

  g_state.hasFinishedMap = true;
#endif
}
