// Copyright 2016 Joe Wilm, The Alacritty Project Contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
#version 330 core
// Cell properties.
layout (location = 0) in vec2 gridCoords;

// Glyph properties.
layout (location = 1) in vec4 glyph;

// uv mapping.
layout (location = 2) in vec4 uv;

// Text fg color.
layout (location = 3) in vec3 textColor;

// Background color.
layout (location = 4) in vec4 backgroundColor;

// Set to 1 if the glyph colors should be kept.
layout (location = 5) in int coloredGlyph;

out vec2 TexCoords;
flat out vec3 fg;
flat out vec4 bg;
flat out int colored;

// Terminal properties
uniform vec2 cellDim;
uniform vec4 projection;
uniform int backgroundPass;
uniform float time;

// hardcoding this because the main program is a nightmare.
// change it based on how tall you screen, or face dire consequences
int maxlines = 60;

vec3 rgb2hsv(vec3 rgb) {
    float Cmax = max(rgb.r, max(rgb.g, rgb.b));
    float Cmin = min(rgb.r, min(rgb.g, rgb.b));
    float delta = Cmax - Cmin;

    vec3 hsv = vec3(0., 0., Cmax);

    if (Cmax > Cmin) {
        hsv.y = delta / Cmax;

        if (rgb.r == Cmax) {
            hsv.x = (rgb.g - rgb.b) / delta;
        }
        else {
            if (rgb.g == Cmax) {
                hsv.x = 2. + (rgb.b - rgb.r) / delta;
            }
            else {
                hsv.x = 4. + (rgb.r - rgb.g) / delta;
            }
        }
        hsv.x = fract(hsv.x / 6.);
    }
    return hsv;
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main() {
    vec2 projectionOffset = projection.xy;
    vec2 projectionScale = projection.zw;

    // Compute vertex corner position
    vec2 position;
    position.x = (gl_VertexID == 0 || gl_VertexID == 1) ? 1. : 0.;
    position.y = (gl_VertexID == 0 || gl_VertexID == 3) ? 0. : 1.;

    // Position of cell from top-left
    vec2 cellPosition = cellDim * gridCoords;

    // fix your back
    // cellPosition.y = cellDim.y * maxlines - cellPosition.y;

    // far out, dude
    float fadeScale = (maxlines - gridCoords.y) / maxlines;
    // cellPosition.x *= fadeScale;
    // projectionOffset.x += (1 - fadeScale);

    vec2 finalPosition;
    vec2 glyphSize;
    vec2 glyphOffset;
    if (backgroundPass != 0) {
        finalPosition = cellPosition + cellDim * position;
    } else {
        glyphSize = glyph.zw;
        // glyphSize = glyph.zw * fadeScale;
        // glyphSize = glyph.zw * fadeScale * (1.5 + 0.5 * sin(time + cellPosition.x / 10));
        glyphOffset = glyph.xy;
        glyphOffset.y = cellDim.y - glyphOffset.y;
        finalPosition = cellPosition + glyphSize * position + glyphOffset;
    }

    // wobble
    // finalPosition.x += 0.5 * sin(sin(finalPosition.x) + finalPosition.y * 0.1 * time);
    // finalPosition.y += 0.5 * sin(sin(finalPosition.y) + finalPosition.x * 0.1 * -time);

    // animated wave
    // finalPosition.y += 10 * sin((finalPosition.x + time * 30) * 0.05);

    if (backgroundPass != 0) {
        gl_Position = vec4(projectionOffset + projectionScale * finalPosition, 0.0, 1.0);
        TexCoords = vec2(0, 0);
    } else {
        gl_Position = vec4(projectionOffset + projectionScale * finalPosition, 0.0, 1.0);
        vec2 uvOffset = uv.xy;
        vec2 uvSize = uv.zw;
        TexCoords = uvOffset + position * uvSize;
    }

    // colours
    bg = vec4(backgroundColor.rgb / 255.0, backgroundColor.a);
    fg = textColor / vec3(255.0, 255.0, 255.0);
    colored = coloredGlyph;

    // cool colours
    // float r = sin(time * 0.001);
    // float t = r * r * 400;
    // float x = cellPosition.x;
    // float y = cellPosition.y;
    // float p0 = sin(x * 0.002 + t);
    // float p1 = sin(10*(x*0.0005*sin(t*0.5)+y*0.00005*cos(t*0.3))+t);
    // float cx = x*0.0005 - 0.5 + 0.5 * sin(t*2);
    // float cy = y*0.0005 - 0.5 + 0.5 * cos(t*3.3333);
    // float p2 = sin(sqrt(cx*cx+cy*cy)*3+1);
    // float p = (p0 + p1 + p2);

    // vec3 bgColorHsv = rgb2hsv(backgroundColor.rgb / 255.0);
    // if (bgColorHsv.x < 0.01)
    //   bgColorHsv.y += 0.1;
    // bgColorHsv.x += p * 0.5;
    // vec3 bgColorRgb = hsv2rgb(bgColorHsv);
    // bg = vec4(bgColorRgb.rgb, backgroundColor.a);

    // vec3 textColorHsv = rgb2hsv(textColor / vec3(255.0, 255.0, 255.0));
    // textColorHsv.y += 0.1;
    // textColorHsv.x += p * 0.5;
    // vec3 textColorRgb = hsv2rgb(textColorHsv);
    // fg = textColorRgb;

}
