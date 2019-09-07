//
//  WriteAR.h
//  ARRecorder
//
//  Created by Yuri Boyka on 2019/9/4.
//  Copyright © 2019 Yuri Boyka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QYRecordConstant.h"
#import<CoreMedia/CoreMedia.h>
#import "RecordARDelegate.h"
NS_ASSUME_NONNULL_BEGIN

@interface WriteAR : NSObject
@property(nonatomic,weak)id<RecordARDelegate> delegate;

@property(nonatomic,assign)ARVideoOrientation videoInputOrientation;
@property(nonatomic,assign)BOOL isWritingWithoutError;
@property(nonatomic,assign)CMTime startingVideoTime;
@property(nonatomic,assign)NSTimeInterval currentDuration;

- (void)pause;
- (void)end:(void(^)(void))finishedHandler;
- (void)insert:(CVPixelBufferRef) buffer intervals:(CFTimeInterval)intervals;
- (void)insert:(CVPixelBufferRef)buffer time:(CMTime)time;
- (void)cancel;

+ (void) message:(NSString *)message;
+ (void)removeFromePath:(NSURL *)path;


- (instancetype)initWithOutput:(NSURL *)output
                          size:(CGSize)size
              adjustForSharing:(BOOL)adjustForSharing
                  audioEnabled:(BOOL)audioEnabled
                   orientaions:(NSArray *)orientaions
                         queue:(dispatch_queue_t)queue
                      allowMix:(BOOL)allowMix
                           fps:(NSInteger)fps;
@end

NS_ASSUME_NONNULL_END
