bool g_fmtThousandths = false;

string ZeroPad2(int n) {
  return n < 10 ? "0" + n : "" + n;
}

string ZeroPad3(int n) {
  return n < 10 ? "00" + n : n < 100 ? "0" + n : "" + n;
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

string PadLeft(const string &in s, int width) {
  string result = s;
  while (int(result.Length) < width) result = " " + result;
  return result;
}

string PadRight(const string &in s, int width) {
  string result = s;
  while (int(result.Length) < width) result = result + " ";
  return result;
}
