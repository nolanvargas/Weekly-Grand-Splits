// Aggregates attempts and best-ever metrics.
class RaceHistory {
  private array<Attempt@> _attempts;
  private int _pbAttemptId = -1;
  private int[] _bestAllTimeLapTotals;
  private array<array<int>> _bestAllTimeCpTimes;

  RaceHistory() {
    _bestAllTimeLapTotals.Resize(MAX_LAPS);
    for (int i = 0; i < MAX_LAPS; i++) _bestAllTimeLapTotals[i] = 0;
  }

  void Clear() {
    _attempts.RemoveRange(0, _attempts.Length);
    _pbAttemptId = -1;
    for (int i = 0; i < MAX_LAPS; i++) _bestAllTimeLapTotals[i] = 0;
    _bestAllTimeCpTimes.RemoveRange(0, _bestAllTimeCpTimes.Length);
  }

  uint GetAttemptCount() const { return _attempts.Length; }

  Attempt@ GetAttemptByIndex(uint idx) {
    if (idx >= _attempts.Length) throw("GetAttemptByIndex: index out of range (index=" + idx + ", count=" + _attempts.Length + ")");
    return _attempts[idx];
  }

  void AddAttempt(const Attempt &in src) {
    // Deep copy the attempt so history is not mutated by callers.
    Attempt@ at = Attempt();
    at.id = src.id;
    array<array<int>> lapCp = LapArraysFromRace(src);
    for (uint li = 0; li < lapCp.Length; li++) {
      array<int> row = lapCp[li];
      for (uint ci = 0; ci < row.Length; ci++) {
        at.SetCheckpointTime(int(li), int(ci), row[ci]);
      }
    }
    _attempts.InsertLast(at);
  }

  int get_PbAttemptId() const { return _pbAttemptId; }
  void set_PbAttemptId(int v) { 
    if (v < 0) {
      throw("set_PbAttemptId: negative id not allowed (value=" + v + ")");
    }
    _pbAttemptId = v;
  }

  int GetBestAllTimeLapTotal(int idx) const {
    if (idx < 0 || idx >= MAX_LAPS) throw("GetBestAllTimeLapTotal: index out of range (index=" + idx + ", count=" + MAX_LAPS + ")");
    return _bestAllTimeLapTotals[idx];
  }

  void SetBestAllTimeLapTotal(int idx, int time) {
    if (idx < 0 || idx >= MAX_LAPS) throw("SetBestAllTimeLapTotal: index out of range (index=" + idx + ", count=" + MAX_LAPS + ")");
    // Actions: silently ignore attempts to write a best total outside the legal lap index bounds.
    _bestAllTimeLapTotals[idx] = Math::Max(0, time);
  }

  array<array<int>>@ GetBestAllTimeCpTimes() { return _bestAllTimeCpTimes; }

  void UpdateCpBest(int lapIdx, int cpIdx, int time) {
    if (lapIdx < 0 || cpIdx < 0 || time <= 0) throw("UpdateCpBest: invalid indices or non-positive time (lapIdx=" + lapIdx + ", cpIdx=" + cpIdx + ", time=" + time + ")");
    // Actions: ignore invalid indices or non-positive times so only meaningful CP splits are recorded as bests.
    int[] empty;
    while (int(_bestAllTimeCpTimes.Length) <= lapIdx) _bestAllTimeCpTimes.InsertLast(empty);
    while (int(_bestAllTimeCpTimes[lapIdx].Length) <= cpIdx) _bestAllTimeCpTimes[lapIdx].InsertLast(0);

    if (_bestAllTimeCpTimes[lapIdx][cpIdx] == 0 || time < _bestAllTimeCpTimes[lapIdx][cpIdx]) {
      // Actions: when there is no prior best or the new split is faster, replace the stored best CP time for this [lap, cp].
      _bestAllTimeCpTimes[lapIdx][cpIdx] = time;
    }
  }
}

