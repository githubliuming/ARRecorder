//
//  QYReocrder.h
//  ARRecorder
//
//  Created by Yuri Boyka on 2019/9/3.
//  Copyright © 2019 Yuri Boyka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ARKit/ARKit.h>
NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(11.0))
@interface QYReocrder : NSObject
- (instancetype)initWithARSKView:(ARSCNView *)arView;

@property(nonatomic,assign)NSInteger recordFPS;

@end

NS_ASSUME_NONNULL_END
