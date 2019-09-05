//
//  QYReocrder.m
//  ARRecorder
//
//  Created by Yuri Boyka on 2019/9/3.
//  Copyright © 2019 Yuri Boyka. All rights reserved.
//

#import "QYReocrder.h"
#import "Rendering/QYARRender.h"
@interface QYReocrder()
@property(nonatomic,strong)CADisplayLink * displayLink;
@property(nonatomic,strong)SCNRenderer * renderEngine;
@property(nonatomic,strong)QYARRender * render;
@end
@implementation QYReocrder
- (instancetype)initWithARSKView:(ARSCNView *)arView
{
    self = [super init];
    if(self)
    {
        _weakScnView  = arView;
        [self initParams];
        [self initEnvironment];
    }
    return self;
}

- (void)initEnvironment
{
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    NSAssert(device, @"该设备不支持 Metal");
    self.renderEngine = [SCNRenderer rendererWithDevice:device options:nil];
    self.renderEngine.scene = self.weakScnView.scene;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(renderFrame)];
    self.displayLink.preferredFramesPerSecond = self.fps;
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    self.status = readyToRecord;
    self.onlyRenderWhileRec = self.onlyRenderWhileRecording;
    self.render = [[QYARRender alloc] initWithARView:self.weakScnView renderer:self.renderEngine contentMode:self.contentMode];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
    
}
- (void)renderFrame
{
    if(self.onlyRenderWhileRec && !self.isRecording)
    {
        return;
    }
    CVPixelBufferRef buffer = self.render.buffer;
    if(buffer == nil)
    {
        [WriteAR message:@"buffer is nil"];
        return;
    }
    CVPixelBufferRef rawBuffer = self.render.rawBuffer;
    if(rawBuffer == nil)
    {
        [WriteAR message:@"rawBuffer is nil"];
        CVPixelBufferRelease(buffer);
        return;
    }
    CGSize size = self.render.bufferSize;
    if(CGSizeEqualToSize(size, CGSizeZero))
    {
        [WriteAR message:@"bufferSize is zero"];
        CVPixelBufferRelease(buffer);
//        CVPixelBufferRelease(rawBuffer);
        return;
    }
    
    self.render.content = self.contentMode;
    dispatch_sync(self.writerQueue, ^{
       
        CMTime time = CMTimeMakeWithSeconds(self.render.time, 1000000);
        if(self.renderARDelegate && [self.renderARDelegate respondsToSelector:@selector(frameDidRender:time:rawBuffer:)])
        {
            [self.renderARDelegate frameDidRender:buffer time:time rawBuffer:rawBuffer];
        }
        NSLog(@"当前 录制状态");
        if(self.isRecording)
        {
            if(self.wirtter)
            {
                CMTime finalFrameTime;
                if(self.backFromPause)
                {
                    if(CMTimeCompare(self.resumeFrameTime, kCMTimeZero) == 0)
                    {
                        self.resumeFrameTime = time;
                    }
                    //计算规则 (currentTime - (timeWhenResume - timeWhenPaused))
                    finalFrameTime = [self adjustTime:time resumeTime:self.resumeFrameTime pauseTime:self.pausedFrameTime];
                    
                }
                else
                {
                    finalFrameTime = time;
                }
                NSLog(@"当前时间 = %f resumeFrameTime = %f pausedFrameTime = %f",CMTimeGetSeconds(finalFrameTime),CMTimeGetSeconds(self.resumeFrameTime),CMTimeGetSeconds(self.resumeFrameTime));
                [self.wirtter insert:buffer time:finalFrameTime];
            
                if(!self.wirtter.isWritingWithoutError)
                {
                    self.isRecording = NO;
                    self.status = readyToRecord;
                    if(self.delegate && [self.delegate respondsToSelector:@selector(didFailRecording:status:)])
                    {
                        [self.delegate didFailRecording:[NSError errorWithDomain:@"写入视频帧失败" code:errSecDecode userInfo:@{@"errorInfo":@"An error occured while recording your video."}] status:@"An error occured while recording your video."];
                    }
                    if(self.delegate && [self.delegate respondsToSelector:@selector(didEndRecording:noError:)])
                    {
                        [self.delegate didEndRecording:self.currentVideoPath noError:NO];
                    }
                }
            }
            else
            {
                self.currentVideoPath = self.videoPath;
                self.wirtter = [[WriteAR alloc] initWithOutput:self.currentVideoPath
                                                          size:size
                                              adjustForSharing:self.adjustVideoForSharing
                                                  audioEnabled:self.enableAudio
                                                   orientaions:@[]
                                                         queue:self.writerQueue
                                                      allowMix:self.enableMixWithOthers];
                self.wirtter.videoInputOrientation = self.videoOrientation;
                self.wirtter.delegate = self.delegate;
            }
        } else if(!self.isRecording && self.adjustPausedTime)
        {
            [self.wirtter pause];
            self.adjustPausedTime = NO;
            if(CMTimeCompare(self.pausedFrameTime, kCMTimeZero) != 0 && CMTimeCompare(self.resumeFrameTime, kCMTimeZero) != 0)
            {
                self.pausedFrameTime = [self adjustTime:time resumeTime:self.resumeFrameTime pauseTime:self.pausedFrameTime];
                
                NSLog(@"pause resumeFrameTime = %f pausedFrameTime = %f",CMTimeGetSeconds(self.resumeFrameTime),CMTimeGetSeconds(self.resumeFrameTime));
            }
            else
            {
                self.pausedFrameTime = time;
            }
            self.backFromPause = YES;
            self.resumeFrameTime = kCMTimeZero;
            self.status = paused;
            self.onlyRenderWhileRec = self.onlyRenderWhileRecording;
        }

        CVPixelBufferRelease(buffer);
//        CVPixelBufferRelease(rawBuffer);
    });
    
}
- (void)initParams
{
    self.status = unkown;
    self.micStatus = unknown;
    self.enableAudio = YES;
    self.fps = autofps;
    self.videoOrientation = autoOrientation;
    self.contentMode = autoAdjust;
    self.onlyRenderWhileRecording = YES;
    self.enableMixWithOthers = YES;
    self.adjustVideoForSharing = YES;
    self.deleteCacheWhenExported = YES;
    self.writerQueue = dispatch_queue_create("com.qyARRecord.writeQueue", DISPATCH_QUEUE_SERIAL);
//    self.gifWriterQueue = dispatch_queue_create("com.qyARRecord.writeQueue", DISPATCH_QUEUE_SERIAL);
    self.audioSessionQueue = dispatch_queue_create("com.qyARRecord.audioSessionQueue", DISPATCH_QUEUE_CONCURRENT);
    self.isRecording = NO;
    self.adjustPausedTime = NO;
    self.backFromPause = NO;
    self.recordingWithLimit = NO;
    self.onlyRenderWhileRec = YES;
    self.resumeFrameTime = kCMTimeZero;
    self.pausedFrameTime = kCMTimeZero;
   
    
    
}
- (void)requestMicrophonePerMission:(void(^)(BOOL status))finished
{
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if(finished)
        {
            finished(granted);
        }
        if(granted)
        {
            self.micStatus = enabled;
        }
        else
        {
            self.micStatus = disabled;
        }
    }];
}

