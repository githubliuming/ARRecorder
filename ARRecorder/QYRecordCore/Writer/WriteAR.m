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
@property(nonatomic,strong)AVCaptureSession * session;

@property(nonatomic,strong)AVAssetWriterInputPixelBufferAdaptor * pixelBufferInput;
@property(nonatomic,strong)NSDictionary<NSString *,id> * videoOutputSettings;
@property(nonatomic,strong)NSDictionary<NSString *,id> * audioSettings;

@property(nonatomic,strong)dispatch_queue_t audioBufferQueue;
@property(nonatomic,assign)BOOL isRecording;

@end
@implementation WriteAR

- (instancetype)initWithOutput:(NSURL *)output
                          size:(CGSize)size
              adjustForSharing:(BOOL)adjustForSharing
                  audioEnabled:(BOOL)audioEnabled
                   orientaions:(NSArray *)orientaions
                         queue:(dispatch_queue_t)queue
                      allowMix:(BOOL)allowMix
{
    self = [super init];
    if (self) {
        NSAssert(output, @"faluire output is nil");
        NSError * error;
        self.asserWriter = [AVAssetWriter assetWriterWithURL:output fileType:AVFileTypeMPEG4 error:&error];
        NSAssert(error,@"faluire init AVAssetWriter");
        self.audioBufferQueue = dispatch_queue_create("com.qyARRecord.audioBufferQueue",DISPATCH_QUEUE_SERIAL);
        self.videoInputOrientation = autoOrientation;
        if(audioEnabled)
        {
            error = nil;
            AVAudioSession * session = [AVAudioSession sharedInstance];
            [session setCategory:AVAudioSessionCategoryPlayAndRecord
                            mode:AVAudioSessionModeSpokenAudio
                         options:AVAudioSessionCategoryOptionMixWithOthers|AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionDefaultToSpeaker|AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers
                           error:&error];
            NSAssert(error,@"faluire setup AVAudioSession");
            error = nil;
            [session setActive:YES error:&error];
            NSAssert(error,@"faluire Active AVAudioSession");
            
            [session requestRecordPermission:^(BOOL granted) {
               
                if(granted)
                {
                    [self prepareAudioDevice:queue];
                }
            }];
        }
        self.videoOutputSettings = @{AVVideoCodecKey:AVVideoCodecTypeH264,AVVideoWidthKey:@(size.width),AVVideoHeightKey:@(size.height)};
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

- (void)prepareAudioDevice:(dispatch_queue_t )queue
{
    NSError * error;
    AVCaptureDevice * device =  [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *  audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if(!error)
    {
       AVCaptureAudioDataOutput * audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
        [audioDataOutput setSampleBufferDelegate:self queue:queue];
        self.session = [[AVCaptureSession alloc] init];
        self.session.sessionPreset = AVCaptureSessionPresetMedium;
        self.session.usesApplicationAudioSession = YES;
        self.session.automaticallyConfiguresApplicationAudioSession = NO;
        if([self.session canAddInput:audioDeviceInput])
        {
            [self.session addInput:audioDeviceInput];
        }
        if([self.session canAddOutput:audioDataOutput])
        {
            [self.session addOutput:audioDataOutput];
        }
        self.audioSettings = [audioDataOutput recommendedAudioSettingsForAssetWriterWithOutputFileType:AVFileTypeAppleM4V];
        self.audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:self.audioSettings];
        self.audioInput.expectsMediaDataInRealTime = YES;
        dispatch_async(self.audioBufferQueue, ^{
            [self.session startRunning];
        });
        if([self.asserWriter canAddInput:self.audioInput])
        {
            [self.asserWriter addInput:self.audioInput];
        }
    }
    
}
- (void)insert:(CVPixelBufferRef) buffer intervals:(CFTimeInterval)intervals
{
    CMTime time = CMTimeMakeWithSeconds(intervals, 1000000);
    [self insert:buffer time:time];
}
- (void)insert:(CVPixelBufferRef)buffer time:(CMTime)time
{
    if(self.asserWriter.status == AVPlayerLooperStatusUnknown)
    {
        if(CMTIME_IS_INVALID(self.startingVideoTime))
        {
            self.isWritingWithoutError = false;
            return;
        }
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
    if(self.session && [self.session isRunning])
    {
        [self.session stopRunning];
    }
    if(self.asserWriter.status == AVAssetWriterStatusWriting)
    {
        [self.asserWriter finishWritingWithCompletionHandler:finishedHandler];
    }
    
}
- (void)cancel
{
    if(self.self && [self.session isRunning])
    {
        [self.session stopRunning];
    }
    [self.asserWriter cancelWriting];
}

#pragma mark -AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if(self.audioInput)
    {
        dispatch_async(self.audioBufferQueue, ^{
            if([self.audioInput isReadyForMoreMediaData] && self.isRecording){
                [self.audioInput appendSampleBuffer:sampleBuffer];
            }
        });
    }
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
@end
