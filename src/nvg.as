const double TAU = 6.28318530717958647692;

const vec4 cMagenta = vec4(1, 0, 1, 1);
const vec4 cCyan =  vec4(0, 1, 1, 1);
const vec4 cGreen = vec4(0, 1, 0, 1);
const vec4 cBlue =  vec4(0, 0, 1, 1);
const vec4 cRed =   vec4(1, 0, 0, 1);
const vec4 cOrange = vec4(1, .4, .05, 1);
const vec4 cBlack =  vec4(0,0,0, 1);
const vec4 cBlack50 =  vec4(0,0,0, .5);
const vec4 cBlack75 =  vec4(0,0,0, .75);
const vec4 cBlack85 =  vec4(0,0,0, .85);
const vec4 cLightGray =  vec4(.8, .8, .8, 1);
const vec4 cGray =  vec4(.5, .5, .5, 1);
const vec4 cGray35 =  vec4(.35, .35, .35, .35);
const vec4 cWhite = vec4(1);
const vec4 cWhite75 = vec4(1,1,1,.75);
const vec4 cWhite50 = vec4(1,1,1,.5);
const vec4 cWhite25 = vec4(1,1,1,.25);
const vec4 cWhite15 = vec4(1,1,1,.15);
const vec4 cNone = vec4(0, 0, 0, 0);
const vec4 cLightYellow = vec4(1, 1, 0.5, 1);
const vec4 cSkyBlue = vec4(0.33, 0.66, 0.98, 1);
const vec4 cLimeGreen = vec4(0.2, 0.8, 0.2, 1);
const vec4 cGold = vec4(1, 0.84, 0, 1);
const vec4 cGoldLight = vec4(1, 0.9, 0.25, 1);
const vec4 cSilver = vec4(0.75, 0.75, 0.75, 1);
const vec4 cBronze = vec4(0.797f, 0.479f, 0.225f, 1.000f);
const vec4 cPaleBlue35 = vec4(0.68, 0.85, 0.90, .35);
const vec4 cTwitch = vec4(0.57f, 0.27f, 1.f, 1.f);



// this does not seem to be expensive
const float nTextStrokeCopies = 12;

vec2 DrawTextWithStroke(const vec2 &in pos, const string &in text, vec4 textColor = vec4(1), float strokeWidth = 2., vec4 strokeColor = cBlack75) {
    nvg::FontBlur(1.0);
    if (strokeWidth > 0.1) {
        nvg::FillColor(strokeColor);
        for (float i = 0; i < nTextStrokeCopies; i++) {
            float angle = TAU * float(i) / nTextStrokeCopies;
            vec2 offs = vec2(Math::Sin(angle), Math::Cos(angle)) * strokeWidth;
            nvg::Text(pos + offs, text);
        }
    }
    nvg::FontBlur(0.0);
    nvg::FillColor(textColor);
    nvg::Text(pos, text);
    // don't return with +strokeWidth b/c it means we can't turn stroke on/off without causing readjustments in the UI
    return nvg::TextBounds(text);
}

vec2 DrawTextWithShadow(const vec2 &in pos, const string &in text, vec4 textColor = vec4(1), float strokeWidth = 2., vec4 strokeColor = vec4(0, 0, 0, 1)) {
    nvg::FontBlur(1.0);
    if (strokeWidth > 0.0) {
        nvg::FillColor(strokeColor);
        float i = 1;
        float angle = TAU * float(i) / nTextStrokeCopies;
        vec2 offs = vec2(Math::Sin(angle), Math::Cos(angle)) * strokeWidth;
        nvg::Text(pos + offs, text);
    }
    nvg::FontBlur(0.0);
    nvg::FillColor(textColor);
    nvg::Text(pos, text);
    // don't return with +strokeWidth b/c it means we can't turn stroke on/off without causing readjustments in the UI
    return nvg::TextBounds(text);
}

vec2 DrawText(const vec2 &in pos, const string &in text, vec4 textColor = vec4(1)) {
    nvg::FontBlur(0.0);
    nvg::FillColor(textColor);
    nvg::Text(pos, text);
    // don't return with +strokeWidth b/c it means we can't turn stroke on/off without causing readjustments in the UI
    return nvg::TextBounds(text);
}
