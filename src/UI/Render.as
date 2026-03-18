// Top-level UI rendering for lap and checkpoint tables.
// This file controls window placement, visibility guards, and overall layout.

vec2 g_lapWinPos;
vec2 g_lapWinSize;
vec2 g_cpWinPos;
vec2 g_cpWinSize;
vec2 anchor = vec2(0, 780);
vec2 anchorCp = vec2(300, 780);

// Entry point copied and adapted from:
//   https://github.com/Phlarx/tm-ultimate-medals
// Render() is called every frame while the overlay is active.
void Render() {
  StorageFile@ storage = g_storage;
  auto app = cast<CTrackMania>(GetApp());

#if TMNEXT || MP4
  auto map = app.RootMap;
#endif

  if (!g_state.isMultiLap) {return;}
  // Actions: if the current map is not multi-lap, hide all plugin UI and skip drawing any lap/CP tables.

  if (lapHideWithIFace) {
    // Actions: when this option is enabled, only render the overlay while the in-game UI is visible and a valid playground/interface exists.
    auto playground = app.CurrentPlayground;
    if (playground is null || playground.Interface is null ||
        !UI::IsGameUIVisible()) {
      // Actions: bail out of rendering when there is no active playground, no interface, or the Trackmania UI is hidden.
      return;
    }
  }

  if (!windowVisible || map is null || map.MapInfo.MapUid == "") {
    // Actions: if the window is globally disabled or the map is invalid, skip drawing and exit early.
    return;
  }

  if (lapLockPosition) {
    // Actions: when position is locked, always reuse the stored anchor as the next window position.
    UI::SetNextWindowPos(int(anchor.x), int(anchor.y), UI::Cond::Always);
  } else {
    // Actions: when not locked, let ImGui pick an initial position but allow the user to drag and persist a new anchor.
    UI::SetNextWindowPos(int(anchor.x), int(anchor.y), UI::Cond::FirstUseEver);
  }

  int windowFlags =
      UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoCollapse |
      UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking;
  if (!UI::IsOverlayShown()) {
    // Actions: when the overlay is hidden, still render for screenshots but disable input so the window is not interactive.
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
    // Actions: while a run is active, compute a live lap time based on current race time minus the previous lap's finish.
    liveTime = GetCurrentPlayerRaceTime() - g_state.prevLapRaceTime;
    if (liveTime < 0) liveTime = 0;
    // Actions: clamp negative live times to zero to avoid confusing UI output.
  }

  if (lapTableTransposed) RenderLapTableTransposed(isRacing, liveTime);
  else                    RenderLapTableNormal(isRacing, liveTime);
  // Actions: depending on the layout mode, delegate to either the transposed or normal lap table renderer with the current timing context.

  UI::End();
  UI::PopStyleColor(2);
  UI::PopFontSize();
  UI::PopFont();

  RenderCpTable();
}

