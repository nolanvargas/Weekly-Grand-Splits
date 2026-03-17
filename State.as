// timing
int prevLapRaceTime = 0;
// last waypoint cp id
int lastCP = 0;
int currentLap = 0;

int finishRaceTime = 0;

// map data
int numCps = 0;
string currentMap;
int numLaps = 0;

// current run lap times (-1 = not yet completed)
int[] lapTimes     = {-1,-1,-1,-1,-1,-1,-1,-1,-1,-1};
// best per-lap times from PB run (-1 = no data)
int[] bestLapTimes = {-1,-1,-1,-1,-1,-1,-1,-1,-1,-1};
// all-time best per-lap times across all runs ever (0 = no data)
int[] bestAllTimeLapTimes = {0,0,0,0,0,0,0,0,0,0};

// per-checkpoint splits: delta time from previous CP within the lap
int lastCpTime = 0;                          // absolute race time of last CP hit
int[] currLapCpTimes;                        // CP deltas for the lap currently being driven
array<array<int>> allLapCpTimes;             // [lap][cp] splits for current run
array<array<int>> bestLapCpTimes;            // [lap][cp] splits from the PB run
array<array<int>> bestAllTimeCpTimes;        // [lap][cp] best individual CP times ever

// attempt tracking
int currentAttemptId = 0;
int g_pbAttemptId = -1;                      // attempt_id of the current PB run
array<array<array<int>>> g_allAttempts;      // [attempt][lap][cp] — all finalized historical attempts
array<int> g_allAttemptIds;                  // parallel attempt ID list

// extra
bool waitForCarReset = true;
bool hasPlayerRaced = false;
bool resetData = true;
int playerStartTime = -1;
bool isMultiLap = false;
bool isFinished = false;

// font
string loadedFontFace = "";
int loadedFontSize = 0;
UI::Font @font = null;

// turbo extra's
bool hasFinishedMap = false;

void debugText(const string &in text) {
    // print(text);
}
