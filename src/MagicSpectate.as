[Setting hidden]
bool S_ClickMinimapToMagicSpectate = true;

[Setting hidden]
bool S_DrawInputsWhileMagicSpec = true;

[Setting hidden]
bool S_PauseTimerWhileSpectating = true;

#if DEPENDENCY_MLHOOK
const bool MAGIC_SPEC_ENABLED = true;

// This is particularly for NON-spectate mode (i.e., players while driving)
// It will allow them to spectate someone without killing their run.
namespace MagicSpectate {
    void Unload() {
        Reset();
        MLHook::UnregisterMLHooksAndRemoveInjectedML();
    }

    void Load() {
        trace("Registered ML Exec callback for Magic Spectator");
        MLHook::RegisterPlaygroundMLExecutionPointCallback(onMLExec);
        if (!IsMLHookEnabled()) {
            NotifyWarning("MLHook is disabled! Click to spectate may not work correctly.");
        }
    }

    int spectatingGhostIx = -1;

    void Reset() {
        @currentlySpectating = null;
        spectatingGhostIx = -1;
    }

    void Render() {
        if ((Time::Now - movementAlarmLastTime) < 500) {
            _DrawMovementAlarm();
        }
        if (IsActive()) {
            _DrawCurrentlySpectatingUI();
        } else if (Spectate::IsSpectator) {
            _DrawGameSpectatingUI();
        }
    }

    bool CheckEscPress() {
        if (currentlySpectating !is null) {
            Reset();
            return true;
        }
        return false;
    }

    bool IsActive() {
        return currentlySpectating !is null || spectatingGhostIx >= 0;
    }
    PlayerState@ GetTarget() {
        if (currentlySpectating !is null) return currentlySpectating;
        return null;
    }

    void SpectatePlayer(PlayerState@ player) {
        trace('Magic Spectate: ' + player.playerName + ' / ' + Text::Format("%08x", player.lastVehicleId));
        @currentlySpectating = player;
        spectatingGhostIx = -1;
    }

    void SpectateGhost(int ix) {
        spectatingGhostIx = ix;
        @currentlySpectating = null;
    }

    uint movementAlarmLastTime = 0;
    bool movementAlarm = false;
    PlayerState@ currentlySpectating;
    void onMLExec(ref@ _x) {
        movementAlarm = false;
        if (!IsActive()) return;
        auto app = GetApp();
        if (app.GameScene is null || app.CurrentPlayground is null) {
            dev_trace("magic spectate resetting: game scene or curr pg null");
            Reset();
            return;
        }
        uint vehicleId = 0;
        if (currentlySpectating !is null) {
            vehicleId = currentlySpectating.lastVehicleId;
            if (currentlySpectating.vehicle is null || currentlySpectating.vehicle.AsyncState is null) {
                NotifyWarning("Turn on opponents to use magic spectate. (Otherwise, this is a bug.)");
                Reset();
                return;
            }
        } else if (spectatingGhostIx >= 0) {
#if DEPENDENCY_GHOSTS_PP
            auto ghost_mgr = Ghosts_PP::GetGhostClipsMgr(app);
            if (spectatingGhostIx >= ghost_mgr.Ghosts.Length) {
                dev_trace("magic spectate resetting: bad ghost ix");
                Reset();
                return;
            }
            auto g = ghost_mgr.Ghosts[spectatingGhostIx];
            vehicleId = Ghosts_PP::GetGhostVisEntityId(g);
#endif
        }

        movementAlarm = PS::localPlayer.vel.LengthSquared() > 0.13; // (PS::localPlayer.isFlying ? 0.13 : 0.02);
        if (movementAlarm) {
            movementAlarmLastTime = Time::Now;
            trace('movement alarm');
            Reset();
            return;
        }

        // do nothing if the vehicle id is invalid, it might become valid
        if (vehicleId == 0 || vehicleId & 0x0f000000 > 0x05000000) {
            // dev_trace("Bad vehicle id: " + Text::Format("%08x", vehicleId));
            return;
        }
        // auto @player = PS::GetPlayerFromVehicleId(vehicleId);
        // if (player is null) {
        //     dev_trace("magic spectate resetting: GetPlayerFromVehicleId null");
        //     Reset();
        //     return;
        // }
        _SetCameraVisIdTarget(app, vehicleId);
    }

