import config;

import std.stdio;
import std.string;
import std.range;
import std.algorithm;

import sdl;
import sdl_mixer;

import ffmpeg;

import mediafile;
import playlist;
import mp3;
import mp4;

// void mk_playlist(string[] args) {
// }

void init_libs() {
    assert(SDL_Init(SDL_INIT_AUDIO | SDL_INIT_VIDEO) == 0);
    const auto mixer_flags = MIX_INIT_MP3;
    assert(mixer_flags == Mix_Init(mixer_flags));
    assert(Mix_OpenAudio(Audio.freq, Audio.format, Audio.channels, 0) == 0);
    av_register_all();
}

import window;

// Window win;

void arg(ulong argc, string argv) {
    writefln("argv[%d] = <%s>", argc, argv);
}

void main(string[] args) {
    arg(0, args[0]);
    foreach (argc, argv; args[1 .. $].enumerate) {
        arg(argc, argv);
        if (argv.endsWith(".mp3"))
            plist ~= new MP3(argv);
        else if (argv.endsWith(".mp4"))
            plist ~= new MP4(argv);
    }
    // 
    init_libs();
    // 
    win = new Window(args[0]);
    assert(win !is null);
    // 
    foreach (file; plist)
        file.play();
    // 
    while (win.loop) {
    }
    win.destroy;
}
