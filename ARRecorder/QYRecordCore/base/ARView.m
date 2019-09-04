//
//  ARView.m
//  ARRecorder
//
//  Created by Yuri Boyka on 2019/9/4.
//  Copyright © 2019 Yuri Boyka. All rights reserved.
//

#import "ARView.h"
#import <UIKit/UIKit.h>
#import <ARKit/ARKit.h>
@interface ARView()
{
    NSMutableArray * _inputViewOrientations;
}
@property(nonatomic,weak)UIViewController * parentVC;
@property(nonatomic,assign)NSInteger recentAngle;
@end
@implementation ARView
- (NSMutableArray *)inputViewOrientations
{
    if(_inputViewOrientations)
    {
        _inputViewOrientations = [[NSMutableArray alloc] init];
    }
    return _inputViewOrientations;
}
- (void)setInputViewOrientations:(NSMutableArray *)inputViewOrientations
{
    if(inputViewOrientations.count == 0)
    {
        _inputViewOrientations = [[NSMutableArray alloc] initWithArray:@[ @(portrait)]];
    }
    else
    {
        _inputViewOrientations = inputViewOrientations;
    }
}
- (instancetype)initWithARSKView:(ARSCNView *)arView
{
    self = [super init];
    if(self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(deviceDidRotate)
                                                     name:UIDeviceOrientationDidChangeNotification object:nil];
        [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationPortrait) forKey:@"orientation"];
       UIViewController * vc =  [self findParentVC:arView];
        if(vc)
        {
            self.parentVC = vc;
        }
    }
    return self;
}

- (void)deviceDidRotate
{
    if(self.parentVC)
    {
        NSArray * views = self.parentVC.view.subviews;
        if(views.count > 0)
        {
            NSInteger rotationAngle = 0;
            switch(self.inputViewOrientationMode)
            {
                case autoViewOrientationMode:{
                    
                }break;
                case all:{}break;
                case manualViewOrientationMode:{}break;
                case disabledViewOrientationMode:{}break;
            }
            views = @[];
           
            BOOL angleEnabled = NO;
            for(NSNumber * m in self.inputViewOrientations)
            {
                if([UIDevice currentDevice].orientation == [m integerValue])
                {
                    angleEnabled = YES;
                    break;
                }
            }
            switch([UIDevice currentDevice].orientation)
            {
                case UIDeviceOrientationLandscapeLeft:{
                    rotationAngle = -90;
                    self.recentAngle = -90;
                }break;
                case UIDeviceOrientationLandscapeRight:{
                    rotationAngle = 90;
                    self.recentAngle = 90;
                }break;
                    
                case UIDeviceOrientationFaceUp:
                case  UIDeviceOrientationFaceDown:
                case UIDeviceOrientationPortraitUpsideDown:{
                    rotationAngle = self.recentAngle;
                }break;
                default:{
                    rotationAngle = 0;
                    self.recentAngle = 0;
                }break;
                    
            }
            for(UIView * view in views)
            {
                [UIView animateWithDuration:0.2 animations:^{
                    view.transform = CGAffineTransformMakeRotation(rotationAngle * M_PI / 180);
                }];
            }
            
        }
    }
}
- (UIViewController *)findParentVC:(UIView *)view
{
    UIViewController * vc = nil;
    UIResponder * responder = view;
    while(responder)
    {
        responder = [responder nextResponder];
        if([responder isKindOfClass:[UIViewController class]])
        {
            vc = (UIViewController *)responder;
            break;
        }
    }
    return vc;
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}
@end
