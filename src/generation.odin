package lvo

import la "core:math/linalg"
import "core:math"

generate_lvo_mountains :: proc(seed: i64, x, z, cx, cz: int) -> i32 {
	nx, nz := f64(x) / f64(CHUNK_WIDTH) - 0.5, f64(z) / f64(CHUNK_LENGTH) - 0.5
	return i32(
		math.abs(
			math.floor(
				lvo_octave_noise(seed, {0.1 * (nz + f64(cz)), 0.1 * (nx + f64(cx))}, 5) *
				(CHUNK_HEIGHT - 1),
			),
		),
	)
}
