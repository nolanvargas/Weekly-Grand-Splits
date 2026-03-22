class Checkpoint {
  int time = 0; // ms

  Checkpoint() {}

  Checkpoint(int time) {
    if (time < 0) throw("Checkpoint time cannot be negative (time=" + time + ")");
    this.time = time;
  }
}
