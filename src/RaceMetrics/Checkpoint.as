class Checkpoint {
  int index = -1; // 0-based
  int time = 0;   // ms

  Checkpoint() {}

  Checkpoint(int index, int time) {
    this.index = index;
    this.time = time;
  }

  Checkpoint(int index) {
    this.index = index;
  }

  // from JSON
  Checkpoint(int index, int time) {
    this.index = index;
    this.time = time;
  }
}
