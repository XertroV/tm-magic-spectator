/*  !! IMPORTANT !!
Please respect the integrity of the competition.
Please refuse any requests to assist in evading any
measures this plugin takes to protect the integrity
of the competition.
Please do not distribute altered copies of the DD2 map.
Thank you.
- XertroV
*/

//
const uint32 LOW_VELOCITY_TURTLE_MIN_TIME = 30000;

// Player state
class PlayerState {
    CSmPlayer@ player;
    CSceneVehicleVis@ vehicle;
    // mwid of the players login (also on player.User)
    uint playerScoreMwId;
    string playerName;
    string playerLogin;
    bool hasLeftGame = false;
    uint discontinuityCount = 0;
    bool stateFrozen = false;
    uint lastVehicleId = 0x0FF00000;
    vec4 color;
    bool isLocal = false;
    bool isViewed = false;
    uint lastRespawn;
    int raceTime;
    int lastRaceTime;
    uint creationTime;
    bool recheckedColor = false;
    uint veryLowVelocitySince;
    uint lowVelocitySince;
    bool isSpectator;
    string clubTag;
    string clubTagClean;
    string clubTagColored;

    vec3 vel;
    vec3 pos;

    PlayerState() {}
    PlayerState(CSmPlayer@ player) {
        @this.player = player;
        // bots have no score. players sometimes too on init
        if (player.User is null) return;
        playerScoreMwId = player.User.Id.Value;
        playerName = player.User.Name;
        playerLogin = player.User.Login;
        color = vec4(player.LinearHueSrgb, 1.0);
        isLocal = playerScoreMwId == g_LocalPlayerMwId;
        startnew(CoroutineFunc(CheckUpdateIsLocal));
        isSpectator = player.ScriptAPI.RequestsSpectate;
        clubTag = player.User.ClubTag;
        clubTagClean = Text::StripFormatCodes(clubTag);
        clubTagColored = Text::OpenplanetFormatCodes(clubTag);
    }

    string _wsid;
    string get_playerWsid() {
        if (_wsid.Length < 15) {
            _wsid = LoginToWSID(playerLogin);
        }
        return _wsid;
    }

    void CheckUpdateIsLocal() {
        isLocal = playerScoreMwId == g_LocalPlayerMwId;
    }

    // run this first to clear references
    void Reset() {
        @player = null;
        @vehicle = null;
    }

    void Update(CSmPlayer@ player) {
        if (Time::Now - creationTime < 500) {
            return;
        }
        @this.player = player;
        CSmScriptPlayer@ scriptPlayer = cast<CSmScriptPlayer>(player.ScriptAPI);
        if (scriptPlayer !is null) {
            lastRaceTime = raceTime;
            raceTime = GetRaceTimeFromStartTime(scriptPlayer.StartTime);
            isSpectator = scriptPlayer.RequestsSpectate;
            vel = scriptPlayer.Velocity;
            pos = scriptPlayer.Position;
        }
        if (!recheckedColor && Time::Now - creationTime > 5000) {
            recheckedColor = true;
#if DEV
            if (!Vec3Eq(color.xyz, player.LinearHueSrgb)) {
                dev_trace("Player " + playerName + " changed color: " + color.ToString() + " -> " + player.LinearHueSrgb.ToString());
            }
#endif
            color = vec4(player.LinearHueSrgb, 1.0);
        }
        this.isViewed = PS::guiPlayerMwId == playerScoreMwId;
        auto entId = player.GetCurrentEntityID();
        if (entId != lastVehicleId) {
            PS::UpdateVehicleId(this, entId);
            lastVehicleId = entId;
            // dev_trace('Updated vehicle id for ' + playerName + ": " + Text::Format("0x%08x", entId));
        }
    }


    void UpdateVehicleState(CSceneVehicleVis@ vis) {
        @vehicle = vis;
        // updatedThisFrame |= UpdatedFlags::Flying | UpdatedFlags::Falling | UpdatedFlags::Position;
        // auto @state = vis.AsyncState;
    }
}



// -1 = less, 0 = eq, 1 = greater
funcdef int PlayerLessF(PlayerState@ &in m1, PlayerState@ &in m2);
void playerQuicksort(PlayerState@[]@ arr, PlayerLessF@ f, int left = 0, int right = -1) {
    if (arr.Length < 2) return;
    if (right < 0) right = arr.Length - 1;
    int i = left;
    int j = right;
    PlayerState@ pivot = arr[(left + right) / 2];
    PlayerState@ temp;

    while (i <= j) {
        while (f(arr[i], pivot) < 0) i++;
        while (f(arr[j], pivot) > 0) j--;
        if (i <= j) {
            @temp = arr[i];
            @arr[i] = arr[j];
            @arr[j] = temp;
            i++;
            j--;
        }
    }

    if (left < j) playerQuicksort(arr, f, left, j);
    if (i < right) playerQuicksort(arr, f, i, right);
}
