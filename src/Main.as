const string PluginName = Meta::ExecutingPlugin().Name;
const string MenuIconColor = "\\$5fa";
const string PluginIcon =  Icons::Magic + Icons::Binoculars;
const string MenuTitle = MenuIconColor + PluginIcon + "\\$z " + PluginName;

int f_Nvg_ExoRegular = nvg::LoadFont("Fonts/Exo-Regular.ttf", true, true);
int f_Nvg_ExoExtraBoldItalic = nvg::LoadFont("Fonts/Exo-ExtraBoldItalic.ttf", true, true);

void Main() {
    g_LocalPlayerMwId = GetLocalPlayerMwId();
    startnew(AwaitLocalPlayerMwId);
    startnew(MagicSpectate::Load);
}

vec2 g_screen;

void RenderEarly() {
    g_screen = vec2(Draw::GetWidth(), Draw::GetHeight());
    RenderEarlyInner();
}

bool g_Active = false;

bool RenderEarlyInner() {
    g_Active = false;
    auto app = GetApp();
    if (app.RootMap is null) return RE_ClearPlayers();
    if (app.RootMap.Id.Value != g_ActiveForMap) return RE_ClearPlayers();
    if (app.CurrentPlayground is null) return RE_ClearPlayers();
    if (app.CurrentPlayground.GameTerminals.Length == 0) return RE_ClearPlayers();
    if (app.CurrentPlayground.GameTerminals[0].ControlledPlayer is null) return RE_ClearPlayers();
    if (app.CurrentPlayground.UIConfigs.Length == 0) return RE_ClearPlayers();
    PS::UpdatePlayers(app);
    g_Active = true;
    return true;
}

void Render() {
    if (!g_Active) return;
    MagicSpectate::Render();
}

// requires game restart so only need to set once.
const float UI_SCALE = UI::GetScale();

[Setting hidden]
bool g_ShowWindow = false;

void RenderInterface() {
    if (!g_ShowWindow) return;
    UI::SetNextWindowPos(g_screen.x * .24, g_screen.y * .25, UI::Cond::FirstUseEver);
    UI::SetNextWindowSize(470, 250, UI::Cond::FirstUseEver);
    if (UI::Begin(PluginName, g_ShowWindow, UI::WindowFlags::NoCollapse)) {
        RenderInner();
    }
    UI::End();
}

uint g_ActiveForMap = 0;

void RenderInner() {
    auto app = GetApp();
    if (app.RootMap !is null) {
        g_ActiveForMap = app.RootMap.Id.Value;
    } else {
        UI::Text("No map");
        return;
    }
    if (app.CurrentPlayground is null) {
        UI::Text("No playground");
        return;
    }
    UI::BeginTabBar("tabs");
    if (UI::BeginTabItem("Players")) {
        DrawSpectateTab();
        UI::EndTabItem();
    }
    if (UI::BeginTabItem("Ghosts")) {
#if DEPENDENCY_GHOSTS_PP
        DrawSpectateGhostsTab();
#else
        UI::Text("Install Ghosts++ to spectate ghosts");
#endif
        UI::EndTabItem();
    }

    UI::EndTabBar();
}

float g_vScale = 1.0;
float stdHeightPx = 1440.0;

void Update() {
    g_vScale = g_screen.y / stdHeightPx;
}


void RenderMenu() {
    if (UI::MenuItem(MenuTitle, "", g_ShowWindow)) {
        g_ShowWindow = !g_ShowWindow;
    }
}



void OnDestroyed() { _Unload(); }
void OnDisabled() { _Unload(); }
void _Unload() {
    MagicSpectate::Unload();
}



UI::InputBlocking OnKeyPress(bool down, VirtualKey key) {
    if (key == VirtualKey::Escape && down && MagicSpectate::CheckEscPress()) {
        return UI::InputBlocking::Block;
    }
    return UI::InputBlocking::DoNothing;
}



void Notify(const string &in msg, int time = 5000) {
    UI::ShowNotification(Meta::ExecutingPlugin().Name, msg, time);
    print("Notified: " + msg);
}
void Dev_Notify(const string &in msg) {
#if DEV
    UI::ShowNotification(Meta::ExecutingPlugin().Name, msg);
    print("Notified: " + msg);
#endif
}

void NotifySuccess(const string &in msg) {
    UI::ShowNotification(Meta::ExecutingPlugin().Name, msg, vec4(.4, .7, .1, .3), 10000);
    print("Notified Success: " + msg);
}

void NotifyError(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Error", msg, vec4(.9, .3, .1, .3), 15000);
}

void NotifyWarning(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Warning", msg, vec4(.9, .6, .2, .3), 15000);
}

void Dev_NotifyWarning(const string &in msg) {
    warn(msg);
#if DEV
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Warning", msg, vec4(.9, .6, .2, .3), 15000);
#endif
}

dictionary warnDebounce;
void NotifyWarningDebounce(const string &in msg, uint ms) {
    warn(msg);
    bool showWarn = !warnDebounce.Exists(msg) || Time::Now - uint(warnDebounce[msg]) > ms;
    if (showWarn) {
        UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Warning", msg, vec4(.9, .6, .2, .3), 15000);
        warnDebounce[msg] = Time::Now;
    }
}


void dev_trace(const string &in msg) {
#if DEV
    trace(msg);
#endif
}


void AddSimpleTooltip(const string &in msg) {
    if (UI::IsItemHovered()) {
        UI::SetNextWindowSize(400, 0, UI::Cond::Appearing);
        UI::BeginTooltip();
        UI::TextWrapped(msg);
        UI::EndTooltip();
    }
}
