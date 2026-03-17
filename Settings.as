//visual studio code formatting messes with the [Setting ..] text causing open planet to crash
//moved to different file to get around that issue
#if __INTELLISENSE__
#include "cppIntellisense.h"
#endif

[Setting category="Display Settings" name="Window visible" description="To adjust the position of the window, click and drag while the Openplanet overlay is visible."]
bool windowVisible = true;

[Setting category="Display Settings" name="Hide on hidden interface"]
bool hideWithIFace = false;

[Setting category="Display Settings" name="Window position" drag]
vec2 anchor = vec2(0, 780);

[Setting category="Display Settings" name="Lock window position" description="Prevents the window moving when click and drag or when the game window changes size."]
bool lockPosition = false;

[Setting category="Display Settings" name="Font face" description="To avoid a memory issue with loading a large number of fonts, you must reload the plugin for font changes to be applied."]
string fontFace = "";

[Setting category="Display Settings" name="Font size" min=8 max=48 description="To avoid a memory issue with loading a large number of fonts, you must reload the plugin for font changes to be applied."]
int fontSize = 23;

[Setting category="Display Settings" name="CP Table visible"]
bool cpTableVisible = true;

[Setting category="Display Settings" name="CP Table position" drag]
vec2 anchorCp = vec2(300, 780);

[Setting category="Display Settings" name="Use thousandths precision"]
bool useThousandths = false;

[Setting category="Display Settings" name="CP time display mode" min=0 max=3 description="0 = Absolute  1 = Delta from PB run  2 = Delta from best at that lap+CP  3 = Delta from best all-time across all laps"]
int cpDisplayMode = 0;
