//
//  RecordARDelegate.h
//  ARRecorder
//
//  Created by Yuri Boyka on 2019/9/4.
//  Copyright © 2019 Yuri Boyka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QYRecordConstant.h"

@protocol RecordARDelegate <NSObject>

- (void)didEndRecording:(NSURL*)path noError:(BOOL)noError;

- (void)didFailRecording:(NSError *)error status:(NSString *)status;

- (void)didCancelReocording:(NSString *)status;

- (void)didUpdateRecording:(NSTimeInterval)duration;

- (void)willEnterBackground:(ARRecordStatus)status;
@end

