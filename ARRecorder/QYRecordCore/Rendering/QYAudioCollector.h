//
//  QYAudioCollector.h
//  ARDemo
//
//  Created by Yuri Boyka on 2019/9/23.
//  Copyright © 2019 11. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioFilterProtocol.h"
NS_ASSUME_NONNULL_BEGIN

@interface QYAudioCollector : NSObject<AudioFilterOutEnabled>

- (instancetype)initWithAudioEnabled:(BOOL)audioEnabled
                               queue:(dispatch_queue_t)queue;

- (void)pause;
- (void)end;
- (void)cancel;
- (void)startRecord;

@end

NS_ASSUME_NONNULL_END
