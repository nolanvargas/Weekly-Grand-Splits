vec2 g_lapWinSize;
vec2 g_cpWinSize;
vec2 anchor = vec2(0, 780);
vec2 anchorCp = vec2(300, 780);

// Navigates to and opens the plugin settings in the overlay.
void OpenMySettings() {
    auto plugins = Meta::AllPlugins();
    for (uint i = 0; i < plugins.Length; i++) {
        if (plugins[i].Name == "Weekly Grand Splits") {
            Meta::OpenSettings(plugins[i]);
            return;
        }
    }
}

// Main render entry point for the lap and CP windows.
void Render() {
  auto app = cast<CTrackMania>(GetApp());

  auto map = app.RootMap;

  RenderDebugState();

  if (!g_state.isMultiLap) {return;}

  g_uiState.Update();

  bool lapHideByIFace = lapHideWithIFace && (
    app.CurrentPlayground is null || app.CurrentPlayground.Interface is null ||
    !UI::IsGameUIVisible()
  );

  bool showLapWindow = windowVisible && map !is null && map.MapInfo.MapUid != "" && !lapHideByIFace;

  if (showLapWindow) {
    UI::SetNextWindowPos(int(anchor.x), int(anchor.y), lapLockPosition ? UI::Cond::Always : UI::Cond::FirstUseEver);

    int windowFlags =
        UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoCollapse |
        UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking;
    if (!UI::IsOverlayShown()) {
      windowFlags |= UI::WindowFlags::NoInputs;
    }

    g_fmtDecimals = int(lapPrecision);
    g_fmtRoundUp  = lapRoundUp;
    UI::PushFont(lapFontStyle == FontStyle::Bold ? UI::Font::DefaultBold : lapFontStyle == FontStyle::Mono ? UI::Font::DefaultMono : UI::Font::Default);
    UI::PushFontSize(lapFontSize);
    if (lapGradientEnabled && g_lapWinSize.x > 0) DrawGradientBg(anchor, g_lapWinSize, lapGradientRadial, lapGradientColor1, lapGradientColor2);
    bool isStale  = g_uiState.lapIsStale;
    bool isRacing = g_uiState.isRacing;
    int  liveTime = g_uiState.liveTime;
    UI::PushStyleColor(UI::Col::WindowBg, lapGradientEnabled ? vec4(0, 0, 0, 0) : lapWindowBgColor);
    UI::PushStyleColor(UI::Col::Text, isStale ? vec4(lapTextColor.x, lapTextColor.y, lapTextColor.z, lapTextColor.w * 0.45f) : lapTextColor);
    UI::Begin("LapTimes", windowFlags);

    if (!lapLockPosition) {
      anchor = UI::GetWindowPos();
    }
    g_lapWinSize = UI::GetWindowSize();

    if (lapShowMapName || lapShowMapAuthor) {
      if (lapShowMapName) {
        UI::Text(GetMapName());
      }
      if (lapShowMapAuthor) {
        string author = GetMapAuthor();
        if (author != "") {
          vec4 fadedColor = vec4(lapTextColor.x, lapTextColor.y, lapTextColor.z, lapTextColor.w * 0.45f);
          UI::PushStyleColor(UI::Col::Text, fadedColor);
          UI::PushFontSize(lapFontSize - 4);
          UI::Text(author);
          UI::PopFontSize();
          UI::PopStyleColor();
        }
      }
      UI::Separator();
    }

    if (lapTableTransposed) RenderLapTableTransposed(isRacing, liveTime);
    else                    RenderLapTableNormal(isRacing, liveTime);

    if (UI::IsOverlayShown() && !lapHideSettingsButton) {
        UI::Dummy(vec2(0, 2));
        UI::PushStyleColor(UI::Col::Button,        vec4(0, 0, 0, 0));
        UI::PushStyleColor(UI::Col::ButtonActive,  vec4(1, 1, 1, 0.15f));
        if (UI::Button(Icons::Cog)) OpenMySettings();
        UI::PopStyleColor(2);
    }

    UI::End();
    UI::PopStyleColor(2);
    UI::PopFontSize();
    UI::PopFont();
  } // if (showLapWindow)

  RenderCpTable();
}

