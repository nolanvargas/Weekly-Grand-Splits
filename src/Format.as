bool g_fmtThousandths = false;

string ZeroPad2(int value) {
  return value < 10 ? "0" + value : "" + value;
}

string ZeroPad3(int value) {
  return value < 10 ? "00" + value : value < 100 ? "0" + value : "" + value;
}

// Returns ".xx" (hundredths) or ".xxx" (thousandths)
string SubSecHundredths(int ms) {
  if (g_fmtThousandths) return "." + ZeroPad3(ms % 1000);
  return "." + ZeroPad2((ms % 1000) / 10);
}

// Returns ".x" (tenths) or ".xxx" (thousandths)
string SubSecTenths(int ms) {
  if (g_fmtThousandths) return "." + ZeroPad3(ms % 1000);
  return "." + ((ms / 100) % 10);
}

string FormatDelta(int ms) {
  string sign = ms < 0 ? "-" : "+";
  int abs = Math::Abs(ms);
  return sign + (abs / 1000) + SubSecHundredths(abs);
}

string FormatTenth(int ms) {
  int secs = (ms / 1000) % 60;
  int mins = ms / 60000;
  if (mins == 0) return secs + SubSecTenths(ms);
  return mins + ":" + ZeroPad2(secs) + SubSecTenths(ms);
}

string FormatCpTime(int ms) {
  return (ms / 1000) + SubSecHundredths(ms);
}

string PadLeft(const string &in text, int width) {
  string result = text;
  while (int(result.Length) < width) result = " " + result;
  return result;
}

string PadRight(const string &in text, int width) {
  string result = text;
  while (int(result.Length) < width) result = result + " ";
  return result;
}
