//
//  QYReocrder.h
//  ARRecorder
//
//  Created by Yuri Boyka on 2019/9/3.
//  Copyright © 2019 Yuri Boyka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QYRecordConstant.h"
#import "RecordARDelegate.h"
#import "RenderARDelegate.h"
#import "WriteAR.h"
#import "ARView.h"
NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(11.0))
@interface QYReocrder : ARView

- (instancetype)initWithARSKView:(ARSCNView *)arView;

@property(nonatomic,weak)id<RecordARDelegate> delegate;
@property(nonatomic,weak)id<RenderARDelegate> renderARDelegate;

@property(nonatomic,assign)ARVideoFrameRate fps;
@property(nonatomic,assign)ARRecordStatus status;
@property(nonatomic,assign)MicrophoneStatus micStatus;
@property(nonatomic,assign)RecordARMicrophonePermission requestMicPermission;

@property(nonatomic,assign)ARVideoOrientation videoOrientation;
@property(nonatomic,assign)ARFrameMode contentMode;
@property(nonatomic,assign)ARFrameMode ARcontentMode;
@property(nonatomic,assign)BOOL onlyRenderWhileRecording;
@property(nonatomic,assign)BOOL enableAudio;
@property(nonatomic,assign)BOOL enableMixWithOthers;
@property(nonatomic,assign)BOOL adjustVideoForSharing;
@property(nonatomic,assign)BOOL adjustGIFForSharing;
@property(nonatomic,assign)BOOL deleteCacheWhenExported;
@property(nonatomic,assign)BOOL enableAdjustEnvironmentLighting;

@property(nonatomic,strong)dispatch_queue_t writerQueue;
@property(nonatomic,strong)dispatch_queue_t audioSessionQueue;

@property(nonatomic,assign)BOOL isRecording;
@property(nonatomic,assign)BOOL adjustPausedTime;
@property(nonatomic,assign)BOOL backFromPause;
@property(nonatomic,assign)BOOL recordingWithLimit;
@property(nonatomic,assign)BOOL onlyRenderWhileRec;
@property(nonatomic,assign)CMTime pausedFrameTime;
@property(nonatomic,assign)CMTime resumeFrameTime;
@property(nonatomic,strong)NSURL * currentVideoPath;
@property(nonatomic,strong)NSURL * currentAudioPath;
@property(nonatomic,strong)NSURL * videoPath;
@property(nonatomic,strong,nullable)WriteAR * wirtter;

@end

NS_ASSUME_NONNULL_END
