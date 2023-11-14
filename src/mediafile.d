module mediafile;

import std.stdio;
import std.string;
import std.algorithm;
import std.range;

// import sdl;
import ffmpeg;

class MediaFile {

    string filename;

    AVFormatContext* pFormatCtx = null; /// media format struc

    uint nb_streams = 0; /// number of media streams
    AVStream** streams = null; /// streams raw (pointered) array
    AVStream* stream0 = null; /// default: first AV stream

    AVCodecContext* codec_context = null; /// media stream codec ctx
    AVCodecContext* codec_decoder = null; /// codec ctx copy for decoder
    AVCodec* codec = null; /// found decoder

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
        codec_decoder = avcodec_alloc_context3(codec);
        assert(avcodec_copy_context(codec_decoder, codec_context) == 0);
        assert(avcodec_open2(codec_decoder, codec, null) >= 0);
    }

    override string toString() const {
        return format("%s(%s)", this.classinfo.name, filename);
    }
}
