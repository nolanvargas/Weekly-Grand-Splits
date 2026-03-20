// Conversion helpers between raw 2D arrays and rich race types (Checkpoint / Lap / Attempt live in sibling .as files).

// Builds an Attempt from a [lap][cp] 2D array of split deltas. Row length = stored CP count
// (shorter = in-progress; complete lap matches map numCps). Totals = Lap::GetLapTime().
Attempt@ RaceFromLapArrays(int attemptId, const array<array<int>> &in lapCpTimes) {
  Attempt@ race = Attempt();
  race.attemptId = attemptId;

  uint numLaps = lapCpTimes.Length;
  for (uint lapIndex = 0; lapIndex < numLaps; lapIndex++) {
    array<int> cpRow = lapCpTimes[lapIndex];
    Lap@ lap = Lap(int(lapIndex), 0);
    for (uint cpIndex = 0; cpIndex < cpRow.Length; cpIndex++) {
      lap.AppendCheckpointTime(cpRow[cpIndex]);
    }
    race.laps.InsertLast(lap);
  }

  return race;
}

// Extracts [lap][cp] CP times from a Race into a raw 2D array.
array<array<int>> LapArraysFromRace(Attempt@ race) {
  array<array<int>> result;
  for (uint lapIndex = 0; lapIndex < race.laps.Length; lapIndex++) {
    Lap@ lap = race.laps[lapIndex];
    if (lap is null) continue;
    array<int> row;
    uint cpCount = lap.checkpoints.Length;
    for (uint cpIndex = 0; cpIndex < cpCount; cpIndex++) {
      row.InsertLast(lap.GetCheckpointTime(int(cpIndex)));
    }
    result.InsertLast(row);
  }
  return result;
}
