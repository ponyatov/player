module window;

import config;

import std.stdio;
import std.string;

import sdl;
import sdl_mixer;

class Window {
    SDL_Window* win = null;
    SDL_Renderer* render = null;
    SDL_RendererInfo renderinfo;
    SDL_Texture* yuv = null; /// YUV texture for video play

    SDL_Rect fs; /// full-screen area rect

    this(string title) {
        win = SDL_CreateWindow(title.toStringz, SDL_WINDOWPOS_UNDEFINED,
                SDL_WINDOWPOS_UNDEFINED, LCDpanel.W,
                LCDpanel.H, SDL_WINDOW_SHOWN);
        assert(win);
        render = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED);
        assert(render !is null);
        SDL_GetRendererInfo(render, &renderinfo);
        writefln("\nrender:%s flags:%s %sx%s",
                renderinfo.name.fromStringz, renderinfo.flags,
                renderinfo.max_texture_width, renderinfo.max_texture_height);
        // foreach (i; 0 .. renderinfo.num_texture_formats) 
        //     writefln("texture: %s", cast(const char*)(renderinfo.texture_formats[i]).fromStringz);
        fs.x = fs.y = 0;
        fs.w = LCDpanel.W;
        fs.h = LCDpanel.H;
    }

    ~this() {
        SDL_DestroyTexture(yuv);
        SDL_DestroyRenderer(render);
        SDL_DestroyWindow(win);
        SDL_Quit();
    }

    void yuvinit(uint w, uint h) {
        yuv = SDL_CreateTexture(render, SDL_PIXELFORMAT_YV12,
                SDL_TEXTUREACCESS_STREAMING, w, h);
        assert(yuv !is null);
        fs.w = w;
        fs.h = h - 100;
    }

    void clear() {
        SDL_SetRenderDrawColor(render, 0x22, 0x22, 0x22, 0);
        SDL_RenderClear(render);
    }

    void blit() {
        clear;
        SDL_RenderCopy(render, yuv, null, &fs);
        SDL_RenderPresent(render);
    }

    bool quit = false; /// loop flag for @ref loop
    SDL_Event event; /// polled SDL event
    bool loop() {
        blit;
        // keys
        SDL_Delay(222);
        SDL_PumpEvents;
        while (SDL_PollEvent(&event)) {
            switch (event.type) {
            case SDL_QUIT:
            case SDL_KEYDOWN:
            case SDL_MOUSEBUTTONDOWN:
                return false;
            default:
            }
        }
        return true;
    }
}

Window win = null;
