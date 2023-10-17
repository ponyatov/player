import std.stdio;
import std.range;

import sdl;

void main(string[] args) {
    foreach (argc, argv; args.enumerate)
        writefln("argv[%d] = <%s>", argc, argv);
        // 
        writeln(SDL_Init(SDL_INIT_AUDIO|SDL_INIT_VIDEO));
        SDL_Quit();
}
