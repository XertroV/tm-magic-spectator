
uint g_LocalPlayerMwId = -1;

void AwaitLocalPlayerMwId() {
    while (g_LocalPlayerMwId == -1) {
        g_LocalPlayerMwId = GetLocalPlayerMwId();
        if (g_LocalPlayerMwId == -1) yield();
        else break;
    }
    // for (uint i = 0; i < PS::players.Length; i++) {
    //     PS::players[i].CheckUpdateIsLocal();
    // }
}

string _LocalPlayerLogin;

uint GetLocalPlayerMwId() {
    auto app = GetApp();
    if (app.LocalPlayerInfo is null) return -1;
    _LocalPlayerLogin = app.LocalPlayerInfo.Id.GetName();
    return app.LocalPlayerInfo.Id.Value;
}

uint GetViewedPlayerMwId(CSmArenaClient@ cp) {
    try {
        return cast<CSmPlayer>(cp.GameTerminals[0].GUIPlayer).Score.Id.Value;
    } catch {
        return 0;
    }
}

int GetGameTime() {
    auto pg = GetApp().Network.PlaygroundInterfaceScriptHandler;
    if (pg is null) return 0;
    return int(pg.GameTime);
}

int GetRaceTimeFromStartTime(int startTime) {
    return GetGameTime() - startTime;
}
