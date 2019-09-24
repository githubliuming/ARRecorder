//
//  QYVoiceChangeFilter.h
//  ARDemo
//
//  Created by Yuri Boyka on 2019/9/23.
//  Copyright © 2019 11. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioFilterProtocol.h"
NS_ASSUME_NONNULL_BEGIN

@interface QYVoiceChangeFilter : NSObject<AudioFilterInputEnabled,AudioFilterOutEnabled>

@property(nonatomic,assign) int tempoChange; //速度 <变速不变调> 范围 -50 ~ 100
@property(nonatomic,assign) int pitch; //音调  范围 -12 ~ 12
@property(nonatomic,assign) double rate;  //声音速率 范围 -50 ~ 100
@end

NS_ASSUME_NONNULL_END
