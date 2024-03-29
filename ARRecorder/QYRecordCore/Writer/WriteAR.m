//
//  WriteAR.m
//  ARRecorder
//
//  Created by Yuri Boyka on 2019/9/4.
//  Copyright © 2019 Yuri Boyka. All rights reserved.
//

#import "WriteAR.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
@interface WriteAR()<AVCaptureAudioDataOutputSampleBufferDelegate>
@property(nonatomic,strong)AVAssetWriter * asserWriter;
@property(nonatomic,strong)AVAssetWriterInput * videoInput;
@property(nonatomic,strong)AVAssetWriterInput * audioInput;

@property(nonatomic,strong)AVAssetWriterInputPixelBufferAdaptor * pixelBufferInput;
@property(nonatomic,strong)NSDictionary<NSString *,id> * videoOutputSettings;
@property(nonatomic,strong)NSDictionary<NSString *,id> * audioSettings;

@property(nonatomic,strong)dispatch_queue_t audioBufferQueue;
@property(nonatomic,assign)BOOL isRecording;
@property(nonatomic,assign)CGSize size;
@property(nonatomic,assign)NSInteger fps;

@end
@implementation WriteAR

- (instancetype)initWithOutput:(NSURL *)output
                          size:(CGSize)size
              adjustForSharing:(BOOL)adjustForSharing
                  audioEnabled:(BOOL)audioEnabled
                   orientaions:(NSArray *)orientaions
                         queue:(dispatch_queue_t)queue
                      allowMix:(BOOL)allowMix
                           fps:(NSInteger)fps
{
    self = [super init];
    if (self) {
        NSAssert(output, @"faluire output is nil");
        NSError * error;
        self.asserWriter = [AVAssetWriter assetWriterWithURL:output fileType:AVFileTypeMPEG4 error:&error];
        NSAssert(!error,@"faluire init AVAssetWriter");
        self.audioBufferQueue = dispatch_queue_create("com.writeAudio.audioBufferQueue",DISPATCH_QUEUE_SERIAL);
        self.videoInputOrientation = autoOrientation;
        if(audioEnabled)
        {
            [self prepareAudioDevice];
        }
        self.size = size;
        self.fps = fps;
//        NSDictionary * attributes = @{
//                                      (__bridge NSString *)kCVPixelBufferCGImageCompatibilityKey :@(YES),
//                                      (__bridge NSString *)kCVPixelBufferCGBitmapContextCompatibilityKey:@(YES)
//                                      };
        self.videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                             outputSettings:self.videoOutputSettings];
        self.videoInput.expectsMediaDataInRealTime = YES;
        
        self.pixelBufferInput = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoInput sourcePixelBufferAttributes:nil];
        
        BOOL angleEnabled = NO;
        for(NSNumber * m in orientaions)
        {
            if([UIDevice currentDevice].orientation == [m integerValue])
            {
                angleEnabled = YES;
                break;
            }
        }
        CGFloat recentAngle = 0.0f,rotationAngle = 0.0f;
        
        switch([UIDevice currentDevice].orientation)
        {
            case UIDeviceOrientationLandscapeLeft:{
                rotationAngle = -90;
                recentAngle = -90;
            }break;
            case UIDeviceOrientationLandscapeRight:{
                rotationAngle = 90;
                recentAngle = 90;
            }break;
                
            case UIDeviceOrientationFaceUp:
            case  UIDeviceOrientationFaceDown:
            case UIDeviceOrientationPortraitUpsideDown:{
                rotationAngle = recentAngle;
            }break;
            default:{
                rotationAngle = 0;
                recentAngle = 0;
            }break;
                
        }
        if(!angleEnabled)
        {
            rotationAngle = 0;
        }
        CGAffineTransform t = CGAffineTransformIdentity;
        switch(self.videoInputOrientation)
        {
            case autoOrientation:{
                t = CGAffineTransformRotate(t, (rotationAngle * M_PI) /180);
            }break;
            case alwaysPortrait:{
                t = CGAffineTransformRotate(t, 0);
            }break;
            case alwaysLandscape:{
                if(rotationAngle == 90 || rotationAngle == -90) {
                    t = CGAffineTransformRotate(t, (rotationAngle * M_PI) /180);
                } else {
                    t = CGAffineTransformRotate(t, (-90 * M_PI) /180);
                }
            }break;
        }
        self.videoInput.transform = t;
        if([self.asserWriter canAddInput:self.videoInput])
        {
            [self.asserWriter addInput:self.videoInput];
        } else {
            if(self.delegate && [self.delegate respondsToSelector:@selector(didFailRecording:status:)])
            {
                [self.delegate didFailRecording:self.asserWriter.error status:@"[self.asserWriter canAddInput:self.videoInput] error"];
            }
            self.isWritingWithoutError = YES;
        }
        self.asserWriter.shouldOptimizeForNetworkUse = adjustForSharing;
    }
    return self;
}

