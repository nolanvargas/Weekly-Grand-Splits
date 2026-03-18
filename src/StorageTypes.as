class StorageAttempt {
  int id = 0;
  array<array<int>> laps;
}

class StorageFile {
  array<StorageAttempt> attempts;
  // Note: JSON stores only archived attempts; best/reference baselines are derived at runtime.

  // Serializes the storage file into a JSON object suitable for writing to disk.
  Json::Value@ ToJson() {
    Json::Value@ root = Json::Object();

    Json::Value@ attArr = Json::Array();
    for (uint i = 0; i < attempts.Length; i++) {
      Json::Value@ atObj = Json::Object();
      atObj["id"] = Json::Value(attempts[i].id);
      atObj["laps"] = Build2DArray(attempts[i].laps);
      attArr.Add(atObj);
    }
    root["attempts"] = attArr;

    return root;
  }

  // Populates this storage file from a JSON object read from disk.
  void FromJson(Json::Value@ root) {
    attempts = {};
    if (root.HasKey("attempts")) {
      Json::Value@ attArr = root["attempts"];
      for (uint i = 0; i < attArr.Length; i++) {
        Json::Value@ atObj = attArr[i];
        if (!atObj.HasKey("id") || !atObj.HasKey("laps")) continue;
        StorageAttempt at;
        at.id = int(atObj["id"]);
        at.laps = Read2DArray(atObj["laps"]);
        attempts.InsertLast(at);
      }
    }
  }
}

// Global in-memory mirror of the JSON structure for the current map.
StorageFile g_storage;

