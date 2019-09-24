//
//  QYVoiceChangeFilter.m
//  ARDemo
//
//  Created by Yuri Boyka on 2019/9/23.
//  Copyright © 2019 11. All rights reserved.
//

#import "QYVoiceChangeFilter.h"
#import "SoundTouch.h"
using namespace soundtouch;
@interface QYVoiceChangeFilter()
@property(nonatomic,strong)NSMutableArray * targets;
@property(nonatomic,assign)void * mSoundTouch;

@property(nonatomic,assign) uint sampleRate;  //音频采样率
@property(nonatomic,assign) uint channels;    //声道

@end
@implementation QYVoiceChangeFilter

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self initSoundTouch];
        self.tempoChange = -25;
        self.pitch = 10;
        self.rate = -5;
        self.channels = 1;
    }
    return self;
}

- (void)initSoundTouch
{
    SoundTouch * mSoundTouch = new SoundTouch();
    mSoundTouch->setSampleRate(44100);
    mSoundTouch->setChannels(1);
    
    mSoundTouch->setSetting(SETTING_SEQUENCE_MS, 40);
    mSoundTouch->setSetting(SETTING_SEEKWINDOW_MS, 15); //寻找帧长
    mSoundTouch->setSetting(SETTING_OVERLAP_MS, 6);  //重叠帧长
    self.mSoundTouch = mSoundTouch;
}

- (void)outputSampbuffer:(CMSampleBufferRef)sampleBuffer
{
    NSLog(@"变声器输出一个 buff");
    //将处理后的
    for (id<AudioFilterInputEnabled> target in self.targets)
    {
        [target pushSampleBuffer:sampleBuffer];
    }
}

- (CMSampleBufferRef)createAudioSample:(void *)audioData
                                frames:(UInt32)len
                                timing:(CMSampleTimingInfo)timing
                          description:(const AudioStreamBasicDescription *)description
                         oSampleBuffer:(CMSampleBufferRef)oSampleBuffer
{
    int channels = 1;
    AudioBufferList audioBufferList;
    audioBufferList.mNumberBuffers = 1;
    audioBufferList.mBuffers[0].mNumberChannels=channels;
    audioBufferList.mBuffers[0].mDataByteSize=len;
    audioBufferList.mBuffers[0].mData = audioData;
    
//    AudioStreamBasicDescription asbd;
//    asbd.mSampleRate = description -> mSampleRate;
//    asbd.mFormatID = description ->mFormatID;
//    asbd.mFormatFlags = description ->mFormatFlags;
//    asbd.mBytesPerPacket = description ->mBytesPerPacket;
//    asbd.mFramesPerPacket = description ->mFramesPerPacket;
//    asbd.mBytesPerFrame = description ->mBytesPerFrame;
//    asbd.mChannelsPerFrame = description ->mChannelsPerFrame;
//    asbd.mBitsPerChannel = description ->mBitsPerChannel;
//    asbd.mReserved = description ->mReserved;
    
    CMSampleBufferRef buff = NULL;
    static CMFormatDescriptionRef format = NULL;
    
    OSStatus error = 0;
    error = CMAudioFormatDescriptionCreate(kCFAllocatorDefault, description, 0, NULL, 0, NULL, NULL, &format);
    if (error) {
        return NULL;
    }
    
    error = CMSampleBufferCreate(kCFAllocatorDefault, NULL, false, NULL, NULL, format, len/2, 1, &timing, 0, NULL, &buff);
    if (error) {
        return NULL;
    }
    
    error = CMSampleBufferSetDataBufferFromAudioBufferList(buff, kCFAllocatorDefault, kCFAllocatorDefault, 0, &audioBufferList);
    if(error){
        return NULL;
    }
    
    return buff;
}

