#if TMNEXT
CSmArenaClient @GetPlayground() {
  CSmArenaClient @playground = cast<CSmArenaClient>(GetApp().CurrentPlayground);
  return playground;
}
#endif

CSmArenaRulesMode @GetPlaygroundScript() {
  CSmArenaRulesMode @playground =
      cast<CSmArenaRulesMode>(GetApp().PlaygroundScript);
  return playground;
}

int GetCurrentGameTime() {
  auto playground = GetPlayground();
  if (playground is null || playground.Interface is null ||
      playground.Interface.ManialinkScriptHandler is null) {
    return -1;
  }
  return playground.Interface.ManialinkScriptHandler.GameTime;
}

#if TMNEXT
CSmPlayer @GetPlayer() {
  auto playground = GetPlayground();
  if (playground is null || playground.GameTerminals.Length != 1) {
    return null;
  }
  return cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer);
}
#endif

CSmScriptPlayer @GetPlayerScript() {
  CSmPlayer @smPlayer = GetPlayer();
  if (smPlayer is null) {
    return null;
  }
  return cast<CSmScriptPlayer>(smPlayer.ScriptAPI);
}

bool IsPlayerReady() {
  CSmScriptPlayer @smPlayerScript = GetPlayerScript();
  if (smPlayerScript is null) {
    return false;
  }
  return GetCurrentPlayerRaceTime() >= 0 &&
         smPlayerScript.Post == CSmScriptPlayer::EPost::CarDriver &&
         GetSpawnCheckpoint() != -1;
}

// current time for race — not accurate for ui
int GetCurrentPlayerRaceTime() {
  return GetCurrentGameTime() - GetPlayerStartTime();
}

// chooses between GetUICheckpointTime or GetCurrentPlayerRaceTime
// called directly after a checkpoint changed
int GetPlayerCheckpointTime() {
#if TMNEXT
  int raceTime;
  int estRaceTime = GetCurrentPlayerRaceTime();
  int uiRaceTime = GetUICheckpointTime();
  if (uiRaceTime == 0) {
    raceTime = estRaceTime;
  } else {
    raceTime = uiRaceTime;
  }
  return raceTime;
#endif
}

#if TMNEXT
int GetPlayerStartTime() {
  CSmPlayer @smPlayer = GetPlayer();
  if (smPlayer is null) {
    return -1;
  }
  return smPlayer.StartTime;
}
#endif

int GetActualPlayerStartTime() {
  return GetPlayerStartTime() - GetCurrentPlayerRaceTime();
}

int GetUICheckpointTime() {
#if DEPENDENCY_MLHOOK && DEPENDENCY_MLFEEDRACEDATA
    const MLFeed::HookRaceStatsEventsBase_V3@ mlf = MLFeed::GetRaceData_V3();
    const MLFeed::PlayerCpInfo_V3@ plf = mlf.GetPlayer_V3(MLFeed::LocalPlayersName);
    return plf.LastCpTime;
#else
    return 0;
#endif
}

int GetCurrentCheckpoint() {
#if TMNEXT
  CSmPlayer @smPlayer = GetPlayer();
  if (smPlayer is null) {
    return -1;
  }
  return smPlayer.CurrentLaunchedRespawnLandmarkIndex;
#endif
}

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
  numCps = 1; // one for finish
#endif
  numLaps = 1;
  isMultiLap = false;

  array<int> links = {};
  bool strictMode = true;

#if TMNEXT
  auto playground = GetPlayground();
  if (playground is null || playground.Arena is null ||
      playground.Arena.Rules is null) {
    debugText("map not ready for waypoint read?");
    return;
  }

  auto map = playground.Map;
#endif
  if (map is null) {
    return;
  }
  numLaps = map.TMObjective_NbLaps;
  isMultiLap = map.TMObjective_IsLapRace;
  debugText("Map Laps: " + numLaps + " Is MultiLap: " + isMultiLap);
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
      numCps++;
    } else if (landmarks[i].Tag == "LinkedCheckpoint") {
      if (links.Find(landmarks[i].Order) < 0) {
        numCps++;
        links.InsertLast(landmarks[i].Order);
      }
    } else {
      if (strictMode) {
        warn("The current map, " + string(playground.Map.MapName) + " (" +
             playground.Map.IdName +
             "), is not compliant with checkpoint naming rules.");
      }
      numCps++;
      strictMode = false;
    }
  }

  if (isMultiLap && numLaps == 1) {
    numCps -= 1;
    isMultiLap = false;
  }

  hasFinishedMap = true;
#endif
}
