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
        UI::Text("currentLap:         " + (g_state.currentLap));
        UI::Text("waitForCarReset:    " + (g_state.waitForCarReset ? "true" : "false"));
        UI::Text("resetData:          " + (g_state.resetData ? "true" : "false"));
        UI::Text("isFinished:         " + (g_state.isFinished ? "true" : "false"));
        UI::Text("IsStale():          " + (g_state.IsStale() ? "true" : "false"));
        UI::Text("lastCP:             " + g_state.lastCP);
        UI::Text("prevLapRaceTime:    " + g_state.prevLapRaceTime + " ms");
        UI::Text("lastCpTime:         " + g_state.lastCpTime + " ms");
        UI::Text("finishRaceTime:     " + g_state.finishRaceTime + " ms");
        UI::Text("playerStartTime:    " + g_state.playerStartTime + " ms");
        UI::Text("currentAttemptId:   " + g_state.currentAttemptId);
        UI::Text("pendingAttemptCommenced: " + (g_state.pendingAttemptCommenced ? "true" : "false"));
        UI::Text("pendingWaypointUpdate:   " + (g_state.pendingWaypointUpdate ? "true" : "false"));
        UI::Text("waitingForStart:        " + (g_state.waitingForStart ? "true" : "false"));

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
            UI::Text("lapCount:       " + atm.laps.Length);
            for (uint lapSlot = 1; lapSlot < atm.laps.Length; lapSlot++) {
                Lap@ lap = atm.GetLap(int(lapSlot));
                UI::Text("  lap[" + lapSlot + "] cps=" + lap.checkpoints.Length + " time=" + lap.GetLapTime() + " ms");
            }
        }
        UI::Text("previousAttempt:   " + (g_state.previousAttempt is null ? "null" : "present"));

        UI::Separator();
        UI::Text("--- History ---");
        UI::Text("attemptCount:   " + g_state.history.GetAttemptCount());

        UI::Separator();
        UI::Text("--- Bests ---");
        Bests@ bests = g_state.bests;
        if (bests is null) {
            UI::Text("bests: null");
        } else {
            UI::Text("_numLaps:            " + bests._numLaps);
            UI::Text("_numCps:             " + bests._numCps);
            UI::Text("bestSingleAttempt:   " + (bests.bestSingleAttempt is null ? "null" : "id=" + bests.bestSingleAttempt.attemptId));
            UI::Text("bestSingleLap:       " + (bests.bestSingleLap is null ? "null" : "time=" + bests.bestSingleLap.GetLapTime() + " ms"));
            UI::Text("bestAnyCp:           " + (bests.bestAnyCp is null ? "null" : "present"));
            UI::Text("bestLapByLapIndex:   " + (bests.bestLapByLapIndex is null ? "null" : "present"));
            UI::Text("bestCpByCpLapIndex:  " + (bests.bestCpByCpLapIndex is null ? "null" : "present"));
        }
    }
    UI::End();
}
