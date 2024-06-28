
PlayerState@[] specSorted;
uint sortCounter = 0;
uint sortCounterModulo = 300;

void DrawSpectateTab() {
    auto specId = PS::viewedPlayer is null ? 0 : PS::viewedPlayer.playerScoreMwId;
    auto len = PS::players.Length;
    bool disableSpectate = !MAGIC_SPEC_ENABLED && !Spectate::IsSpectator;

    DrawSpectateEnabledAndExitMsg();

    float refreshProg = 1. - float(sortCounter) / float(sortCounterModulo);
    UI::PushStyleColor(UI::Col::PlotHistogram, Math::Lerp(cRed, cLimeGreen, refreshProg));
    UI::ProgressBar(refreshProg, vec2(-1, 2));
    UI::PopStyleColor();

    if (specSorted.Length != len) {
        sortCounter = 0;
    }

    // only sort every so often to avoid unstable ordering for neighboring ppl
    if (sortCounter == 0) {
        specSorted.Resize(0);
        specSorted.Reserve(len * 2);
        for (uint i = 0; i < len; i++) {
            _InsertPlayerSorted(specSorted, PS::players[i]);
        }
    }

    if (len > 1) sortCounter = (sortCounter + 1) % sortCounterModulo;

    UI::PushStyleColor(UI::Col::TableRowBgAlt, cGray35);
    if (UI::BeginTable("specplayers", 3, UI::TableFlags::SizingStretchProp | UI::TableFlags::ScrollY | UI::TableFlags::RowBg)) {
        UI::TableSetupColumn("Spec", UI::TableColumnFlags::WidthFixed, 40. * UI_SCALE);
        UI::TableSetupColumn("Race Time", UI::TableColumnFlags::WidthFixed, 100. * UI_SCALE);
        UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
        UI::TableHeadersRow();

        PlayerState@ p;
        bool isSpeccing;
        UI::ListClipper clip(specSorted.Length);
        while (clip.Step()) {
            for (int i = clip.DisplayStart; i < clip.DisplayEnd; i++) {
                @p = specSorted[i];
                isSpeccing = specId == p.playerScoreMwId;
                UI::PushID('spec'+i);

                UI::TableNextRow();
                UI::TableNextColumn();
                UI::BeginDisabled(disableSpectate || p.isSpectator || p.isLocal);
                if (UI::Button((isSpeccing) ? Icons::EyeSlash : Icons::Eye)) {
                    if (isSpeccing) {
                        Spectate::StopSpectating();
                    } else {
                        Spectate::SpectatePlayer(p);
                    }
                }
                UI::EndDisabled();

                UI::TableNextColumn();
                UI::Text(Time::Format(p.raceTime));

                UI::TableNextColumn();
                UI::Text((p.clubTag.Length > 0 ? "[\\$<"+p.clubTagColored+"\\$>] " : "") + p.playerName);

                UI::PopID();
            }
        }

        UI::EndTable();
    }
    UI::PopStyleColor();
}

void DrawSpectateEnabledAndExitMsg() {
    UI::AlignTextToFramePadding();
    UI::Indent();
    UI::TextWrapped("\\$4f4Magic Spectating Enabled!\\$z Spectating while driving will not kill your run. Press ESC to exit. Camera changes work. Movement auto-disables.");
    UI::BeginDisabled(!MagicSpectate::IsActive());
    if (UI::Button("Exit Magic Spectator")) {
        MagicSpectate::Reset();
    }
    UI::EndDisabled();
    UI::SameLine();
    UI::Dummy(vec2(30, 0));
    UI::SameLine();
    if (UI::Button("Close window and sleep")) {
        MagicSpectate::Reset();
        g_ShowWindow = false;
        g_ActiveForMap = 0;
    }
    AddSimpleTooltip("Disables main loop for performance until you open Magic Spectate again.");
    UI::Unindent();
}

void _InsertPlayerSorted(PlayerState@[]@ arr, PlayerState@ p) {
    int upper = int(arr.Length) - 1;
    if (upper < 0) {
        arr.InsertLast(p);
        return;
    }
    if (upper == 0) {
        if (arr[0].raceTime >= p.raceTime) {
            arr.InsertLast(p);
        } else {
            arr.InsertAt(0, p);
        }
        return;
    }
    int lower = 0;
    int mid;
    while (lower < upper) {
        mid = (lower + upper) / 2;
        // trace('l: ' + lower + ', m: ' + mid + ', u: ' + upper);
        if (arr[mid].raceTime < p.raceTime) {
            upper = mid;
        } else {
            lower = mid + 1;
        }
    }
    arr.InsertAt(lower, p);
}
