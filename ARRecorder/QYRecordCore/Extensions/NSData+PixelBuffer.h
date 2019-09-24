//
//  NSData+PixelBuffer.h
//  ARDemo
//
//  Created by Yuri Boyka on 2019/9/20.
//  Copyright © 2019 11. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface NSData (PixelBuffer)

- (CVPixelBufferRef)pexelBuffer:(size_t)width height:(size_t)height;
@end

NS_ASSUME_NONNULL_END
