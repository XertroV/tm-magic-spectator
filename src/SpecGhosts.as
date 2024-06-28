#if DEPENDENCY_GHOSTS_PP

void DrawSpectateGhostsTab() {
    auto app = GetApp();
    auto ghost_mgr = Ghosts_PP::GetGhostClipsMgr(app);
    auto nbGhosts = ghost_mgr.Ghosts.Length;

    DrawSpectateEnabledAndExitMsg();

    UI::Separator();

    bool isSpeccing = false;

    UI::PushStyleColor(UI::Col::TableRowBgAlt, cGray35);
    if (UI::BeginTable("specghosts", 3, UI::TableFlags::SizingStretchProp | UI::TableFlags::ScrollY | UI::TableFlags::RowBg)) {
        UI::TableSetupColumn("Spec", UI::TableColumnFlags::WidthFixed, 40. * UI_SCALE);
        UI::TableSetupColumn("Race Time", UI::TableColumnFlags::WidthFixed, 100. * UI_SCALE);
        UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
        UI::TableHeadersRow();

        UI::ListClipper clip(nbGhosts);
        while (clip.Step()) {
            for (int i = clip.DisplayStart; i < clip.DisplayEnd; i++) {
                isSpeccing = MagicSpectate::spectatingGhostIx == i;
                auto @g = ghost_mgr.Ghosts[i];
                UI::PushID('specg'+i);

                UI::TableNextRow();
                UI::TableNextColumn();
                UI::BeginDisabled(false);
                if (UI::Button((isSpeccing) ? Icons::EyeSlash : Icons::Eye)) {
                    if (isSpeccing) {
                        Spectate::StopSpectating();
                    } else {
                        Spectate::SpectateGhost(i);
                    }
                }
                UI::EndDisabled();

                UI::TableNextColumn();
                UI::AlignTextToFramePadding();
                UI::Text(Time::Format(g.GhostModel.RaceTime));

                UI::TableNextColumn();
                UI::Text(g.GhostModel.GhostNickname);

                UI::PopID();
            }
        }

        UI::EndTable();
    }
    UI::PopStyleColor();
}

#endif