- (void)prepareAudioDevice
{
    self.audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:self.audioSettings];
    self.audioInput.expectsMediaDataInRealTime = YES;
    if([self.asserWriter canAddInput:self.audioInput])
    {
        [self.asserWriter addInput:self.audioInput];
    }
    NSLog(@"音频录制准备完成");
}
- (void)insert:(CVPixelBufferRef) buffer intervals:(CFTimeInterval)intervals
{
    CMTime time = CMTimeMakeWithSeconds(intervals, 1000000);
    [self insert:buffer time:time];
}
- (void)insert:(CVPixelBufferRef)buffer time:(CMTime)time
{
    CVPixelBufferRetain(buffer);
    if(self.asserWriter.status == AVPlayerLooperStatusUnknown)
    {
        self.startingVideoTime = time;
        if([self.asserWriter startWriting])
        {
            [self.asserWriter startSessionAtSourceTime:self.startingVideoTime];
            self.currentDuration = 0;
            self.isRecording = YES;
            self.isWritingWithoutError = YES;
        }
        else
        {
            if(self.delegate && [self.delegate respondsToSelector:@selector(didFailRecording:status:)])
            {
                [self.delegate didFailRecording:self.asserWriter.error status:@"[self.asserWriter startWriting] error"];
            }
            self.currentDuration = 0;
            self.isRecording = NO;
            self.isWritingWithoutError = NO;
        }
    }
    else if (self.asserWriter.status == AVPlayerLooperStatusFailed)
    {
        if(self.delegate && [self.delegate respondsToSelector:@selector(didFailRecording:status:)])
        {
            [self.delegate didFailRecording:self.asserWriter.error status:@"Video session failed while recording."];
        }
        NSLog(@"self.asserWriter.status == AVPlayerLooperStatusFailed !! error = %@",self.asserWriter.error);
        self.currentDuration = 0;
        self.isRecording = NO;
        self.isWritingWithoutError = NO;
        return;
    }
    if(self.videoInput.isReadyForMoreMediaData)
    {
        [self append:buffer time:time];
        self.currentDuration = CMTimeGetSeconds(time) - CMTimeGetSeconds(self.startingVideoTime);
        self.isRecording = YES;
        self.isWritingWithoutError = YES;
        if(self.delegate && [self.delegate respondsToSelector:@selector(didUpdateRecording:)])
        {
            [self.delegate didUpdateRecording:self.currentDuration];
        }
    }
    CVPixelBufferRelease(buffer);
}
- (void)append:(CVPixelBufferRef)buffer time:(CMTime)time{
    [self.pixelBufferInput appendPixelBuffer:buffer withPresentationTime:time];
}

