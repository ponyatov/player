module mp4;

import config;

import std.stdio;

import ffmpeg;

import mediafile;
import window;

class MP4 : MediaFile {

    this(string filename) {
        super(filename);
    }

    AVFrame* srcframe = null; /// stream source frame
    AVFrame* yuvframe = null; /// current AV frame: output video frames
    AVPacket packet; /// current AV packet: read data from file
    int finished; ///

    ubyte* srcbuffer = null; /// i/o buffer for decoder
    uint srcbuffer_size = 0; /// @ref srcbuffer size in bytes
    ubyte* yuvbuffer = null; /// i/o buffer for SDL YUV output
    uint yuvbuffer_size = 0; /// @ref yuvbuffer size in bytes

    SwsContext* sws_context = null;

    ~this() {
        if (srcbuffer !is null)
            av_free(srcbuffer);
        if (srcframe !is null)
            av_frame_free(&srcframe);
        if (yuvframe !is null)
            av_frame_free(&yuvframe);
        packet.destroy();
        if (sws_context !is null)
            sws_freeContext(sws_context);
    }

    void buffers() {
        // set SDL output buffers with media W/H
        win.yuvinit(codec_context.width, codec_context.height);
        // AV frames
        srcframe = av_frame_alloc();
        assert(srcframe !is null);
        yuvframe = av_frame_alloc();
        assert(yuvframe !is null);
        // i/o buffers
        srcbuffer_size = avpicture_get_size(codec_context.pix_fmt,
                codec_context.width, codec_context.height);
        srcbuffer = cast(ubyte*) av_malloc(srcbuffer_size);
        assert(srcbuffer !is null);
        // 
        yuvbuffer_size = avpicture_get_size(AVPixelFormat.AV_PIX_FMT_YUV420P,
                LCDpanel.W, LCDpanel.H);
        yuvbuffer = cast(ubyte*) av_malloc(yuvbuffer_size);
        assert(yuvbuffer !is null);
        // bind raw buffers to frames
        avpicture_fill(cast(AVPicture*) srcframe, srcbuffer,
                codec_context.pix_fmt, codec_context.width,
                codec_context.height);
        avpicture_fill(cast(AVPicture*) yuvframe, yuvbuffer,
                AVPixelFormat.AV_PIX_FMT_YUV420P, LCDpanel.W, LCDpanel.H);
    }

    void scaler() {
        // sws_context = sws_getCachedContext(null, codec_context.width,
        //         codec_context.height, codec_context.pix_fmt,
        //         LCDpanel.W, LCDpanel.H,
        //         AVPixelFormat.AV_PIX_FMT_YUV420P, SWS_BICUBIC, null, null, null);
        // assert(sws_context !is null);
    }

    override void play() {
        super.ffplay(AVMediaType.AVMEDIA_TYPE_VIDEO);
        buffers;
        scaler;
        //
        // https://habr.com/ru/articles/137793/
        // 

        // av_init_packet(&packet);
        // finished = 0;
        // // while (!finished)
        // avcodec_decode_video2(codec_context, &frame, &finished, &packet);
        // writefln("\nframe finished:%s", finished);
    }
}
