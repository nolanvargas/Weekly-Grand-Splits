int  g_fmtDecimals = 1;
bool g_fmtRoundUp  = false;

// Rounds milliseconds to the nearest unit for the current decimal precision.
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

// Returns a two-digit zero-padded string for the given value.
string ZeroPad2(int value) {
  return value < 10 ? "0" + value : "" + value;
}

// Returns a three-digit zero-padded string for the given value.
string ZeroPad3(int value) {
  return value < 10 ? "00" + value : value < 100 ? "0" + value : "" + value;
}

// Returns the sub-second portion formatted to the current decimal depth.
string SubSec(int ms) {
  switch (g_fmtDecimals) {
    case 1: return "." + ((ms / 100) % 10);
    case 2: return "." + ZeroPad2((ms % 1000) / 10);
    case 3: return "." + ZeroPad3(ms % 1000);
    default: return ""; // 0 decimals
  }
}

// Formats a millisecond delta value as a signed time string.
string FormatDelta(int ms) {
  string sign = ms < 0 ? "-" : "+";
  int v = RoundMs(Math::Abs(ms));
  return sign + (v / 1000) + SubSec(v);
}

// Formats milliseconds as a lap time string with sub-second precision.
string FormatTenth(int ms) {
  int v = RoundMs(ms);
  int secs = (v / 1000) % 60;
  int mins = v / 60000;
  if (mins == 0) return secs + SubSec(v);
  return mins + ":" + ZeroPad2(secs) + SubSec(v);
}

// Formats a checkpoint split time in seconds with sub-second precision.
string FormatCpTime(int ms) {
  int v = RoundMs(ms);
  return (v / 1000) + SubSec(v);
}
