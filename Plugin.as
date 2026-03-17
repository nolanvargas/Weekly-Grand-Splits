#include "src/Constants.as"
#include "src/State.as"
#include "src/GameAPI.as"
#include "src/Map.as"
#include "src/Storage.as"
#include "src/Records.as"
#include "src/Race.as"
#include "src/Format.as"
#include "src/Render.as"

void Main() {
  LoadFont();
  g_state.playerStartTime = GetPlayerStartTime();
}

void OnSettingsChanged() {
  // TODO: apply font size changes
}
