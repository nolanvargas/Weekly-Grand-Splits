string FormatDelta(int ms) {
  string sign = ms < 0 ? "-" : "+";
  int abs = Math::Abs(ms);
  int secs = abs / 1000;
  if (useThousandths) {
    int millis = abs % 1000;
    string m = millis < 10 ? "00" + millis : millis < 100 ? "0" + millis : "" + millis;
    return sign + secs + "." + m;
  }
  int hundredths = (abs % 1000) / 10;
  string h = hundredths < 10 ? "0" + hundredths : "" + hundredths;
  return sign + secs + "." + h;
}

string FormatTenth(int ms) {
  int secs = (ms / 1000) % 60;
  int mins = ms / 60000;
  if (useThousandths) {
    int millis = ms % 1000;
    string m = millis < 10 ? "00" + millis : millis < 100 ? "0" + millis : "" + millis;
    if (mins == 0) return secs + "." + m;
    string s = secs < 10 ? "0" + secs : "" + secs;
    return mins + ":" + s + "." + m;
  }
  int tenths = (ms / 100) % 10;
  if (mins == 0) return secs + "." + tenths;
  string s = secs < 10 ? "0" + secs : "" + secs;
  return mins + ":" + s + "." + tenths;
}

string FormatCpTime(int ms) {
  int secs = ms / 1000;
  if (useThousandths) {
    int millis = ms % 1000;
    string m = millis < 10 ? "00" + millis : millis < 100 ? "0" + millis : "" + millis;
    return secs + "." + m;
  }
  int hundredths = (ms % 1000) / 10;
  string h = hundredths < 10 ? "0" + hundredths : "" + hundredths;
  return secs + "." + h;
}

void SetMinWidth(int width) {
  UI::PushStyleVar(UI::StyleVar::ItemSpacing, vec2(0, 0));
  UI::Dummy(vec2(width, 0));
  UI::PopStyleVar();
}

void LoadFont() {
  string fontFaceToLoad = fontFace.Length == 0 ? "DroidSans.ttf" : fontFace;
  if (fontFaceToLoad != loadedFontFace || fontSize != loadedFontSize) {
    @font = UI::LoadFont(fontFaceToLoad, fontSize);
    if (font !is null) {
      loadedFontFace = fontFaceToLoad;
      loadedFontSize = fontSize;
    }
  }
}

