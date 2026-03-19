#if TMNEXT
CSmArenaClient @GetPlayground() {
  return cast<CSmArenaClient>(GetApp().CurrentPlayground);
}
#endif

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

#if TMNEXT
CSmPlayer @GetPlayer() {
  auto pg = GetPlayground();
  if (pg is null || pg.GameTerminals.Length != 1) return null;
  return cast<CSmPlayer>(pg.GameTerminals[0].GUIPlayer);
}
#endif

CSmScriptPlayer @GetPlayerScript() {
  CSmPlayer @p = GetPlayer();
  return p is null ? null : cast<CSmScriptPlayer>(p.ScriptAPI);
}

bool IsPlayerReady() {
  CSmScriptPlayer @s = GetPlayerScript();
  return s !is null && GetCurrentPlayerRaceTime() >= 0 &&
         s.Post == CSmScriptPlayer::EPost::CarDriver && GetSpawnCheckpoint() != -1;
}

int GetCurrentPlayerRaceTime() {
  return GetCurrentGameTime() - GetPlayerStartTime();
}

int GetPlayerCheckpointTime() {
#if TMNEXT
  int ui = GetUICheckpointTime();
  return ui == 0 ? GetCurrentPlayerRaceTime() : ui;
#endif
}

#if TMNEXT
int GetPlayerStartTime() {
  CSmPlayer @p = GetPlayer();
  return p is null ? -1 : p.StartTime;
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
  CSmPlayer @p = GetPlayer();
  return p is null ? -1 : p.CurrentLaunchedRespawnLandmarkIndex;
#endif
}
