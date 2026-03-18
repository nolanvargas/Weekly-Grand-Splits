// Thin wrappers around common Trackmania game API calls.
// These helpers centralize access to playground, player, and timing state.

#if TMNEXT
CSmArenaClient @GetPlayground() {
  CSmArenaClient @playground = cast<CSmArenaClient>(GetApp().CurrentPlayground);
  return playground;
}
#endif

// Returns the current arena rules script object, or null if unavailable.
CSmArenaRulesMode @GetPlaygroundScript() {
  CSmArenaRulesMode @playground =
      cast<CSmArenaRulesMode>(GetApp().PlaygroundScript);
  return playground;
}

// Returns the current game time in milliseconds from the rules script.
// This is the canonical time base used for race timing.
int GetCurrentGameTime() {
  auto playground = GetPlayground();
  if (playground is null || playground.Interface is null ||
      playground.Interface.ManialinkScriptHandler is null) {
    // Actions: when we cannot access the rules script handler, signal an invalid time with -1 so callers can guard their logic.
    return -1;
  }
  return playground.Interface.ManialinkScriptHandler.GameTime;
}

#if TMNEXT
// Returns the local CSmPlayer instance, or null in menus / invalid states.
CSmPlayer @GetPlayer() {
  auto playground = GetPlayground();
  if (playground is null || playground.GameTerminals.Length != 1) {
    // Actions: in menus or unexpected multi-terminal setups, report no active player so race logic can skip processing.
    return null;
  }
  return cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer);
}
#endif

// Returns the script API wrapper for the local player, or null if unavailable.
CSmScriptPlayer @GetPlayerScript() {
  CSmPlayer @smPlayer = GetPlayer();
  if (smPlayer is null) {
    // Actions: if there is no underlying CSmPlayer, return null so callers know script-level player data is unavailable.
    return null;
  }
  return cast<CSmScriptPlayer>(smPlayer.ScriptAPI);
}

// Returns true when the player is spawned, in the car, and has a valid spawn CP.
// Used as a guard to ensure that timing and checkpoint logic only runs in-race.
bool IsPlayerReady() {
  CSmScriptPlayer @smPlayerScript = GetPlayerScript();
  if (smPlayerScript is null) {
    // Actions: when the script player is missing, treat the player as not ready so timing/checkpoint logic does not run.
    return false;
  }
  return GetCurrentPlayerRaceTime() >= 0 &&
         smPlayerScript.Post == CSmScriptPlayer::EPost::CarDriver &&
         GetSpawnCheckpoint() != -1;
}

// Current race time for the player from game-time minus start time.
// This is authoritative for logic but may diverge slightly from UI display.
int GetCurrentPlayerRaceTime() {
  return GetCurrentGameTime() - GetPlayerStartTime();
}

// Chooses between GetUICheckpointTime or GetCurrentPlayerRaceTime.
// Called directly after a checkpoint changed to get the best-available CP time.
int GetPlayerCheckpointTime() {
#if TMNEXT
  int raceTime;
  int estRaceTime = GetCurrentPlayerRaceTime();
  int uiRaceTime = GetUICheckpointTime();
  if (uiRaceTime == 0) {
    // Actions: when the UI feed has no CP time, fall back to the estimated race time from game-time minus start.
    raceTime = estRaceTime;
  } else {
    raceTime = uiRaceTime;
  }
  return raceTime;
#endif
}

#if TMNEXT
// Returns the race start time for the current player, or -1 if unknown.
int GetPlayerStartTime() {
  CSmPlayer @smPlayer = GetPlayer();
  if (smPlayer is null) { return -1; }
  return smPlayer.StartTime;
}
#endif

// Computes a corrected start time based on current race time.
// This is used when we reset the run while preserving the current race timer.
int GetActualPlayerStartTime() {
  return GetPlayerStartTime() - GetCurrentPlayerRaceTime();
}

// Returns the checkpoint time reported by MLFeed, if available.
// Falls back to 0 when the dependency is missing or no CP was just passed.
int GetUICheckpointTime() {
#if DEPENDENCY_MLHOOK && DEPENDENCY_MLFEEDRACEDATA
    const MLFeed::HookRaceStatsEventsBase_V3@ mlf = MLFeed::GetRaceData_V3();
    const MLFeed::PlayerCpInfo_V3@ plf = mlf.GetPlayer_V3(MLFeed::LocalPlayersName);
    return plf.LastCpTime;
#else
    return 0;
    // Actions: when MLFeed is not available, always return 0 so code will fall back to the internal race-time estimate.
#endif
}

// Returns the index of the last launched respawn landmark (current CP), or -1.
int GetCurrentCheckpoint() {
#if TMNEXT
  CSmPlayer @smPlayer = GetPlayer();
  if (smPlayer is null) {
    // Actions: if there is no current player, indicate an unknown checkpoint index with -1.
    return -1;
  }
  return smPlayer.CurrentLaunchedRespawnLandmarkIndex;
#endif
}