    void _SetCameraVisIdTarget(CGameCtnApp@ app, uint vehicleId) {
        if (app is null || app.GameScene is null || app.CurrentPlayground is null) {
            Reset();
            return;
        }
        if (vehicleId > 0 && vehicleId & 0x0FF00000 != 0x0FF00000) {
            CMwNod@ gamecam = Dev::GetOffsetNod(app, O_GAMESCENE + 0x10);
            // vehicle id targeted by the camera
            Dev::SetOffset(gamecam, 0x44, vehicleId);
        } else {
            dev_trace("magic spectate resetting: _SetCameraVisIdTarget bad vehicleId: " + Text::Format("%08x", vehicleId));
            Reset();
        }
    }

#if DEPENDENCY_GHOSTS_PP
    void SetGhostAlpha_AfterMainLoop() {
        auto pg = cast<CSmArenaClient>(GetApp().CurrentPlayground);
        if (pg is null || pg.Arena is null || pg.Arena.Rules is null) return;
        CSmArenaRules_SetGhostAlpha(pg.Arena.Rules, 1.0);
    }
#endif

    void _DrawCurrentlySpectatingUI() {
        auto pad = SPEC_BG_PAD * g_vScale;
        auto namePosCM = SPEC_NAME_POS * g_screen;
        string name;
        vec4 color;
        PlayerState@ p = currentlySpectating;
        NGameGhostClips_SClipPlayerGhost@ g;
        if (p !is null) {
            name = p.playerName;
            if (p.clubTag.Length > 0) {
                name = "["+Text::StripFormatCodes(p.clubTag)+"] " + name;
            }
            color = p.color;
        } else {
#if DEPENDENCY_GHOSTS_PP
            auto ghost_mgr = Ghosts_PP::GetGhostClipsMgr(GetApp());
            @g = ghost_mgr.Ghosts[spectatingGhostIx];
            name = g.GhostModel.GhostNickname;
            color = vec4(g.GhostModel.LightTrailColor, 1.);
            startnew(SetGhostAlpha_AfterMainLoop).WithRunContext(Meta::RunContext::AfterMainLoop);
#endif
        }
        // Draw name at same place as normal spectate name
        nvg::Reset();
        nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
        nvg::FontFace(f_Nvg_ExoExtraBoldItalic);
        float fs = SPEC_NAME_HEIGHT * g_vScale;
        nvg::FontSize(fs);
        nvg::BeginPath();
        vec2 bgSize = nvg::TextBounds(name) + pad * 2.;
        vec2 bgTL = namePosCM - bgSize / 2.;
        nvg::FillColor(cBlack85);
        nvg::RoundedRect(bgTL, bgSize, pad.x);
        nvg::Fill();
        nvg::StrokeColor((cWhite50 + color) / 2.);
        nvg::StrokeWidth(2.0);
        nvg::Stroke();
        nvg::BeginPath();
        DrawText(SPEC_NAME_POS * g_screen + vec2(0, fs * .1), name, (cWhite + color) / 2.);
        // DrawTwitchName(twitchName, fs, pad, true);
        if (S_DrawInputsWhileMagicSpec) {
            if (S_ShowInputsWhenUIHidden || UI::IsGameUIVisible()) {
                if (p !is null) {
                    // trace('looking for vehicle: ' + Text::Format("%08x", p.lastVehicleId));
                    MS_RenderInputs(p.vehicle, color);
                }
                else {
#if DEPENDENCY_GHOSTS_PP
                    auto vehicleId = Ghosts_PP::GetGhostVisEntityId(g);
                    if (vehicleId == 0x0FF00000) return;
                    // trace('looking for vehicle: ' + Text::Format("%08x", vehicleId));
                    auto vss = VehicleState::GetAllVis(GetApp().GameScene);
                    for (uint i = 0; i < vss.Length; i++) {
                        auto vis = vss[i];
                        auto vid = Dev::GetOffsetUint32(vis, 0);
                        // trace('vid: ' + Text::Format("%08x", vid));
                        if (vehicleId == vid) {
                            // trace("Found vehicle: " + Text::Format("%08x", vehicleId) + " at " + i);
                            MS_RenderInputs(vis, color);
                            break;
                        }
                    }
#endif
                }
            }
        }
    }

