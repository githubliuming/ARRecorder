//
//  QYReocrder.m
//  ARRecorder
//
//  Created by Yuri Boyka on 2019/9/3.
//  Copyright © 2019 Yuri Boyka. All rights reserved.
//

#import "QYReocrder.h"

@interface QYReocrder()
@property(nonatomic,weak)ARSCNView * weakScnView;
@property(nonatomic,strong)CADisplayLink * displayLink;
@property(nonatomic,strong)SCNRenderer * renderEngine;
@end
@implementation QYReocrder
- (instancetype)initWithARSKView:(ARSCNView *)arView
{
    self = [super init];
    if(self)
    {
        _weakScnView  = arView;
    }
    return self;
}
- (void)initEnvironment
{
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    NSAssert(device, @"该设备不支持 Metal");
    self.renderEngine = [SCNRenderer rendererWithDevice:device options:nil];
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(renderFrame)];
    self.displayLink.preferredFramesPerSecond = self.recordFPS;
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}
- (void)renderFrame
{
    
}
@end
