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
