CSmArenaClient @GetPlayground() {
  return cast<CSmArenaClient>(GetApp().CurrentPlayground);
}

CSmArenaRulesMode @GetPlaygroundScript() {
  return cast<CSmArenaRulesMode>(GetApp().PlaygroundScript);
}

int GetCurrentGameTime() {
  auto pg = GetPlayground();
  if (pg is null || pg.Interface is null ||
      pg.Interface.ManialinkScriptHandler is null) {
    return -1;
  }
  return pg.Interface.ManialinkScriptHandler.GameTime;
}

CSmPlayer @GetPlayer() {
  auto pg = GetPlayground();
  if (pg is null || pg.GameTerminals.Length != 1) return null;
  return cast<CSmPlayer>(pg.GameTerminals[0].GUIPlayer);
}

CSmScriptPlayer @GetPlayerScript() {
  CSmPlayer @player = GetPlayer();
  return player is null ? null : cast<CSmScriptPlayer>(player.ScriptAPI);
}

bool IsPlayerReady() {
  CSmScriptPlayer @scriptPlayer = GetPlayerScript();
  return scriptPlayer !is null && GetCurrentPlayerRaceTime() >= 0 &&
         scriptPlayer.Post == CSmScriptPlayer::EPost::CarDriver && GetSpawnCheckpoint() != -1;
}

int GetCurrentPlayerRaceTime() {
  return GetCurrentGameTime() - GetPlayerStartTime();
}

int GetPlayerCheckpointTime() {
  int uiCheckpointMs = GetUICheckpointTime();
  return uiCheckpointMs == 0 ? GetCurrentPlayerRaceTime() : uiCheckpointMs;
}

int GetPlayerStartTime() {
  CSmPlayer @player = GetPlayer();
  return player is null ? -1 : player.StartTime;
}

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
  CSmPlayer @player = GetPlayer();
  return player is null ? -1 : player.CurrentLaunchedRespawnLandmarkIndex;
}
