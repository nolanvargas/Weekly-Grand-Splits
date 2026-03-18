// Encapsulates race configuration for a single map.
class RaceConfig {
  private string _mapId;
  private int _numLaps = 1;
  private int _numCps = 0;
  private bool _isMultiLap = false;

  RaceConfig() {}

  RaceConfig(const string &in mapId, int numLaps, int numCps, bool isMultiLap) {
    Configure(mapId, numLaps, numCps, isMultiLap);
  }

  void Configure(const string &in mapId, int numLaps, int numCps, bool isMultiLap) {
    set_MapId(mapId);
    set_NumLaps(numLaps);
    set_NumCps(numCps);
    set_IsMultiLap(isMultiLap);
  }

  const string& get_MapId() const { return _mapId; }
  int get_NumLaps() const { return _numLaps; }
  int get_NumCps() const { return _numCps; }
  bool get_IsMultiLap() const { return _isMultiLap; }

  void set_NumLaps(int v) {
    _numLaps = Math::Max(1, v);
    if (_numLaps <= 1) _isMultiLap = false;
    // Actions: whenever the lap count drops to a single lap, force multi-lap mode off to keep configuration consistent.
  }

  void set_NumCps(int v) {
    _numCps = Math::Max(0, v);
  }

  void set_IsMultiLap(bool v) {
    // Only allow multi-lap if there is more than one lap.
    _isMultiLap = (_numLaps > 1) && v;
  }

  void set_MapId(const string &in v) { _mapId = v; }
}
