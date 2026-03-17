string FormatDelta(int ms) {
  string sign = ms < 0 ? "-" : "+";
  int abs = Math::Abs(ms);
  int secs = abs / 1000;
  if (useThousandths) {
    int millis = abs % 1000;
    string millisStr = millis < 10 ? "00" + millis : millis < 100 ? "0" + millis : "" + millis;
    return sign + secs + "." + millisStr;
  }
  int hundredths = (abs % 1000) / 10;
  string hundredthsStr = hundredths < 10 ? "0" + hundredths : "" + hundredths;
  return sign + secs + "." + hundredthsStr;
}

string FormatTenth(int ms) {
  int secs = (ms / 1000) % 60;
  int mins = ms / 60000;
  if (useThousandths) {
    int millis = ms % 1000;
    string millisStr = millis < 10 ? "00" + millis : millis < 100 ? "0" + millis : "" + millis;
    if (mins == 0) return secs + "." + millisStr;
    string secsStr = secs < 10 ? "0" + secs : "" + secs;
    return mins + ":" + secsStr + "." + millisStr;
  }
  int tenths = (ms / 100) % 10;
  if (mins == 0) return secs + "." + tenths;
  string secsStr = secs < 10 ? "0" + secs : "" + secs;
  return mins + ":" + secsStr + "." + tenths;
}

string FormatCpTime(int ms) {
  int secs = ms / 1000;
  if (useThousandths) {
    int millis = ms % 1000;
    string millisStr = millis < 10 ? "00" + millis : millis < 100 ? "0" + millis : "" + millis;
    return secs + "." + millisStr;
  }
  int hundredths = (ms % 1000) / 10;
  string hundredthsStr = hundredths < 10 ? "0" + hundredths : "" + hundredths;
  return secs + "." + hundredthsStr;
}
