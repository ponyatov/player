import std.stdio;
import std.range;
import std.algorithm;
import std.string;

import sdl;
import sdl_mixer;

import ffmpeg;

class MediaFile {

    string filename;

    AVFormatContext* pFormatCtx = null; /// media format struc

    uint nb_streams = 0; /// number of media streams
    AVStream** streams = null; /// streams raw (pointered) array
    AVStream* stream0 = null; /// default: first AV stream

    AVCodecContext* codec_context = null;
    AVCodec* codec = null;

    this(string filename) {
        this.filename = filename;
    }

    void play() {
    }

    void ffplay(AVMediaType mtype) {
        writeln();
        writeln(this);
        // format
        assert(avformat_open_input(&pFormatCtx,
                filename.toStringz, null, null) == 0);
        assert(avformat_find_stream_info(pFormatCtx, null) >= 0);
        av_dump_format(pFormatCtx, 0, filename.toStringz, 0);
        // stream[0]
        streams = pFormatCtx.streams;
        nb_streams = pFormatCtx.nb_streams;
        stream0 = (streams[0 .. nb_streams].find!"a.codec.codec_type==b"(
                mtype)).takeOne[0];
        writefln("stream[0]: %s", *stream0);
        // codec
        codec_context = stream0.codec;
        assert(codec_context !is null);
        codec = avcodec_find_decoder(codec_context.codec_id);
        assert(codec !is null);
        writefln("codec: %s", codec.id);
        assert(avcodec_open2(codec_context, codec, null) >= 0);
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
        super.ffplay(AVMediaType.AVMEDIA_TYPE_AUDIO);
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

    override void play() {
        super.ffplay(AVMediaType.AVMEDIA_TYPE_VIDEO);
        win.yuvoverlay(codec_context.width, codec_context.height);
    }
}

enum LCDpanel {
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

class Window {
    SDL_Window* win = null;
    SDL_Renderer* render = null;
    SDL_RendererInfo renderinfo;
    SDL_Texture* yuv = null; /// YUV texture for video play

    this(string title) {
        win = SDL_CreateWindow(title.toStringz, SDL_WINDOWPOS_UNDEFINED,
                SDL_WINDOWPOS_UNDEFINED, LCDpanel.W,
                LCDpanel.H, SDL_WINDOW_SHOWN);
        assert(win);
        render = SDL_CreateRenderer(win, -1, 0);
        assert(render !is null);
        SDL_GetRendererInfo(render, &renderinfo);
        writefln("\nrender:%s flags:%s %sx%s",
                renderinfo.name.fromStringz, renderinfo.flags,
                renderinfo.max_texture_width, renderinfo.max_texture_height);
        // foreach (i; 0 .. renderinfo.num_texture_formats) 
        //     writefln("texture: %s", cast(const char*)(renderinfo.texture_formats[i]).fromStringz);

    }

    void yuvoverlay(uint w, uint h) {
        yuv = SDL_CreateTexture(render, SDL_PIXELFORMAT_YV12,
                SDL_TEXTUREACCESS_STATIC, w, h);
        assert(yuv !is null);
    }
}

Window win;

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
    win = new Window(args[0]);
    assert(win !is null);
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
