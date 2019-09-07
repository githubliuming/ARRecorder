//
//  UIImage+QYCategory.h
//  ARRecorder
//
//  Created by Yuri Boyka on 2019/9/4.
//  Copyright © 2019 Yuri Boyka. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (QYCategory)
- (UIImage *)rotateByDegress:(CGFloat)degress flip:(BOOL)flip;

- (CVPixelBufferRef)buffer;
- (CVPixelBufferRef)buffertoSize:(CGSize)size;
@end

NS_ASSUME_NONNULL_END