- (void)pause
{
    self.isRecording = NO;
}
- (void)end:(void(^)(void))finishedHandler
{
    
    if(self.asserWriter.status == AVAssetWriterStatusWriting)
    {
         self.isRecording = NO;
        [self.asserWriter finishWritingWithCompletionHandler:finishedHandler];
        NSLog(@"视频写入完成");
    }
    else
    {
        NSLog(@"视频写入未完成");
    }
    
    
}
- (void)cancel
{
     self.isRecording = NO;
    [self.asserWriter cancelWriting];
}

#pragma mark -AVCaptureAudioDataOutputSampleBufferDelegate
- (NSDictionary<NSString *,id> *)videoOutputSettings
{
    if(_videoOutputSettings == nil)
    {
        CGFloat baseBitRate = 6.0;
        CGFloat baserateNum = 720 * 1280;
        CGFloat factNum  = self.size.width * self.size.height;
        CGFloat scale  = factNum / baserateNum;
        scale = MAX(0.5, scale);
        scale = MIN(2, scale);
        baseBitRate /= scale;
        NSLog(@"当前 baseBitRate = %f",baseBitRate);
        NSDictionary * comporessionPropeties = @{
                                                 AVVideoAverageBitRateKey:[NSNumber numberWithInt:self.size.width * self.size.height * baseBitRate],
                                                 AVVideoExpectedSourceFrameRateKey:@(self.fps),
                                                 AVVideoProfileLevelKey:AVVideoProfileLevelH264HighAutoLevel,
                                                 AVVideoMaxKeyFrameIntervalKey:@(20)
                                                 };
        _videoOutputSettings = @{
                                 AVVideoCodecKey:AVVideoCodecTypeH264,
                                 AVVideoWidthKey:@(self.size.width),
                                 AVVideoHeightKey:@(self.size.height),
                                 AVVideoCompressionPropertiesKey:comporessionPropeties,
                                 AVVideoScalingModeKey:AVVideoScalingModeResizeAspectFill
                                 };
    }
    return _videoOutputSettings;
}

- (NSDictionary<NSString *,id> *) audioSettings
{
    if(_audioSettings == nil)
    {
        AudioChannelLayout setereChannelLayout = {
            .mChannelLayoutTag = kAudioChannelLayoutTag_Mono,
            .mChannelBitmap = 0,
            .mNumberChannelDescriptions = 0,
        };
        
        NSData * channelLayoutAsData = [NSData dataWithBytes:&setereChannelLayout length:offsetof(AudioChannelLayout,mChannelDescriptions)];
        _audioSettings = @{
                           AVFormatIDKey:@(kAudioFormatMPEG4AAC),
                           AVEncoderBitRateKey:@(96000),
                           AVSampleRateKey:@(44100),
                           AVChannelLayoutKey:channelLayoutAsData,
                           AVNumberOfChannelsKey:@(1)
                           };
        
    }
    return _audioSettings;
}
#pragma mark - 类方法
+ (void) message:(NSString *)message
{
#if DEBUG
    NSLog(@"ARVideoKit:[%@]:%@",[NSDate date],message);
#endif
}
+ (void)removeFromePath:(NSURL *)path
{
    if([path path])
    {
        NSFileManager * manager = [NSFileManager defaultManager];
        if([manager fileExistsAtPath:[path path]])
        {
            NSError * error;
            [manager removeItemAtPath:[path path] error:&error];
            NSString * msg = [NSString stringWithFormat:@"移出文件%@:%@",error?@"失败":@"成功",[path path]];
            [self message:msg];
        }
    }
}
#pragma mark - AudioFilterInputEnabled
- (void)pushSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    NSLog(@"追加一个音频数据");
    if(self.audioInput)
    {
        CFRetain(sampleBuffer);
        dispatch_async(self.audioBufferQueue, ^{
            if(self.isRecording && [self.audioInput isReadyForMoreMediaData]){
                NSLog(@"追加一个音频数据");
                [self.audioInput appendSampleBuffer:sampleBuffer];
            }
            CFRelease(sampleBuffer);
        });
        
    }
}
@end
