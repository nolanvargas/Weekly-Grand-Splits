vec2 g_lapWinPos;
vec2 g_lapWinSize;
vec2 g_cpWinPos;
vec2 g_cpWinSize;
vec2 anchor = vec2(0, 780);
vec2 anchorCp = vec2(300, 780);

// Entry point copied and adapted from:
//   https://github.com/Phlarx/tm-ultimate-medals
void Render() {
  StorageFile@ storage = g_storage;
  auto app = cast<CTrackMania>(GetApp());

#if TMNEXT
  auto map = app.RootMap;
#endif

  if (!g_state.isMultiLap) {return;}

  if (lapHideWithIFace) {
    auto playground = app.CurrentPlayground;
    if (playground is null || playground.Interface is null ||
        !UI::IsGameUIVisible()) {
      return;
    }
  }

  if (!windowVisible || map is null || map.MapInfo.MapUid == "") {
    return;
  }
  UI::SetNextWindowPos(int(anchor.x), int(anchor.y), lapLockPosition ? UI::Cond::Always : UI::Cond::FirstUseEver);

  int windowFlags =
      UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoCollapse |
      UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking;
  if (!UI::IsOverlayShown()) {
    windowFlags |= UI::WindowFlags::NoInputs;
  }

  g_fmtThousandths = lapUseThousandths;
  UI::PushFont(lapFontStyle == FontStyle::Bold ? UI::Font::DefaultBold : lapFontStyle == FontStyle::Mono ? UI::Font::DefaultMono : UI::Font::Default);
  UI::PushFontSize(lapFontSize);
  if (lapGradientEnabled && g_lapWinSize.x > 0) DrawGradientBg(g_lapWinPos, g_lapWinSize, lapGradientRadial, lapGradientColor1, lapGradientColor2);
  UI::PushStyleColor(UI::Col::WindowBg, lapGradientEnabled ? vec4(0, 0, 0, 0) : lapWindowBgColor);
  UI::PushStyleColor(UI::Col::Text, lapTextColor);
  UI::Begin("LapTimes", windowFlags);

  if (!lapLockPosition) {
    anchor = UI::GetWindowPos();
  }
  g_lapWinPos  = UI::GetWindowPos();
  g_lapWinSize = UI::GetWindowSize();

  bool isRacing = !g_state.waitForCarReset && !g_state.resetData && !g_state.isFinished;
  int liveTime = 0;
  if (isRacing) {
    // while a run is active, compute a live lap time based on current race time minus the previous lap's finish.
    liveTime = GetCurrentPlayerRaceTime() - g_state.prevLapRaceTime;
    if (liveTime < 0) liveTime = 0;
  }

  if (lapTableTransposed) RenderLapTableTransposed(isRacing, liveTime);
  else                    RenderLapTableNormal(isRacing, liveTime);

  UI::End();
  UI::PopStyleColor(2);
  UI::PopFontSize();
  UI::PopFont();

  RenderCpTable();
}

