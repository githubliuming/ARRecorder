//
//  RenderARDelegate.h
//  ARRecorder
//
//  Created by Yuri Boyka on 2019/9/4.
//  Copyright © 2019 Yuri Boyka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import<CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>

@protocol RenderARDelegate <NSObject>

- (void)frameDidRender:(CVPixelBufferRef)buffer time:(CMTime)time rawBuffer:(CVPixelBufferRef)rawBuffer;
@end

