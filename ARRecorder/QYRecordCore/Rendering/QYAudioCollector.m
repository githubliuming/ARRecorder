//
//  QYAudioCollector.m
//  ARDemo
//
//  Created by Yuri Boyka on 2019/9/23.
//  Copyright © 2019 11. All rights reserved.
//

#import "QYAudioCollector.h"
#import <AVFoundation/AVFoundation.h>

@interface QYAudioCollector()<AVCaptureAudioDataOutputSampleBufferDelegate>

@property(nonatomic,strong)AVAssetWriterInput * audioInput;
@property(nonatomic,strong)AVCaptureSession * session;
@property(nonatomic,strong)NSDictionary<NSString *,id> * audioSettings;
@property(nonatomic,strong)dispatch_queue_t audioBufferQueue;
@property(nonatomic,strong)NSMutableArray * targets;
@property(nonatomic,assign)BOOL isRecording;
@end
@implementation QYAudioCollector

- (instancetype)initWithAudioEnabled:(BOOL)audioEnabled queue:(dispatch_queue_t)queue
{
    self = [super init];
    if (self) {
        
        self.targets = [[NSMutableArray alloc] init];
         self.audioBufferQueue = dispatch_queue_create("com.qyARRecord.audioBufferQueue",DISPATCH_QUEUE_SERIAL);
        
        if(audioEnabled)
        {
           NSError * error = nil;
            AVAudioSession * session = [AVAudioSession sharedInstance];
            [session setCategory:AVAudioSessionCategoryPlayAndRecord
                            mode:AVAudioSessionModeSpokenAudio
                         options:AVAudioSessionCategoryOptionMixWithOthers|AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionDefaultToSpeaker|AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers
                           error:&error];
            NSAssert(!error,@"faluire setup AVAudioSession");
            error = nil;
            [session setActive:YES error:&error];
            NSAssert(!error,@"faluire Active AVAudioSession");
            
            [session requestRecordPermission:^(BOOL granted) {
                
                NSLog(@"麦克风权限 = %d",granted);
                if(granted)
                {
                    [self prepareAudioDevice:queue];
                }
            }];
        }
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
        //        self.audioSettings = [audioDataOutput recommendedAudioSettingsForAssetWriterWithOutputFileType:AVFileTypeAppleM4V];
        self.audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:self.audioSettings];
        self.audioInput.expectsMediaDataInRealTime = YES;
        dispatch_async(self.audioBufferQueue, ^{
            self.isRecording = YES;
            [self.session startRunning];
            
        });
        NSLog(@"音频录制准备完成");
    }
}

#pragma mark -AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
     NSLog(@"kkkkkkkkkkkkkkk");
    if(self.audioInput)
    {
        NSLog(@"ddddddddddddddd");
        CFRetain(sampleBuffer);
        dispatch_async(self.audioBufferQueue, ^{
            NSLog(@"采集到一个音频 buff");
            [self outputSampbuffer:sampleBuffer];
            CFRelease(sampleBuffer);
        });
    }
}
#pragma mark - 音频数据设置
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
#pragma mark -AudioFilterOutEnabled

- (void)outputSampbuffer:(CMSampleBufferRef)sampleBuffer
{
    if(self.isRecording)
    {
        for(id<AudioFilterInputEnabled> target in self.targets)
        {
            [target pushSampleBuffer:sampleBuffer];
        }
    }
}

- (void)addTarget:(id<AudioFilterInputEnabled>)target {
    if(![self.targets containsObject:target])
    {
        [self.targets addObject:target];
    }
}

- (void)removeAllTargets
{
    [self.targets removeAllObjects];
}

- (void)removeTarget:(id<AudioFilterInputEnabled>)target
{
    if([self.targets containsObject:target])
    {
        [self.targets removeObject:target];
    }
}

- (void)startRecord
{
    self.isRecording = YES;
}
- (void)pause
{
    self.isRecording = NO;
}
- (void)end
{
    if(self.session && [self.session isRunning])
    {
        [self.session stopRunning];
    }
    self.isRecording = NO;
}
- (void)cancel
{
    [self end];
}
@end
