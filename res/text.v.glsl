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

// hardcoding this because the main program is a nightmare
// change it based on how tall you screen, or face dire consequences
int maxlines = 60;

void main()
{
    vec2 projectionOffset = projection.xy;
    vec2 projectionScale = projection.zw;

    // Compute vertex corner position
    vec2 position;
    position.x = (gl_VertexID == 0 || gl_VertexID == 1) ? 1. : 0.;
    position.y = (gl_VertexID == 0 || gl_VertexID == 3) ? 0. : 1.;

    // Position of cell from top-left
    vec2 cellPosition = cellDim * gridCoords;

    // back on my bullshit
    // flop
    cellPosition.y = cellDim.y * maxlines - cellPosition.y;
    // tasteful fade-out
    float fadeScale = (maxlines - gridCoords.y) / maxlines;
    cellPosition.x *= fadeScale;
    projectionOffset.x += (1 - fadeScale);

    if (backgroundPass != 0) {
        vec2 finalPosition = cellPosition + cellDim * position;
        gl_Position = vec4(projectionOffset + projectionScale * finalPosition, 0.0, 1.0);

        TexCoords = vec2(0, 0);
    } else {
        vec2 glyphSize = glyph.zw * fadeScale;
        vec2 glyphOffset = glyph.xy;
        glyphOffset.y = cellDim.y - glyphOffset.y;

        vec2 finalPosition = cellPosition + glyphSize * position + glyphOffset;
        gl_Position = vec4(projectionOffset + projectionScale * finalPosition, 0.0, 1.0);

        vec2 uvOffset = uv.xy;
        vec2 uvSize = uv.zw;
        TexCoords = uvOffset + position * uvSize;
    }
    // rotation of uv coordinates?? (this does not work)
    // float angle = 4 * 3.14159 * gridCoords.y / maxlines;
    // float sin_value = sin(angle);
    // float cos_value = cos(angle);
    // TexCoords = TexCoords * mat2(cos_value, sin_value, -sin_value, cos_value);
    bg = vec4(backgroundColor.rgb / 255.0, backgroundColor.a);
    fg = textColor / vec3(255.0, 255.0, 255.0);
    colored = coloredGlyph;
}
