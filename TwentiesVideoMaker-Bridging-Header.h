//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import "RecorderViewController.h"
#import "AudioExporter.h"
#import "ExporterController.h"

#include "FilteringVideo.h"

#import "AlphaViewController.h"

#import "SDAVAssetExportSession.h"

#include <libavformat/avformat.h>
#include <libavfilter/avfilter.h>
#include <libavfilter/buffersink.h>
#include <libavfilter/buffersrc.h>
#include <libavutil/samplefmt.h>
#include <libavutil/opt.h>
#include <libavutil/channel_layout.h>

static int open_input_file(const char *filename);
static int init_filters(const char *filters_descr);
static void display_frame(const AVFrame *frame, AVRational time_base);
static void apply_filters(const char *filename);