- (NSData *)audioData:(CMSampleBufferRef)sampleBuffer numSamples:(uint *)numSamples
{
    //取出 sampleBuffer 中音频数据
    AudioBufferList audioBufferList;
    CMBlockBufferRef blockBuffer;
    CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &audioBufferList, sizeof(audioBufferList), NULL, NULL, 0, &blockBuffer);
    
    AudioBuffer audioBuffer = audioBufferList.mBuffers[0];
    self.channels = audioBuffer.mNumberChannels;
    NSMutableData *audioData=[[NSMutableData alloc] init];
    [audioData appendBytes: audioBuffer.mData length:audioBuffer.mDataByteSize];
    CFRelease(blockBuffer);
    return audioData;
}
#pragma mark - AudioFilterInputEnabled
- (void)pushSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    NSTimeInterval t1 = [[NSDate date] timeIntervalSince1970];
    CFRetain(sampleBuffer);
    
    CMFormatDescriptionRef formatDescription =
    CMSampleBufferGetFormatDescription(sampleBuffer);
    
    const AudioStreamBasicDescription* const asbd =
    CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription);
    self.sampleRate = asbd -> mSampleRate;
    
    SoundTouch * soundTouch = [self GetSoundTouchOBJ];
    uint nSamples = 0;
    NSData * audioData = [self audioData:sampleBuffer numSamples:&nSamples];
    NSLog(@"变声之前的 size = %lu",(unsigned long)audioData.length);
    NSUInteger pcmSize = audioData.length;
    nSamples = (uint)pcmSize / (2 * self.channels);
    SAMPLETYPE * pcmData = (SAMPLETYPE *)audioData.bytes;
    soundTouch->putSamples(pcmData, nSamples);
    NSMutableData *soundTouchDatas = [[NSMutableData alloc] init];
    SAMPLETYPE *samples = new SAMPLETYPE[pcmSize];
    uint numSamples = 0;
    do {
        memset(samples, 0, pcmSize);
        numSamples = soundTouch -> receiveSamples(samples,(uint)pcmSize);
        [soundTouchDatas appendBytes:samples length:numSamples * 2];
        NSLog(@"numSamples = %d",numSamples);
    } while (numSamples > 0);
    delete [] samples;

    NSLog(@"变声之后的 size = %lu",(unsigned long)soundTouchDatas.length);
//
    //获取 sampleBuffer 时间信息
    CMItemCount timingCount;
    CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, 0, nil, &timingCount);
    CMSampleTimingInfo* pInfo = (CMSampleTimingInfo *)malloc(sizeof(CMSampleTimingInfo) * timingCount);
    CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, timingCount, pInfo, &timingCount);
    //转换后的音频数据
    void *touchData = (void *)[soundTouchDatas bytes];
    //转换后的 sampleBuffer
    CMSampleBufferRef tSampleBufferRef = [self createAudioSample:touchData
                                                          frames:(int)[soundTouchDatas length]
                                                          timing:*pInfo
                                                     description:asbd
                                                   oSampleBuffer:sampleBuffer];
    if (tSampleBufferRef)
    {
        [self outputSampbuffer:tSampleBufferRef];
        CFRelease(tSampleBufferRef);
    }
    NSTimeInterval t2 = [[NSDate date] timeIntervalSince1970];
    NSLog(@"消耗时间 = %f",t2 - t1);
    CFRelease(sampleBuffer);
}
#pragma mark - AudioFilterOutEnabled
- (void)addTarget:(id<AudioFilterInputEnabled>)target
{
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

#pragma mark -Getter/Setter
- (void)setRate:(double)rate
{
    if (_rate != rate)
    {
        _rate = rate;
        SoundTouch * soundTouch = [self GetSoundTouchOBJ];
        soundTouch -> setRateChange(_rate);
    }
}
- (void) setPitch:(int)pitch
{
    if (_pitch != pitch)
    {
        _pitch = pitch;
        SoundTouch * soundTouch = [self GetSoundTouchOBJ];
        soundTouch ->setPitchSemiTones(_pitch);
    }
}

- (void) setTempoChange:(int)tempoChange
{
    if (_tempoChange != tempoChange)
    {
        _tempoChange = tempoChange;
        SoundTouch * soundTouch = [self GetSoundTouchOBJ];
        soundTouch ->setTempoChange(_tempoChange);
    }
}
- (void)setSampleRate:(uint)sampleRate
{
    if (_sampleRate != sampleRate)
    {
        _sampleRate = sampleRate;
        NSLog(@"变换采样率 = %u",_sampleRate);
        SoundTouch * soundTouch = [self GetSoundTouchOBJ];
        soundTouch -> setSampleRate(_sampleRate);
    }
}
- (void)setChannels:(uint)channels
{
    if (_channels != channels)
    {
        _channels = channels;
        SoundTouch * soundTouch = [self GetSoundTouchOBJ];
        soundTouch ->setChannels(_channels);
    }
}
- (NSMutableArray *)targets
{
    if(_targets == nil)
    {
        _targets = [[NSMutableArray alloc] init];
    }
    return _targets;
}

- (SoundTouch *) GetSoundTouchOBJ
{
   return (SoundTouch *)self.mSoundTouch;
}

- (void)dealloc
{
    if (self.mSoundTouch)
    {
        delete (SoundTouch *)self.mSoundTouch;
        self.mSoundTouch = NULL;
    }
}
@end
