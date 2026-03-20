// Stores archived attempts for the current map.
class RaceHistory {
  private array<Attempt@> _attempts;

  RaceHistory() {}

  void Clear() {
    _attempts.RemoveRange(0, _attempts.Length);
  }

  uint GetAttemptCount() const { return _attempts.Length; }

  Attempt@ GetAttemptByIndex(uint idx) {
    if (idx >= _attempts.Length) throw("GetAttemptByIndex: index out of range (index=" + idx + ", count=" + _attempts.Length + ")");
    return _attempts[idx];
  }

  void AddAttempt(Attempt@ src) {
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

  // Replaces an existing entry with the same id in-place, or appends if not found.
  void UpsertAttempt(Attempt@ src) {
    for (uint i = 0; i < _attempts.Length; i++) {
      if (_attempts[i].id == src.id) {
        Attempt@ at = Attempt();
        at.id = src.id;
        array<array<int>> lapCp = LapArraysFromRace(src);
        for (uint li = 0; li < lapCp.Length; li++) {
          array<int> row = lapCp[li];
          for (uint ci = 0; ci < row.Length; ci++) {
            at.SetCheckpointTime(int(li), int(ci), row[ci]);
          }
        }
        @_attempts[i] = at;
        return;
      }
    }
    AddAttempt(src);
  }
}

