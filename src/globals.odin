package lvo
import la "core:math/linalg"

// window stuff
WIDTH :: 1280
HEIGHT :: 720
TITLE :: "LOE | Alpha v0.0.1"

// player stuff
HIT_RANGE :: 3
FOV :: 90.0
SENSITIVITY :: 0.002
WALKING_SPEED :: 4.317
SPRINTING_SPEED :: 7.0
HOLDING: i32 = 9

// input stuff
CAMERA_TEMP_INPUT: la.Vector3f32 = {0.0, 0.0, 0.0}
CAMERA_TEMP_SPEED: f32 = WALKING_SPEED
CURSOR_CAPTURED := false
MBL_PRESS := false
MBR_PRESS := false
MBM_PRESS := false

// world stuff
LVO_WORLD: ^LVO_World
WORLD_SIZE :: 256 // in blocks

// chunk stuff
CHUNK_WIDTH :: 16
CHUNK_HEIGHT :: 64
CHUNK_LENGTH :: 16

// subchunk stuff
SUBCHUNK_WIDTH :: 4
SUBCHUNK_HEIGHT :: 4
SUBCHUNK_LENGTH :: 4

// logging stuff
LVO_LOG_FILE: string
