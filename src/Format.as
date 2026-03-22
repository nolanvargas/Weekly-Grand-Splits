int  g_fmtDecimals = 1;
bool g_fmtRoundUp  = false;

// Rounds ms to the nearest unit for the current decimal precision.
// No effect when g_fmtDecimals == 3 (full precision) or round-up is off.
int RoundMs(int ms) {
  if (!g_fmtRoundUp || g_fmtDecimals >= 3) return ms;
  int granularity;
  switch (g_fmtDecimals) {
    case 0: granularity = 1000; break;
    case 1: granularity = 100;  break;
    default: granularity = 10;  break; // case 2
  }
  return ((ms + granularity / 2) / granularity) * granularity;
}

string ZeroPad2(int value) {
  return value < 10 ? "0" + value : "" + value;
}

string ZeroPad3(int value) {
  return value < 10 ? "00" + value : value < 100 ? "0" + value : "" + value;
}

// Returns the sub-second portion of ms as ".x", ".xx", ".xxx", or "" based on g_fmtDecimals.
string SubSec(int ms) {
  switch (g_fmtDecimals) {
    case 1: return "." + ((ms / 100) % 10);
    case 2: return "." + ZeroPad2((ms % 1000) / 10);
    case 3: return "." + ZeroPad3(ms % 1000);
    default: return ""; // 0 decimals
  }
}

string FormatDelta(int ms) {
  string sign = ms < 0 ? "-" : "+";
  int v = RoundMs(Math::Abs(ms));
  return sign + (v / 1000) + SubSec(v);
}

string FormatTenth(int ms) {
  int v = RoundMs(ms);
  int secs = (v / 1000) % 60;
  int mins = v / 60000;
  if (mins == 0) return secs + SubSec(v);
  return mins + ":" + ZeroPad2(secs) + SubSec(v);
}

string FormatCpTime(int ms) {
  int v = RoundMs(ms);
  return (v / 1000) + SubSec(v);
}
