//
//  WriteAR.m
//  ARRecorder
//
//  Created by Yuri Boyka on 2019/9/4.
//  Copyright © 2019 Yuri Boyka. All rights reserved.
//

#import "WriteAR.h"
#import <AVFoundation/AVFoundation.h>
@interface WriteAR()
@property(nonatomic,strong)AVAssetWriter * asserWriter;
@property(nonatomic,strong)AVAssetWriterInput * videoInput;
@property(nonatomic,strong)AVAssetWriterInput * audioInput;
@property(nonatomic,strong)AVCaptureSession * session;

@property(nonatomic,strong)AVAssetWriterInputPixelBufferAdaptor * pixelBufferInput;
@property(nonatomic,strong)NSDictionary<NSString *,id> * vidoOutputSettings;
@property(nonatomic,strong)NSDictionary<NSString *,id> * audioSettings;

@property(nonatomic,assign)dispatch_queue_t audioBufferQueue;
@property(nonatomic,assign)BOOL isRecording;

@property(nonatomic,weak)id delegate;

@end
@implementation WriteAR


@end