// modified https://github.com/Phlarx/tm-ultimate-medals
void Render() {
  auto app = cast<CTrackMania>(GetApp());

#if TMNEXT || MP4
  auto map = app.RootMap;
#endif

  if (!isMultiLap) {
    return;
  }

  if (hideWithIFace) {
    auto playground = app.CurrentPlayground;
    if (playground is null || playground.Interface is null ||
        !UI::IsGameUIVisible()) {
      return;
    }
  }

  if (!windowVisible || map is null || map.MapInfo.MapUid == "") {
    return;
  }

  if (lockPosition) {
    UI::SetNextWindowPos(int(anchor.x), int(anchor.y), UI::Cond::Always);
  } else {
    UI::SetNextWindowPos(int(anchor.x), int(anchor.y), UI::Cond::FirstUseEver);
  }

  int windowFlags =
      UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoCollapse |
      UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking;
  if (!UI::IsOverlayShown()) {
    windowFlags |= UI::WindowFlags::NoInputs;
  }

  UI::PushFont(font);
  UI::Begin("LapTimes", windowFlags);

  if (!lockPosition) {
    anchor = UI::GetWindowPos();
  }

  // Determine racing state
  bool isRacing = !waitForCarReset && !resetData && !isFinished && hasPlayerRaced;
  int liveTime = 0;
  if (isRacing) {
    liveTime = GetCurrentPlayerRaceTime() - prevLapRaceTime;
    if (liveTime < 0) liveTime = 0;
  }

  // 3-column table: Lap | +/- | Accumulated time (to tenth)
  if (UI::BeginTable("splits", 3, UI::TableFlags::SizingFixedFit)) {
    UI::TableNextColumn(); SetMinWidth(32); UI::Text("Lap");
    UI::TableNextColumn(); SetMinWidth(72); UI::Text("+/-");
    UI::TableNextColumn(); SetMinWidth(72); UI::Text("Time");

    for (int i = 0; i < 10; i++) {
      UI::TableNextRow();
      bool completed = lapTimes[i] != -1;
      bool active    = isRacing && (i == currentLap);

      vec4 gold = vec4(1.0f, 0.84f, 0.0f, 1.0f);

      if (completed) {
        bool hasBest  = bestLapTimes[i] != -1;
        int delta     = hasBest ? (lapTimes[i] - bestLapTimes[i]) : 0;
        bool isGold   = bestAllTimeLapTimes[i] > 0 && lapTimes[i] <= bestAllTimeLapTimes[i];
        vec4 deltaColor;
        if (!hasBest || delta == 0) {
          deltaColor = vec4(1.f, 1.f, 1.f, 1.f);
        } else if (delta < 0) {
          deltaColor = vec4(0.4f, 1.0f, 0.4f, 1.0f);
        } else {
          deltaColor = vec4(1.0f, 0.4f, 0.4f, 1.0f);
        }
        UI::TableNextColumn(); UI::Text("" + (i + 1));
        UI::PushStyleColor(UI::Col::Text, deltaColor);
        UI::TableNextColumn(); UI::Text(hasBest ? FormatDelta(delta) : "-");
        UI::PopStyleColor();
        if (isGold) UI::PushStyleColor(UI::Col::Text, gold);
        UI::TableNextColumn(); UI::Text(FormatTenth(lapTimes[i]));
        if (isGold) UI::PopStyleColor();

      } else if (active) {
        bool hasBest  = bestLapTimes[i] != -1;
        int liveDelta = hasBest ? (liveTime - bestLapTimes[i]) : 0;
        bool showDelta = hasBest && liveDelta >= -5000;
        UI::TableNextColumn(); UI::Text("" + (i + 1));
        if (showDelta) {
          vec4 deltaColor;
          if (liveDelta < 0)      deltaColor = vec4(0.4f, 1.0f, 0.4f, 1.0f);
          else if (liveDelta > 0) deltaColor = vec4(1.0f, 0.4f, 0.4f, 1.0f);
          else                    deltaColor = vec4(0.6f, 0.6f, 0.6f, 1.0f);
          UI::PushStyleColor(UI::Col::Text, deltaColor);
          UI::TableNextColumn(); UI::Text(FormatDelta(liveDelta));
          UI::PopStyleColor();
          UI::TableNextColumn(); UI::Text(FormatTenth(liveTime));
        } else {
          UI::TableNextColumn(); UI::Text("-");
          UI::TableNextColumn(); UI::Text(FormatTenth(liveTime));
        }

      } else {
        UI::TableNextColumn(); UI::Text("" + (i + 1));
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
    int totalRun = 0;
    int bestForCompleted = 0;
    bool hasCompletedLap = false;
    bool allCompletedHaveBest = true;
    for (int i = 0; i < 10; i++) {
      if (lapTimes[i] != -1) {
        totalRun += lapTimes[i];
        hasCompletedLap = true;
        if (bestLapTimes[i] != -1) bestForCompleted += bestLapTimes[i];
        else allCompletedHaveBest = false;
      }
    }
    int displayTotal = totalRun + (isRacing ? liveTime : 0);
    bool hasTotal = displayTotal > 0 || isFinished;
    bool showTotalDelta = hasCompletedLap && allCompletedHaveBest;
    int totalDelta = showTotalDelta ? (totalRun - bestForCompleted) : 0;

    vec4 totalColor;
    if (!showTotalDelta || totalDelta == 0) {
      totalColor = vec4(1.f, 1.f, 1.f, 1.f);
    } else if (totalDelta < 0) {
      totalColor = vec4(0.4f, 1.0f, 0.4f, 1.0f);
    } else {
      totalColor = vec4(1.0f, 0.4f, 0.4f, 1.0f);
    }

    UI::TableNextColumn();
    UI::PushStyleColor(UI::Col::Text, totalColor);
    UI::TableNextColumn(); UI::Text(showTotalDelta ? FormatDelta(totalDelta) : "-");
    UI::PopStyleColor();
    UI::TableNextColumn(); UI::Text(hasTotal ? FormatTenth(displayTotal) : "-");

    UI::EndTable();
  }

  UI::End();

  RenderCpTable();

  UI::PopFont();
}

void RenderCpTable() {
  if (!cpTableVisible) return;

  auto app = cast<CTrackMania>(GetApp());
#if TMNEXT || MP4
  auto map = app.RootMap;
#endif

  if (!isMultiLap) return;

  if (hideWithIFace) {
    auto playground = app.CurrentPlayground;
    if (playground is null || playground.Interface is null ||
        !UI::IsGameUIVisible()) {
      return;
    }
  }

  if (map is null || map.MapInfo.MapUid == "") return;

  // determine column count from data
  int numCols = numCps;
  for (uint i = 0; i < allLapCpTimes.Length; i++) {
    if (int(allLapCpTimes[i].Length) > numCols) numCols = int(allLapCpTimes[i].Length);
  }
  if (int(currLapCpTimes.Length) > numCols) numCols = int(currLapCpTimes.Length);
  if (numCols == 0) return;

  if (lockPosition) {
    UI::SetNextWindowPos(int(anchorCp.x), int(anchorCp.y), UI::Cond::Always);
  } else {
    UI::SetNextWindowPos(int(anchorCp.x), int(anchorCp.y), UI::Cond::FirstUseEver);
  }

  int windowFlags =
      UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoCollapse |
      UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking;
  if (!UI::IsOverlayShown()) {
    windowFlags |= UI::WindowFlags::NoInputs;
  }

  UI::Begin("CpTimes", windowFlags);

  if (!lockPosition) {
    anchorCp = UI::GetWindowPos();
  }

  bool isRacing = !waitForCarReset && !resetData && !isFinished && hasPlayerRaced;

  // precompute best-ever per CP position across all laps (mode 3)
  array<int> bestEverCp;
  for (int j = 0; j < numCols; j++) {
    int best = 0;
    for (uint li = 0; li < bestAllTimeCpTimes.Length; li++) {
      if (j < int(bestAllTimeCpTimes[li].Length)) {
        int t = bestAllTimeCpTimes[li][j];
        if (t > 0 && (best == 0 || t < best)) best = t;
      }
    }
    bestEverCp.InsertLast(best);
  }

  bool deltaMode = cpDisplayMode > 0;
  int colWidth = deltaMode ? 52 : 36;

  if (UI::BeginTable("cptable", numCols + 1, UI::TableFlags::SizingFixedFit)) {
    // header row
    UI::TableNextColumn(); SetMinWidth(16); UI::Text("Lap");
    for (int j = 0; j < numCols; j++) {
      UI::TableNextColumn(); SetMinWidth(colWidth);
      UI::Text(j == numCols - 1 ? "Fin" : "CP" + (j + 1));
    }

    // 10 lap rows
    for (int i = 0; i < 10; i++) {
      UI::TableNextRow();
      bool completed = i < currentLap && int(allLapCpTimes.Length) > i;
      bool active    = isRacing && i == currentLap;

      if (completed || active) {
        UI::TableNextColumn(); UI::Text("" + (i + 1));
        array<int>@ cpTimes = active ? currLapCpTimes : allLapCpTimes[i];
        for (int j = 0; j < numCols; j++) {
          UI::TableNextColumn();
          if (j >= int(cpTimes.Length)) { UI::Text("-"); continue; }
          int t = cpTimes[j];
          if (!deltaMode) {
            UI::Text(FormatCpTime(t));
            continue;
          }
          int refTime = 0;
          if (cpDisplayMode == 1) {
            if (i < int(bestLapCpTimes.Length) && j < int(bestLapCpTimes[i].Length))
              refTime = bestLapCpTimes[i][j];
          } else if (cpDisplayMode == 2) {
            if (i < int(bestAllTimeCpTimes.Length) && j < int(bestAllTimeCpTimes[i].Length))
              refTime = bestAllTimeCpTimes[i][j];
          } else if (cpDisplayMode == 3) {
            if (j < int(bestEverCp.Length)) refTime = bestEverCp[j];
          }
          if (refTime == 0) { UI::Text(FormatCpTime(t)); continue; }
          int delta = t - refTime;
          vec4 color;
          if (delta < 0)      color = vec4(0.4f, 1.0f, 0.4f, 1.0f);
          else if (delta > 0) color = vec4(1.0f, 0.4f, 0.4f, 1.0f);
          else                color = vec4(1.f, 1.f, 1.f, 1.f);
          UI::PushStyleColor(UI::Col::Text, color);
          UI::Text(FormatDelta(delta));
          UI::PopStyleColor();
        }
      } else {
        UI::TableNextColumn(); UI::Text("" + (i + 1));
        for (int j = 0; j < numCols; j++) {
          UI::TableNextColumn(); UI::Text("-");
        }
      }
    }

    UI::EndTable();
  }

  UI::End();
}
