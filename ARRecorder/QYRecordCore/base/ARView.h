//
//  ARView.h
//  ARRecorder
//
//  Created by Yuri Boyka on 2019/9/4.
//  Copyright © 2019 Yuri Boyka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QYRecordConstant.h"
#import <ARKit/ARKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface ARView : NSObject

@property(nonatomic,strong)NSMutableArray * inputViewOrientations;
@property(nonatomic,assign)ARInputViewOrientationMode inputViewOrientationMode;

- (instancetype)initWithARSKView:(ARSCNView *)arView;

@end

NS_ASSUME_NONNULL_END
