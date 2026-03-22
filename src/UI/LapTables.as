// Renders lap splits vertically with one row per lap and a total.
void RenderLapTableNormal(bool isRacing, int liveTime) {
  if (UI::BeginTable("splits", 3, UI::TableFlags::SizingFixedFit)) {
    UI::TableNextColumn(); SetMinWidth(styleColWidthLap);   UI::Text("Lap");
    UI::TableNextColumn(); SetMinWidth(styleColWidthDelta); UI::Text("+/-");
    UI::TableNextColumn(); SetMinWidth(styleColWidthTime);  UI::Text("Time");

    for (int lapIdx = 1; lapIdx <= g_uiState.numLaps; lapIdx++) { // Laps start at 1
      UI::TableNextRow();
      if (lapIdx >= int(g_uiState.lapData.Length)) break;
      LapDisplayData@ d = g_uiState.lapData[lapIdx];

      if (d.completed) {
        UI::TableNextColumn(); UI::Text("" + lapIdx);
        UI::PushStyleColor(UI::Col::Text, GetLapDeltaColor(d.delta, d.hasBest));
        UI::TableNextColumn(); UI::Text(d.hasBest ? FormatDelta(d.delta) : "-");
        UI::PopStyleColor();
        if (d.isGold) UI::PushStyleColor(UI::Col::Text, COLOR_GOLD);
        UI::TableNextColumn(); UI::Text(FormatTenth(d.lapTime));
        if (d.isGold) UI::PopStyleColor();

      } else if (d.active) {
        UI::TableNextColumn(); UI::Text("" + lapIdx);
        if (d.showDelta) {
          UI::PushStyleColor(UI::Col::Text, GetLiveDeltaColor(d.liveDelta));
          UI::TableNextColumn(); UI::Text(FormatDelta(d.liveDelta));
          UI::PopStyleColor();
          UI::TableNextColumn(); UI::Text(FormatTenth(liveTime));
        } else {
          UI::TableNextColumn(); UI::Text("-");
          UI::TableNextColumn(); UI::Text(FormatTenth(liveTime));
        }

      } else {
        UI::TableNextColumn(); UI::Text("" + lapIdx);
        UI::TableNextColumn(); UI::Text("-");
        UI::TableNextColumn(); UI::Text("-");
      }
    }

    // Separator row then Total
    UI::TableNextRow();
    UI::TableNextColumn(); UI::Text("---");
    UI::TableNextColumn(); UI::Text("---");
    UI::TableNextColumn(); UI::Text("---");

    UI::TableNextRow();
    UI::TableNextColumn();
    UI::PushStyleColor(UI::Col::Text, g_uiState.totalColor);
    UI::TableNextColumn(); UI::Text(g_uiState.showTotalDelta ? FormatDelta(g_uiState.totalDelta) : "-");
    UI::PopStyleColor();
    UI::TableNextColumn(); UI::Text(g_uiState.hasTotal ? FormatTenth(g_uiState.displayTotal) : "-");

    UI::EndTable();
  }
}

// Renders the lap table transposed with one column per lap.
void RenderLapTableTransposed(bool isRacing, int liveTime) {
  // cols: label | Lap1..numLaps | Total
  if (UI::BeginTable("splits_t", 1 + g_uiState.numLaps + 1, UI::TableFlags::SizingFixedFit)) {
    // Header row
    UI::TableNextColumn(); SetMinWidth(styleColWidthDelta);
    for (int lapIdx = 1; lapIdx <= g_uiState.numLaps; lapIdx++) { // Laps start at 1
      UI::TableNextColumn(); SetMinWidth(styleColWidthTime); UI::Text("" + lapIdx);
    }
    UI::TableNextColumn(); SetMinWidth(styleColWidthTime);

    // +/- row
    UI::TableNextRow();
    UI::TableNextColumn(); UI::Text("+/-");
    for (int lapIdx = 1; lapIdx <= g_uiState.numLaps; lapIdx++) { // Laps start at 1
      UI::TableNextColumn();
      if (lapIdx >= int(g_uiState.lapData.Length)) { UI::Text("-"); continue; }
      LapDisplayData@ d = g_uiState.lapData[lapIdx];
      if (d.completed) {
        UI::PushStyleColor(UI::Col::Text, GetLapDeltaColor(d.delta, d.hasBest));
        UI::Text(d.hasBest ? FormatDelta(d.delta) : "-");
        UI::PopStyleColor();
      } else if (d.active) {
        if (d.showDelta) {
          UI::PushStyleColor(UI::Col::Text, GetLiveDeltaColor(d.liveDelta));
          UI::Text(FormatDelta(d.liveDelta));
          UI::PopStyleColor();
        } else {
          UI::Text("-");
        }
      } else {
        UI::Text("-");
      }
    }
    UI::TableNextColumn();
    UI::PushStyleColor(UI::Col::Text, g_uiState.totalColor);
    UI::Text(g_uiState.showTotalDelta ? FormatDelta(g_uiState.totalDelta) : "-");
    UI::PopStyleColor();

    // Time row
    UI::TableNextRow();
    UI::TableNextColumn(); UI::Text("Time");
    for (int lapIdx = 1; lapIdx <= g_uiState.numLaps; lapIdx++) { // Laps start at 1
      UI::TableNextColumn();
      if (lapIdx >= int(g_uiState.lapData.Length)) { UI::Text("-"); continue; }
      LapDisplayData@ d = g_uiState.lapData[lapIdx];
      if (d.completed) {
        if (d.isGold) UI::PushStyleColor(UI::Col::Text, COLOR_GOLD);
        UI::Text(FormatTenth(d.lapTime));
        if (d.isGold) UI::PopStyleColor();
      } else if (d.active) {
        UI::Text(FormatTenth(liveTime));
      } else {
        UI::Text("-");
      }
    }
    UI::TableNextColumn();
    UI::Text(g_uiState.hasTotal ? FormatTenth(g_uiState.displayTotal) : "-");

    UI::EndTable();
  }
}
