module playlist;

import std.range;

import mediafile;

class PlayList {

    MediaFile[] plist;

    uint current = 0;

    PlayList opAppend(MediaFile file) {
        return this;
    }

    void opOpAssign(string op : "~")(MediaFile rhs) {
        writefln("playlist += %s", rhs);
        plist ~= rhs;
    }

    bool empty() {
        return plist.empty();
    }

    MediaFile front() {
        return plist.front();
    }

    void popFront() {
        plist.popFront();
    }

}

MediaFile[] plist;
