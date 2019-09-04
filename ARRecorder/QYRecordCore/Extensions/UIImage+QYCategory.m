//
//  UIImage+QYCategory.m
//  ARRecorder
//
//  Created by Yuri Boyka on 2019/9/4.
//  Copyright © 2019 Yuri Boyka. All rights reserved.
//

#import "UIImage+QYCategory.h"

@implementation UIImage (QYCategory)
- (UIImage *)rotateByDegress:(CGFloat)degress flip:(BOOL)flip
{
    CGFloat radians = degress *  M_PI / 180.0f;
    //待优化，可以直接进行矩阵运算
    UIView * bufferView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.size.width, self.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(radians);
    bufferView.transform = t;
    CGSize bufferSize = bufferView.frame.size;
    UIGraphicsBeginImageContextWithOptions(bufferSize, false, self.scale);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(bitmap,bufferSize.width / 2.0,bufferSize.height /2.0);
    CGContextRotateCTM(bitmap, radians);
    CGContextScaleCTM(bitmap,flip? -1.0:1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-self.size.width /2.0f, -self.size.height /2.0f, self.size.width, self.size.height), self.CGImage);
    UIImage * finalBuffer = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CFRelease(bitmap);
    return finalBuffer;
}

- (CVPixelBufferRef)buffer
{
    NSDictionary * attrs = @{(__bridge NSString *)kCVPixelBufferCGImageCompatibilityKey:@(YES),(__bridge NSString *)kCVPixelBufferCGBitmapContextCompatibilityKey:@(YES)};

    CVPixelBufferRef pixelBuffer;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, self.size.width, self.size.height, kCVPixelFormatType_32ARGB,(__bridge CFDictionaryRef)attrs, &pixelBuffer);
    if(status == kCVReturnSuccess)
    {
        CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
        void * pixelData = CVPixelBufferGetBaseAddress(pixelBuffer);
       CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
       CGContextRef context = CGBitmapContextCreate(pixelData, self.size.width, self.size.height, 8, CVPixelBufferGetBytesPerRow(pixelBuffer), colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGContextTranslateCTM(context, 0, self.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        UIGraphicsPushContext(context);
        [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height)];
        UIGraphicsPopContext();
        CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
        CFRelease(context);
        return pixelBuffer;
    }
    return nil;
}
@end
