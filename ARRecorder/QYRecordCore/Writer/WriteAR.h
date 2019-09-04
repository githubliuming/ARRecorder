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
NS_ASSUME_NONNULL_BEGIN

@interface WriteAR : NSObject
@property(nonatomic,weak)id delegate;

@property(nonatomic,assign)ARVideoOrientation videoInputOrientation;
@property(nonatomic,assign)BOOL isWritingWithoutError;
@property(nonatomic,assign)CMTime startingVideoTime;
@property(nonatomic,assign)NSTimeInterval currentDuration;

@end

NS_ASSUME_NONNULL_END
