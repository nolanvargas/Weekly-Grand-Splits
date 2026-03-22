class Checkpoint {
  int time = 0; // ms

  // Constructs a checkpoint entry with a default time of zero.
  Checkpoint() {}

  // Constructs a checkpoint with the given time and validates it.
  Checkpoint(int time) {
    if (time < 0) throw("Checkpoint time cannot be negative (time=" + time + ")");
    this.time = time;
  }
}
