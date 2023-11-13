module config;

import sdl;

enum LCDpanel {
    W = 240,
    H = 320
}

enum Audio {
    freq = 22_050,
    format = AUDIO_S8,
    channels = 1
}
