//
//  QYARRender.h
//  ARRecorder
//
//  Created by Yuri Boyka on 2019/9/4.
//  Copyright © 2019 Yuri Boyka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ARKit/ARKit.h>
typedef NS_ENUM(NSInteger,ARFrameMode)
{
    autoAdjust,
    aspectFit,
    aspectFill,
}
API_AVAILABLE(ios(11.0));
NS_ASSUME_NONNULL_BEGIN

@interface QYARRender : NSObject
- (instancetype)initWithARView:(id)view renderer:(SCNRenderer *)renderEngine contentMode:(ARFrameMode)mode;

@property(nonatomic,assign,readonly)dispatch_queue_t pixelsQueue;
@property(nonatomic,assign,readonly)CFTimeInterval time;
@property(nonatomic,assign,readonly)CVPixelBufferRef rawBuffer;
@property(nonatomic,assign,readonly)CGSize bufferSize;
@property(nonatomic,assign,readonly,nullable)CVPixelBufferRef buffer;
@end

NS_ASSUME_NONNULL_END
