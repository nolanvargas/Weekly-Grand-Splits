void Update(float dt) {
  BeginLogFrame();

  string mapId = GetMapId();

  if (g_state.currentMap != "" && mapId == "") {
    g_state.onMapLeave();
  }

  if (g_state.currentMap != mapId) {
    g_state.OnMapChanged(mapId);
  }
  if (g_state.pendingWaypointUpdate) {
    LogUpdate("[Update] Waiting for playground (pendingWaypointUpdate)");
    g_state.TryCompleteWaypointUpdate();
    return;
  }
  if (!g_state.isMultiLap) {
    LogUpdate("[Update] Not in a multi-lap map, plugin inactive");
    return;
  }
  // player restarting || player just loaded into first run
  if (g_state.pendingAttemptCommenced && !IsPlayerReady() ||
    GetCurrentPlayerRaceTime() < -1000 && !g_state.waitingForStart) {

    // prevents OnNewAttempt if user leaves map
    if (GetCurrentPlayerRaceTime() < -1000) {
      g_state.OnNewAttempt();
      g_state.pendingAttemptCommenced = false;
    }
  }

  if (g_state.waitForCarReset) {
    bool ready = IsPlayerReady();
    LogUpdate("Waiting for player");
    g_state.waitForCarReset = !ready;
    return;
  }

  if (g_state.resetData) {
    if (IsPlayerReady()) {
      g_state.OnAttemptCommenced();

      ResetRace(g_state.currentAttempt);
      g_state.resetData = false;

      g_state.playerStartTime = GetActualPlayerStartTime();
    }
    return;
  }

  if (g_state.isFinished || g_state.waitingForStart) {
    return;
  }

  int cp = GetCurrentCheckpoint();

  if (cp != g_state.lastCP) {
    if (IsWaypointFinish(cp)) {
      g_state.OnLapFinished();
    } else {
      g_state.OnCheckpointReached(cp);
    }

    PersistCurrentRun();
  }
}
