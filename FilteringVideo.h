//
//  FilteringVideo.h
//  TwentiesVideoMaker
//
//  Created by Patrick Aubin on 10/18/17.
//  Copyright © 2017 Patrick Aubin. All rights reserved.
//

#define _XOPEN_SOURCE 600 /* for usleep */
#include <unistd.h>

#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavfilter/avfiltergraph.h>
#include <libavfilter/avcodec.h>
#include <libavfilter/buffersink.h>
#include <libavfilter/buffersrc.h>
#include <libavutil/opt.h>


static int open_input_file(const char *filename);
static int init_filters(const char *filters_descr);
static void display_frame(const AVFrame *frame, AVRational time_base);
static void apply_filters(const char *filename);

