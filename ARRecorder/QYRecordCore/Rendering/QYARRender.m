//
//  QYARRender.m
//  ARRecorder
//
//  Created by Yuri Boyka on 2019/9/4.
//  Copyright © 2019 Yuri Boyka. All rights reserved.
//

#import "QYARRender.h"
#import "UIScreen+QYCategory.h"
#import "UIImage+QYCategory.h"
@interface QYARRender()
{
    dispatch_queue_t _pixelsQueue;
}
@property(nonatomic,assign)id view;
@property(nonatomic,strong)SCNRenderer * renderEngine;
@end
@implementation QYARRender

- (instancetype)initWithARView:(id)view renderer:(SCNRenderer *)renderEngine contentMode:(ARFrameMode)mode
{
    self = [super init];
    if (self) {
        self.view = view;
        self.renderEngine = renderEngine;
        self.content = mode;
    }
    return self;
}

#pragma -mark Setter // Getter
- (dispatch_queue_t)pixelsQueue{
    if(_pixelsQueue == NULL){
        
        _pixelsQueue = dispatch_queue_create("com.qyARRecord.PixelsQueue", DISPATCH_QUEUE_CONCURRENT);
    }
    return _pixelsQueue;
}
- (CFTimeInterval)time{
    return CACurrentMediaTime();
}
- (CVPixelBufferRef)rawBuffer{
    if(self.view)
    {
        if([self.view isKindOfClass:[ARSCNView class]])
        {
            ARSCNView * scnView = (ARSCNView *)self.view;
            CVPixelBufferRef rawBuffer = [scnView.session.currentFrame capturedImage];
            return rawBuffer;
        } else if ([self.view isKindOfClass:[ARSKView class]])
        {
            ARSKView * skView = (ARSKView *)self.view;
            CVPixelBufferRef rawBuffer = [skView.session.currentFrame capturedImage];
            return rawBuffer;
        } else if ([self.view isKindOfClass:[SCNView class]]) {
            return self.buffer;
        }
    }
    return NULL;
}
- (CGSize)bufferSizeFill
{
    CVPixelBufferRef raw = self.rawBuffer;
    if(raw)
    {
        size_t width = CVPixelBufferGetWidth(raw);
        size_t height = CVPixelBufferGetHeight(raw);
        if(width > height)
        {
            return CGSizeMake(height, width);
        }
        else
        {
            return CGSizeMake(width, height);
        }
    }
    return CGSizeZero;
}
- (CGSize)bufferSize
{
    CVPixelBufferRef raw = self.rawBuffer;
//    if(raw){
        size_t width = CVPixelBufferGetWidth(raw);
        size_t height = CVPixelBufferGetHeight(raw);
//        switch(self.content)
//        {
//            case autoAdjust:{
//                if([[UIScreen mainScreen] qy_isPhone10])
//                {
//                    width = [UIScreen mainScreen].nativeBounds.size.width;
//                    height = [UIScreen mainScreen].nativeBounds.size.height;
//                }
//            }break;
//            case aspectFit:{
//                width = CVPixelBufferGetWidth(raw);
//                height = CVPixelBufferGetHeight(raw);
//            }break;
//            case aspectFill:{
//                width = [UIScreen mainScreen].nativeBounds.size.width;
//                height = [UIScreen mainScreen].nativeBounds.size.height;
//            }break;
//            default:{
//                if([[UIScreen mainScreen] qy_isPhone10])
//                {
//                    width = [UIScreen mainScreen].nativeBounds.size.width;
//                    height = [UIScreen mainScreen].nativeBounds.size.height;
//                }
//            }break;
//        }
        if(width > height){
            return CGSizeMake(height, width);
        } else {
            return CGSizeMake(width, height);
        }
//    }
//    return CGSizeZero;
}
- (CVPixelBufferRef)buffer{
    if(self.view){
        CGSize size = self.bufferSize;
        if(!CGSizeEqualToSize(self.outputSize, CGSizeZero))
        {
            size = CGSizeMake(self.outputSize.width * 2, self.outputSize.height * 2);
        }
        if([self.view isKindOfClass:[ARSCNView class]]){
            if(!CGSizeEqualToSize(size, CGSizeZero)){
                __block UIImage * renderFrame;
                dispatch_sync(self.pixelsQueue, ^{
                    renderFrame = [self.renderEngine snapshotAtTime:self.time withSize:size antialiasingMode:SCNAntialiasingModeNone];
                });
                if(!renderFrame){
                    renderFrame = [self.renderEngine snapshotAtTime:self.time withSize:size antialiasingMode:SCNAntialiasingModeNone];
                }
                CVPixelBufferRef buffer = [renderFrame buffertoSize:self.outputSize];
                return buffer;
            }
        } else if ([self.view isKindOfClass:[ARSKView class]]) {
             __block UIImage * renderFrame;
            dispatch_sync(self.pixelsQueue, ^{
                renderFrame = [[self.renderEngine snapshotAtTime:self.time withSize:size antialiasingMode:SCNAntialiasingModeNone] rotateByDegress:180.0f flip:NO];
            });
            if(renderFrame == nil) {
                renderFrame = [[self.renderEngine snapshotAtTime:self.time withSize:size antialiasingMode:SCNAntialiasingModeNone] rotateByDegress:180.0f flip:NO];
            }
            CVPixelBufferRef buffer = [renderFrame buffertoSize:self.outputSize];
            return buffer;
            
        } else if ([self.view isKindOfClass:[SCNView class]]) {
           __block UIImage * renderFrame;
            dispatch_sync(self.pixelsQueue, ^{
                renderFrame = [self.renderEngine snapshotAtTime:self.time withSize:size antialiasingMode:SCNAntialiasingModeNone];
            });
            if(renderFrame == nil){
                 renderFrame = [self.renderEngine snapshotAtTime:self.time withSize:size antialiasingMode:SCNAntialiasingModeNone];
            }
            CVPixelBufferRef buffer = [renderFrame buffertoSize:self.outputSize];
            return buffer;
        }
    }
    return nil;
}
@end
