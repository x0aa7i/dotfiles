// the cursor itself glides between cells instead of jumping.
// Unlike a trail shader, this one is the focused cursor, so it
// requires ghostty's own cursor to be hidden:
//
//     cursor-opacity = 0
//     custom-shader  = "./shaders/cursor_glide.glsl"

// --- CONFIGURATION ---
const float DURATION       = 0.08;  // seconds for one glide
const float AA             = 1.0;   // edge antialiasing in pixels
const float MAX_DISTANCE_X = 40.0;  // max horizontal distance (in cells) to glide; snap if exceeded
const float MAX_DISTANCE_Y = 5.0;   // max vertical distance (in lines) to glide; snap if exceeded

// sRGB -> linear: uniforms arrive as sRGB, iChannel0 and the output are linear.
vec3 sRGBToLinear(vec3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

// EaseOutCubic — swap for any of the curves in cursor_sweep.glsl.
float ease(float x) {
    return 1.0 - pow(1.0 - x, 3.0);
}

float sdfRect(vec2 p, vec2 center, vec2 halfSize) {
    vec2 d = abs(p - center) - halfSize;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// iCurrentCursor/iPreviousCursor are (left, top-edge, width, height) in
// pixels with shadertoy's y-up convention: the rect spans [y - h, y].
vec2 rectCenter(vec4 r) {
    return vec2(r.x + r.z * 0.5, r.y - r.w * 0.5);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 tex = texture(iChannel0, fragCoord / iResolution.xy);
    fragColor = tex;

    // Immediately stop rendering when cursor is hidden (e.g. yazi, lazygit, TUI tools)
    if (iCursorVisible == 0) return;

    vec4 cur  = iCurrentCursor;
    vec4 prev = iPreviousCursor;

    // Exit if cursor is hidden or zero-sized
    if (cur.z <= 0.0 || cur.w <= 0.0) return;

    // An all-zero previous cursor is the first frame after launch; don't
    // glide in from the window corner.
    if (dot(prev.zw, prev.zw) == 0.0) prev = cur;

    // Snap immediately if the jump is too large (e.g. switching tabs,
    // switching splits, clearing screen, or jumping across files).
    vec2 cellDelta = abs(rectCenter(cur) - rectCenter(prev)) / cur.zw;
    if (cellDelta.x > MAX_DISTANCE_X || cellDelta.y > MAX_DISTANCE_Y) prev = cur;

    float t = clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.0);
    float e = ease(t);

    vec2 center   = mix(rectCenter(prev), rectCenter(cur), e);
    vec2 halfSize = mix(prev.zw, cur.zw, e) * 0.5;
    vec3 rgb      = sRGBToLinear(mix(iPreviousCursorColor.rgb, iCurrentCursorColor.rgb, e));
    vec4 cursor   = vec4(rgb, 1.0);

    float coverage = 1.0 - smoothstep(0.0, AA, sdfRect(fragCoord, center, halfSize));
    if (coverage <= 0.0) return;

    // Difference blend: inverts text under the block cursor without requiring alpha transparency
    vec3 cursorPixel = abs(cursor.rgb - tex.rgb);

    fragColor = mix(tex, vec4(cursorPixel, 1.0), coverage);
}
