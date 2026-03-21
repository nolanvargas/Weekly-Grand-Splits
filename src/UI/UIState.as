class UIState {
  Attempt@ displayAttempt = null;
  bool isStale    = false;
  bool isRacing   = false;
  int  liveTime   = 0;

  // Called by GameState.OnNewAttempt() — UI switches to previousAttempt (stale display).
  void OnNewAttempt(Attempt@ prev) {
    @displayAttempt = prev;
    LogUIState("UIState: displayAttempt -> previousAttempt (id=" + (prev !is null ? prev.attemptId : -1) + ")");
  }

  // Called by GameState.OnCheckpointReached() — first CP clears stale display.
  void OnCheckpointReached(Attempt@ current) {
    @displayAttempt = current;
    LogUIState("UIState: displayAttempt -> currentAttempt (id=" + (current !is null ? current.attemptId : -1) + ")");
  }

  // Called by GameState.OnMapChanged() / TryCompleteWaypointUpdate() / ResetCommon().
  void OnReset() {
    @displayAttempt = null;
    isStale  = false;
    isRacing = false;
    liveTime = 0;
    LogUIState("UIState: reset");
  }

  // Called once per Render() frame to refresh derived values.
  void Update() {
    bool newStale   = g_state.IsStale();
    bool newRacing  = !g_state.waitForCarReset && !g_state.resetData && !g_state.isFinished && !newStale;
    int  newLive    = newRacing ? Math::Max(0, GetCurrentPlayerRaceTime() - g_state.prevLapRaceTime) : 0;

    if (newStale != isStale)   { isStale = newStale;   LogUIState("UIState: isStale=" + isStale); }
    if (newRacing != isRacing) { isRacing = newRacing; LogUIState("UIState: isRacing=" + isRacing); }
    liveTime = newLive;

    // Fallback: if displayAttempt was never set by an event (e.g. plugin loaded mid-race),
    // derive it the old way so the UI is never blank when it shouldn't be.
    if (displayAttempt is null && (g_state.currentAttempt !is null || g_state.previousAttempt !is null)) {
      @displayAttempt = g_state.previousAttempt !is null ? g_state.previousAttempt : g_state.currentAttempt;
      LogUIState("UIState: displayAttempt fallback (id=" + displayAttempt.attemptId + ")");
    }
  }
}

UIState g_uiState;
