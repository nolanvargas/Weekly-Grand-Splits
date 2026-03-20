void RenderDebugState() {
    if (!debugShowStateWindow) return;

    int flags = UI::WindowFlags::NoCollapse | UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking;
    if (UI::Begin("Game State##dbg", flags)) {
        UI::Text("--- Map ---");
        UI::Text("currentMap:     " + g_state.currentMap);
        UI::Text("numCps:         " + g_state.numCps);
        UI::Text("numLaps:        " + g_state.numLaps);
        UI::Text("isMultiLap:     " + (g_state.isMultiLap ? "true" : "false"));

        UI::Separator();
        UI::Text("--- Race State ---");
        UI::Text("currentLap:         " + g_state.currentLap);
        UI::Text("waitForCarReset:    " + (g_state.waitForCarReset ? "true" : "false"));
        UI::Text("resetData:          " + (g_state.resetData ? "true" : "false"));
        UI::Text("isFinished:         " + (g_state.isFinished ? "true" : "false"));
        UI::Text("hasPlayerRaced:     " + (g_state.hasPlayerRaced ? "true" : "false"));
        UI::Text("IsStale():          " + (g_state.IsStale() ? "true" : "false"));
        UI::Text("lastCP:             " + g_state.lastCP);
        UI::Text("prevLapRaceTime:    " + g_state.prevLapRaceTime + " ms");
        UI::Text("lastCpTime:         " + g_state.lastCpTime + " ms");
        UI::Text("finishRaceTime:     " + g_state.finishRaceTime + " ms");
        UI::Text("playerStartTime:    " + g_state.playerStartTime + " ms");
        UI::Text("currentAttemptId:   " + g_state.currentAttemptId);

        UI::Separator();
        UI::Text("--- Live ---");
        UI::Text("raceTime:           " + GetCurrentPlayerRaceTime() + " ms");
        UI::Text("gameTime:           " + GetCurrentGameTime() + " ms");
        UI::Text("checkpoint:         " + GetCurrentCheckpoint());
        UI::Text("playerReady:        " + (IsPlayerReady() ? "true" : "false"));

        UI::Separator();
        UI::Text("--- Attempt ---");
        Attempt@ atm = g_state.currentAttempt;
        if (atm is null) {
            UI::Text("currentAttempt: null");
        } else {
            UI::Text("lapCount:       " + atm.LapCount);
            for (uint i = 0; i < atm.LapCount; i++) {
                Lap@ lap = atm.GetLap(int(i));
                UI::Text("  lap[" + i + "] cps=" + lap.CheckpointCount + " time=" + lap.LapTime + " ms");
            }
        }
        UI::Text("staleAttempt:   " + (g_state.staleAttempt is null ? "null" : "present"));
    }
    UI::End();
}