    void MS_RenderInputs(CSceneVehicleVis@ vis, const vec4 &in color = cWhite) {
        if (vis is null) return;
        if (vis.AsyncState is null) return;
        auto inputsSize = vec2(S_InputsHeight * 2, S_InputsHeight) * g_screen.y;
        auto inputsPos = (g_screen - inputsSize) * vec2(S_InputsPosX, S_InputsPosY);
        inputsPos += inputsSize;
        nvg::Translate(inputsPos);
        Inputs::DrawInputs(vis.AsyncState, color, inputsSize);
        nvg::ResetTransform();
    }

    void _DrawMovementAlarm() {
        nvg::Reset();
        nvg::BeginPath();
        nvg::FontSize(50. * g_vScale);
        nvg::FontFace(f_Nvg_ExoExtraBoldItalic);
        nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
        DrawTextWithStroke(vec2(.5, 0.69) * g_screen, "Movement!", cRed, 4. * g_vScale);
    }

    void DrawMenu() {
        if (UI::BeginMenu("Magic Spectate")) {
            S_ClickMinimapToMagicSpectate = UI::Checkbox("Click Minimap to Magic Spectate", S_ClickMinimapToMagicSpectate);
            S_DrawInputsWhileMagicSpec = UI::Checkbox("Show Inputs While Magic Spectating", S_DrawInputsWhileMagicSpec);
            DrawInputsSettingsMenu();
            UI::EndMenu();
        }
    }
}

#else
const bool MAGIC_SPEC_ENABLED = false;
namespace MagicSpectate {
    void Unload() {}
    void Load() {}
    void Reset() {}
    void Render() {
        if (Spectate::IsSpectator) {
            _DrawGameSpectatingUI();
        }
    }
    void DrawMenu() {}
    void SpectatePlayer(PlayerState@ player) {}
    bool CheckEscPress() { return false; }
    bool IsActive() { return false; }
    PlayerState@ GetTarget() { return null; }
}
#endif


const uint16 O_GAMESCENE = GetOffset("CGameCtnApp", "GameScene");


namespace MagicSpectate {
    const float SPEC_NAME_HEIGHT = 50.;
    const vec2 SPEC_NAME_POS = vec2(.5, 0.8333333333333334);
    const vec2 SPEC_BG_PAD = vec2(18.);

    void _DrawGameSpectatingUI() {
    }
}


// This is for managing spectating more generally
namespace Spectate {
    void StopSpectating() {
        MagicSpectate::Reset();
        ServerStopSpectatingIfSpectator();
    }

    void SpectateGhost(uint ix) {
        MagicSpectate::SpectateGhost(ix);
    }

    void SpectatePlayer(PlayerState@ p) {
        // deactivate if we're in proper spectator mode
        if (IsSpectator && MagicSpectate::IsActive()) {
            MagicSpectate::Reset();
        }
        // if we are driving
        bool areWeDriving = PS::localPlayer !is null && PS::viewedPlayer !is null && PS::localPlayer.playerScoreMwId == PS::viewedPlayer.playerScoreMwId;
        if (MAGIC_SPEC_ENABLED && !IsSpectator && ((MagicSpectate::IsActive() || areWeDriving))) {
            MagicSpectate::SpectatePlayer(p);
        } else {
            ServerSpectatePlayer(p.playerLogin);
        }
    }

    void ServerSpectatePlayer(const string &in login) {
        auto net = GetApp().Network;
        auto api = net.PlaygroundClientScriptAPI;
        auto client = net.ClientManiaAppPlayground;
        api.SetSpectateTarget(login);
        // https://github.com/ezio416/tm-spectator-camera/blob/6a8f5180c90d37d15b830d238065fa7dab83b3cc/src/Main.as#L206
        client.ClientUI.Spectator_SetForcedTarget_Clear();
        api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Follow);
    }

    void ServerStopSpectatingIfSpectator() {
        auto api = GetApp().Network.PlaygroundClientScriptAPI;
        if (!api.IsSpectator) return;
        api.RequestSpectatorClient(false);
    }

    void ServerStartSpectatingIfNotSpectator() {
        auto api = GetApp().Network.PlaygroundClientScriptAPI;
        if (api.IsSpectator) return;
        api.RequestSpectatorClient(true);
    }

    bool get_IsSpectator() {
        return GetApp().Network.Spectator;
    }

    bool get_IsSpectatorOrMagicSpectator() {
        return MagicSpectate::IsActive() || IsSpectator;
    }
}



bool IsMLHookEnabled() {
    auto p = Meta::GetPluginFromSiteID(252);
    return p !is null && p.Enabled;
}
