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
@property(nonatomic,assign)BOOL enableAudio;
@property(nonatomic,assign)BOOL enableMixWithOthers;
@property(nonatomic,assign)BOOL adjustVideoForSharing;

@property(nonatomic,assign)BOOL enableAdjustEnvironmentLighting;

@property(nonatomic,assign)BOOL isRecording;
@property(nonatomic,assign)BOOL adjustPausedTime;

@property(nonatomic,strong)NSURL * currentVideoPath;
@property(nonatomic,strong)NSURL * currentAudioPath;

@property(nonatomic,assign)CGSize outputSize; //输出视频的尺寸,不设置会安原始帧的尺寸大小设置


/// 开始 或者 恢复录制视频
- (void)startRecord;

/// 开始录制指定时长的视频
/// @param time 录制时长
/// @param finished 录制完成回调
- (void)startRecord:(NSTimeInterval)time finished:(void(^)(NSURL * vidoePath))finished;
/// 暂停录制
- (void)pause;

/// 结束录制视频
/// @param finished 录制完成回调
- (void)stop:(void(^)(NSURL * vidoePath))finished;

/// 取消录制
- (void)cancel;
@end

NS_ASSUME_NONNULL_END