- (void)startRecord
{
    dispatch_sync(self.writerQueue, ^{
       
        if(self.enableAudio && self.micStatus == unknown)
        {
            [self requestMicrophonePerMission:^(BOOL status) {
               if(!status)
               {
                   NSLog(@"拒绝了 麦克风权限");
               }
                self.isRecording = YES;
                self.status = recording;
            }];
        }
        else
        {
            self.isRecording = YES;
            self.status = recording;
        }
    });
}
- (void)startRecord:(NSTimeInterval)time finished:(void(^)(NSURL * vidoePath))finished
{
    dispatch_sync(self.writerQueue, ^{
       
        if(self.enableAudio && self.micStatus == unknown)
        {
            [self requestMicrophonePerMission:^(BOOL status) {
                if(!status)
                {
                    NSLog(@"拒绝了 麦克风权限");
                }
                self.isRecording = YES;
                self.status = recording;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self stop:^(NSURL *vidoePath) {
                       if(finished)
                       {
                           finished(vidoePath);
                       }
                    }];
                });
            }];
        }
        else
        {
            self.recordingWithLimit = true;
            self.isRecording = true;
            self.status = recording;
            [self stop:^(NSURL *vidoePath) {
                if(finished)
                {
                    finished(vidoePath);
                }
            }];
        }
    });
}
- (void)pause
{
    if(!self.recordingWithLimit)
    {
        self.onlyRenderWhileRec = NO;
        self.isRecording = NO;
        self.adjustPausedTime = YES;
    }
    else
    {
        NSLog(@"NOT PERMITTED: The [ pause() ] method CAN NOT be used while using [ record(forDuration duration: TimeInterval) ]");
    }
}
- (void)stop:(void(^)(NSURL * vidoePath))finished
{
    dispatch_sync(self.writerQueue, ^{
       
        self.isRecording = NO;
        self.adjustPausedTime = NO;
        self.backFromPause = NO;
        self.recordingWithLimit = NO;
        
        self.pausedFrameTime = kCMTimeZero;
        self.resumeFrameTime = kCMTimeZero;
        dispatch_async(dispatch_get_main_queue(), ^{
           
            [self.wirtter end:^{
                NSLog(@"视频录制结束");
                if(self.currentVideoPath){
                    if(finished){
                        finished(self.currentVideoPath);
                    }
                    if(self.delegate && [self.delegate respondsToSelector:@selector(didEndRecording:noError:)])
                    {
                        [self.delegate didEndRecording:self.currentVideoPath noError:YES];
                    }
                }
                self.wirtter = nil;
            }];
        });
    });
}
- (void)cancel
{
    dispatch_sync(self.writerQueue, ^{
       
        self.isRecording = NO;
        self.adjustPausedTime = NO;
        self.backFromPause = NO;
        self.recordingWithLimit = NO;
        self.pausedFrameTime = kCMTimeZero;
        self.resumeFrameTime = kCMTimeZero;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.wirtter cancel];
            if(self.currentVideoPath)
            {
                [WriteAR removeFromePath:self.currentVideoPath];
                if(self.delegate && [self.delegate respondsToSelector:@selector(didCancelReocording:)])
                {
                    [self.delegate didCancelReocording:@"正常取消录制视频"];
                }
                self.status = readyToRecord;
            }
            else
            {
                self.status = readyToRecord;
                if(self.delegate && [self.delegate respondsToSelector:@selector(didCancelReocording:)])
                {
                    [self.delegate didCancelReocording:@"异常取消录制视频"];
                }
            }
            self.wirtter = nil;
        });
        
    });
}
#pragma mark- Setter /Getter
- (void)setRequestMicPermission:(RecordARMicrophonePermission)requestMicPermission
{
    _requestMicPermission = requestMicPermission;
    switch(_requestMicPermission)
    {
        case autoPermission:{
            if(self.enableAudio)
            {
                [self requestMicrophonePerMission:nil];
            }
        }break;
        case manual:{}break;
    }
}
- (void)setOnlyRenderWhileRecording:(BOOL)onlyRenderWhileRecording
{
    _onlyRenderWhileRecording = onlyRenderWhileRecording;
    _onlyRenderWhileRec = _onlyRenderWhileRecording;
}
- (void)setEnableAudio:(BOOL)enableAudio
{
    _enableAudio = enableAudio;
    self.requestMicPermission = (self.requestMicPermission == manual)? manual:autoPermission;
}
- (void)setEnableAdjustEnvironmentLighting:(BOOL)enableAdjustEnvironmentLighting
{
    _enableAdjustEnvironmentLighting = enableAdjustEnvironmentLighting;
    if(self.renderEngine)
    {
        self.renderEngine.autoenablesDefaultLighting = _enableAdjustEnvironmentLighting;
    }
}
- (NSURL *)videoPath
{
    NSString * path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateIntervalFormatterFullStyle;
    formatter.timeStyle = NSDateIntervalFormatterFullStyle;
    formatter.dateFormat = @"yyyy-MM-dd'@'HH-mm-ssZZZZ";
    NSDate *date = [NSDate date];
    path = [NSString stringWithFormat:@"%@/%@ARVideo.mp4",path,[formatter stringFromDate:date]];
    _videoPath = [NSURL fileURLWithPath:path];
    return _videoPath;
}

#pragma mark - Dealloc
- (void)dealloc
{
    [self.displayLink invalidate];
    self.displayLink = nil;
}
#pragma mark - noti
- (void)appWillEnterBackground
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(willEnterBackground:)])
    {
        [self.delegate willEnterBackground:self.status];
    }
}
#pragma mark - extension
- (CMTime) adjustTime:(CMTime)currentTime resumeTime:(CMTime)resume pauseTime:(CMTime)pause
{
    return CMTimeSubtract(currentTime, CMTimeSubtract(resume, pause));
}
//- (void)prepare:(ARConfiguration *)config
//{
//    self.ARcontentMode = self.contentMode;
//    self.onlyRenderWhileRec = self.onlyRenderWhileRecording;
//    if(self.weakScnView)
//    {
//        [[UIDevice currentDevice] setValue:UIInterfaceOrientationPortrait forKey:@"orientation"];
//        self.weakScnView.
//    }
//}
@end
