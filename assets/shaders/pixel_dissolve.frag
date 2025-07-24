#include <flutter/runtime_effect.glsl>

// The final color output for the current pixel
out vec4 fragColor;

// --- Uniforms (inputs from Flutter) ---
// The sampler2D type is used for image textures
uniform sampler2D uImage;
// A float for the animation progress, driven by the AnimationController (0.0 to 1.0)
uniform float uProgress;
// A 2D vector for the widget's resolution (width, height)
uniform vec2 uResolution;
// A float to control the size of the pixelation grid
uniform float uGridSize;


// --- Helper Functions ---
// A simple pseudo-random number generator.
// It produces a deterministic, repeatable "random" value between 0.0 and 1.0
// for a given 2D input vector 'p'.
float rand(vec2 p) {
    // The specific numbers are arbitrary "magic numbers" chosen to produce good visual noise.
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}


// --- Main Shader Program ---
// This function is executed by the GPU for every single pixel being rendered.
void main() {
    // Get the current pixel's coordinate and normalize it to a 0.0-1.0 range.
    // This is essential for correctly mapping the image texture.
    vec2 uv = FlutterFragCoord().xy / uResolution;

    // Quantize the UV coordinates to create a grid. All pixels within the same
    // grid cell will have the same 'grid_uv' value.
    vec2 grid_uv = floor(uv * uGridSize) / uGridSize;

    // Generate a single random value for the entire grid cell.
    float randomVal = rand(grid_uv);

    // --- Dissolve Logic ---
    // Compare the cell's random value with the animation progress.
    // If the random value is greater, the pixel is not rendered.
    // As 'uProgress' animates from 0.0 to 1.0, more pixels pass this check and become visible.
    // This works seamlessly in reverse as well.
    if (randomVal > uProgress) {
        discard; // Halts execution for this pixel, making it transparent.
    }

    // --- Controlled Movement Logic ---
    // Generate a random, normalized 2D direction vector for the grid cell.
    // We use slightly different inputs to rand() to get different random numbers for x and y.
    vec2 offsetDir = vec2(rand(grid_uv + 0.1) - 0.5, rand(grid_uv - 0.1) - 0.5) * 2.0;

    // Calculate the magnitude of the offset.
    // It's strongest when progress is 0.0 (fully disintegrated) and zero when progress is 1.0 (fully consolidated).
    // The 0.2 is an arbitrary strength factor; this could be exposed as another uniform for customization.
    float offsetMagnitude = (1.0 - uProgress) * 0.2;

    // Apply the final offset to the original, non-quantized UV coordinate.
    // This ensures the internal texture remains smooth while the particles move in blocks.
    vec2 final_uv = uv + offsetDir * offsetMagnitude;

    // --- Final Color Calculation ---
    // Sample the source image texture at the final, potentially offset, coordinate.
    fragColor = texture(uImage, final_uv);

    // Apply a fade-in to the particles based on the overall progress.
    // 'smoothstep' creates a gentle transition at the beginning of the animation.
    // This makes the particles fade in smoothly rather than popping in abruptly.
    fragColor.a *= smoothstep(0.0, 0.1, uProgress);
}