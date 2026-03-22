// Conversion helpers between raw 2D arrays and rich race types (Checkpoint / Lap / Attempt live in sibling .as files).

// Extracts lap CP times from an attempt into a zero-based 2D array.
array<array<int>> LapArraysFromRace(Attempt@ race) {
  array<array<int>> result;
  for (uint lapIndex = 1; lapIndex < race.laps.Length; lapIndex++) { // Laps start at 1
    Lap@ lap = race.laps[lapIndex];
    if (lap is null) continue;
    array<int> row;
    uint cpCount = lap.checkpoints.Length;
    for (uint cpIndex = 1; cpIndex < cpCount; cpIndex++) { // CPs start at 1
      row.InsertLast(lap.GetCheckpointTime(int(cpIndex)));
    }
    result.InsertLast(row);
  }
  return result;
}
