import std.stdio;
import std.range;
import std.algorithm;
import std.string;

import sdl;
import sdl_mixer;

import ffmpeg;

class MediaFile {

    string filename;

    this(string filename) {
        this.filename = filename;
    }

    void play() {
        writeln(this);
    }

    override string toString() const {
        return format("%s(%s)", this.classinfo.name, filename);
    }
}

class PlayList {

    MediaFile[] item;

    uint current = 0;

    PlayList opAppend(MediaFile file) {
        return this;
    }

    void opOpAssign(string op : "~")(MediaFile rhs) {
        writefln("playlist += %s", rhs);
        item ~= rhs;
    }

    bool empty() {
        return item.empty();
    }

    MediaFile front() {
        return item.front();
    }

    void popFront() {
        item.popFront();
    }

}

// PlayList playlist;
MediaFile[] playlist;

class MP3 : MediaFile {
    this(string filename) {
        super(filename);
    }

    Mix_Music* music;
    override void play() {
        super.play;
        // music = Mix_LoadMUS(filename.toStringz);
        // assert(music !is null);
        // Mix_PlayMusic(music, 1);
    }
}

class MP4 : MediaFile {

    this(string filename) {
        super(filename);
    }

    // https://habr.com/ru/articles/137793/    

    AVFormatContext* pFormatCtx = null;
    override void play() {
        super.play();
        assert(avformat_open_input(&pFormatCtx,
                filename.toStringz, null, null) == 0);
        writefln("%s", pFormatCtx.iformat.name.fromStringz);
        assert(avformat_find_stream_info(pFormatCtx, null) >= 0);
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

void mk_playlist(string[] args) {
}

void argw(ulong argc, string argv) {
    writefln("argv[%d] = <%s>", argc, argv);
}

void init_libs() {
    assert(SDL_Init(SDL_INIT_AUDIO | SDL_INIT_VIDEO) == 0);
    const auto mixer_flags = MIX_INIT_MP3;
    assert(mixer_flags == Mix_Init(mixer_flags));
    assert(Mix_OpenAudio(Audio.freq, Audio.format, Audio.channels, 0) == 0);
    av_register_all();
}

void main(string[] args) {
    argw(0, args[0]);
    foreach (argc, argv; args[1 .. $].enumerate) {
        argw(argc, argv);
        if (argv.endsWith(".mp3"))
            playlist ~= new MP3(argv);
        else if (argv.endsWith(".mp4"))
            playlist ~= new MP4(argv);
    }
    // 
    init_libs();
    // 
    auto wmain = SDL_CreateWindow(args[0].toStringz, SDL_WINDOWPOS_UNDEFINED,
            SDL_WINDOWPOS_UNDEFINED, Video.W, Video.H, SDL_WINDOW_SHOWN);
    assert(wmain);
    // 
    foreach (file; playlist)
        file.play();
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
    SDL_Quit();
}
