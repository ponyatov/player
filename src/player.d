import std.stdio;
import std.range;
import std.algorithm;
import std.string;

import sdl;
import sdl_mixer;

class MediaFile {
    string filename;
    this(string filename) {
        this.filename = filename;
    }

    void play() {
        writeln(filename);
    }
}

MediaFile[] playlist;

class MP3 : MediaFile {
    this(string filename) {
        super(filename);
    }

    Mix_Music* music;
    override void play() {
        super.play;
        music = Mix_LoadMUS(filename.toStringz);
        assert(music !is null);
        Mix_PlayMusic(music, 1);
    }
}

enum Video {
    W = 240,
    H = 320
}

enum Audio {
    freq = 22_050,
    format = AUDIO_S8,
    channels = 1
}

void main(string[] args) {
    foreach (argc, argv; args.enumerate) {
        writefln("argv[%d] = <%s>", argc, argv);
        if (argv.endsWith(".mp3"))
            playlist ~= new MP3(argv);
    }
    // 
    assert(SDL_Init(SDL_INIT_AUDIO | SDL_INIT_VIDEO) == 0);
    scope (exit)
        SDL_Quit();
    const auto mixer_flags = MIX_INIT_MP3;
    assert(mixer_flags == Mix_Init(mixer_flags));
    assert(Mix_OpenAudio(Audio.freq, Audio.format, Audio.channels, 0) == 0);
    // 
    auto wmain = SDL_CreateWindow(args[0].toStringz, SDL_WINDOWPOS_UNDEFINED,
            SDL_WINDOWPOS_UNDEFINED, Video.W, Video.H, SDL_WINDOW_SHOWN);
    assert(wmain);
    // 
    playlist[0].play();
    // 
    bool quit = false;
    SDL_Event event;
    while (!quit) {
        SDL_Delay(222);
        SDL_PumpEvents;
        while (SDL_PollEvent(&event)) {
            switch (event.type) {
            case SDL_QUIT:
            case SDL_KEYDOWN:
            case SDL_MOUSEBUTTONDOWN:
                quit = true;
                break;
            default:
            }
        }
    }
}
