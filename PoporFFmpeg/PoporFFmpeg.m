//
//  PoporFFmpeg.m
//  PoporFFmpeg
//
//  Created by apple on 2019/2/14.
//  Copyright © 2019 popor. All rights reserved.
//

#import "PoporFFmpeg.h"

#import "ffmpeg.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

static NSString * ThreadCompressName = @"PoporFFmpegVideo";

@implementation PoporFFmpeg

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    if (self = [super init]) {
        // from https://github.com/fanmaoyu0871/VideoCutterDemo
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(threadWillExit:) name:NSThreadWillExitNotification object:nil];
    }
    return self;
}

- (void)compressCmd:(NSString *)cmd finish:(PoporFFmpegFinishBlock)finishBlock {
    self.finishBlock = finishBlock;
    //[NSThread detachNewThreadSelector:@selector(threadCompressCmd:) toTarget:self withObject:cmd];
    NSLog(@"FFMpeg cmd : %@", cmd);
    NSThread * newThread = [[NSThread alloc] initWithTarget:self selector:@selector(threadCompressCmd:) object:cmd];
    //newThread.qualityOfService = NSQualityOfServiceUserInteractive;
    [newThread setThreadPriority:1.0];
    [newThread setName:@"PoporFFmpegVideo"]; //  线程的名字
    [newThread start];
}

- (void)threadCompressCmd:(NSString *)cmd {
    NSArray * cmdArray = [cmd componentsSeparatedByString:@","];
    int argc = (int)cmdArray.count;
    char **arguments = calloc(argc, sizeof(char*));
    if(arguments != NULL) {
        for (int i = 0; i<argc; i++) {
            NSString * oneStr = cmdArray[i];
            arguments[i] = (char*)[oneStr UTF8String];
        }
        int result = ffmpeg_main(argc, arguments);
        NSLog(@"FFMpeg result: %i", result);
        
    }else{
        if (self.finishBlock) {
            self.finishBlock(NO, ThreadCompressName);
        }
    }
}

//ffmpeg命令行线程将要结束时调用
-(void)threadWillExit:(NSNotification *)notification {
    NSThread * newThread = notification.object;
    //NSLog(@"notification: %@", [notification description]);
    if ([newThread.name isEqualToString:ThreadCompressName]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.finishBlock) {
                self.finishBlock(YES, @"FFMpegCmd finish");
            }
        });
    }
}

@end

/*
 此时生成的.a文件不能同时运行在真机和模拟器上，此时我们需要在终端上执行命令行进行合并：lipo -create Debug-iphoneos/libAClone.a Debug-iphonesimulator/libAClone.a -output /Users/zhaochenglin/Desktop/1/LibCLNavigation.a
 到这就大功告成了，
 注意如果大家在使用的过程中遇到 “undefine symbols for architecture i386”这样的，大家只需要将设备选择 iPhone 5的模拟器编译，并将得到的.a文件，再次执行第6步 将和LibCLNavigation.a合并即可。另外我们可以通过lipo -info + xx.a查看其支持的运行编译环境。下面Xcode 是所有设备都支持的编译环境。
 
 作者：诺宇
 链接：https://www.jianshu.com/p/7a72327d19e5
 來源：简书
 简书著作权归作者所有，任何形式的转载都请联系作者获得授权并注明出处。
 
 lipo -create libPoporFFmpeg_simulator.a  libPoporFFmpeg_iphone.a -output libPoporFFmpeg.a
 
 */
