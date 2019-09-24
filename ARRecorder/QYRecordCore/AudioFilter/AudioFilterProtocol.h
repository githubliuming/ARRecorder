//
//  AudioFilterProtocol.h
//  ARDemo
//
//  Created by Yuri Boyka on 2019/9/23.
//  Copyright © 2019 11. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

/// 具有接受 sampleBuffer 能力的filter
@protocol AudioFilterInputEnabled
//接受上一个 target 的输出
- (void)pushSampleBuffer:(CMSampleBufferRef)sampleBuffer;
@end

/// 具有输出 sampleBuffer 能力的 filter
@protocol AudioFilterOutEnabled <NSObject>

//将处理后的数据输出给下一个 target
- (void)outputSampbuffer:(CMSampleBufferRef)sampleBuffer;
/// 添加输出源
- (void)addTarget:(id<AudioFilterInputEnabled>)target;

- (void)removeAllTargets;

- (void)removeTarget:(id<AudioFilterInputEnabled>)target;

@end
