// Returns the current arena client or null if unavailable.
CSmArenaClient @GetPlayground() {
  return cast<CSmArenaClient>(GetApp().CurrentPlayground);
}

// Returns the current absolute game clock in milliseconds or -1.
int GetCurrentGameTime() {
  auto pg = GetPlayground();
  if (pg is null || pg.Interface is null ||
      pg.Interface.ManialinkScriptHandler is null) {
    return -1;
  }
  return pg.Interface.ManialinkScriptHandler.GameTime;
}

// Returns the local player or null if not in race.
CSmPlayer @GetPlayer() {
  auto pg = GetPlayground();
  if (pg is null || pg.GameTerminals.Length != 1) return null;
  return cast<CSmPlayer>(pg.GameTerminals[0].GUIPlayer);
}

// Returns the script API for the local player or null.
CSmScriptPlayer @GetPlayerScript() {
  CSmPlayer @player = GetPlayer();
  return player is null ? null : cast<CSmScriptPlayer>(player.ScriptAPI);
}

// Returns true when the player is spawned and ready to race.
bool IsPlayerReady() {
  CSmScriptPlayer @scriptPlayer = GetPlayerScript();
  return scriptPlayer !is null && GetCurrentPlayerRaceTime() >= 0 &&
         scriptPlayer.Post == CSmScriptPlayer::EPost::CarDriver && GetSpawnCheckpoint() != -1;
}

// Returns elapsed race time in milliseconds for the local player.
int GetCurrentPlayerRaceTime() {
  return GetCurrentGameTime() - GetPlayerStartTime();
}

// Returns checkpoint time from the UI label, falling back to race time.
int GetPlayerCheckpointTime() {
  int uiTime = GetUICheckpointTime();
  return uiTime == -1 ? GetCurrentPlayerRaceTime() : uiTime;
}

// Reads the race checkpoint time from the game's own UI label.
int GetUICheckpointTime() {
  CGameCtnNetwork@ network = GetApp().Network;
  if (network is null) return -1;
  CGameManiaAppPlayground@ appPlayground = network.ClientManiaAppPlayground;
  if (appPlayground is null) return -1;
  CGameUILayer@ layer = appPlayground.UILayers[8];
  if (layer is null) return -1;
  CGameManialinkPage@ page = layer.LocalPage;
  if (page is null) return -1;
  CGameManialinkControl@ root = page.GetClassChildren_Result[0];
  if (root is null || root.ControlId != "Race_Checkpoint") return -1;
  CGameManialinkControl@ f0 = cast<CGameManialinkFrame>(root).Controls[0];
  if (f0 is null) return -1;
  CGameManialinkControl@ f1 = cast<CGameManialinkFrame>(f0).Controls[0];
  if (f1 is null) return -1;
  CGameManialinkControl@ f2 = cast<CGameManialinkFrame>(f1).Controls[0];
  if (f2 is null || cast<CGameManialinkFrame>(f2).Controls.Length != 2) return -1;
  CGameManialinkLabel@ label = cast<CGameManialinkLabel>(cast<CGameManialinkFrame>(f2).Controls[1]);
  if (label is null) return -1;
  return ParseTimeString(label.Value);
}

// Parses a M:SS.mmm time string into total milliseconds or -1.
int ParseTimeString(const string &in s) {
  int colon = s.IndexOf(":");
  int dot   = s.IndexOf(".");
  if (colon < 0 || dot < 0 || dot <= colon) return -1;
  int minutes = Text::ParseInt(s.SubStr(0, colon));
  int seconds = Text::ParseInt(s.SubStr(colon + 1, dot - colon - 1));
  int millis  = Text::ParseInt(s.SubStr(dot + 1));
  return (minutes * 60 + seconds) * 1000 + millis;
}

// Returns the absolute game time when the current run began.
int GetPlayerStartTime() {
  CSmPlayer @player = GetPlayer();
  return player is null ? -1 : player.StartTime;
}

// Returns the race-zero game time by subtracting current race time.
int GetActualPlayerStartTime() {
  return GetPlayerStartTime() - GetCurrentPlayerRaceTime();
}

// Returns the player's current launched respawn landmark index or -1.
int GetCurrentCheckpoint() {
  CSmPlayer @player = GetPlayer();
  return player is null ? -1 : player.CurrentLaunchedRespawnLandmarkIndex;
}
