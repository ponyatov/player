module mp3;

import sdl_mixer;
import ffmpeg;

import mediafile;

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
