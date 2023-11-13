module mp4;

import config;

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

    SwsContext* sws_context = null;

    override void play() {
        super.ffplay(AVMediaType.AVMEDIA_TYPE_VIDEO);
        win.yuvinit(codec_context.width, codec_context.height);
        // buffers
        srcframe = av_frame_alloc();
        assert(srcframe !is null);
        yuvframe = av_frame_alloc();
        assert(yuvframe !is null);
        // scaler
        sws_context = sws_getCachedContext(null, codec_context.width,
                codec_context.height, codec_context.pix_fmt,
                LCDpanel.W, LCDpanel.H,
                AVPixelFormat.AV_PIX_FMT_YUV420P, SWS_BICUBIC, null, null, null);
        assert(sws_context !is null);
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
