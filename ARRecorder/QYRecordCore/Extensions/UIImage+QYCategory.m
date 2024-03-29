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

- (CVPixelBufferRef)buffertoSize:(CGSize)size
{
    if(CGSizeEqualToSize(size, self.size) ||
       size.width >= self.size.width ||
       size.height >= self.size.height ||
       CGSizeEqualToSize(size, CGSizeZero))
    {
//        return self.buffer;
        size = self.size;
    }
    CGRect cropRect = [self cropSize:self.size toSize:size];
    NSLog(@"裁剪 rect = %@ originSize = %@",NSStringFromCGRect(cropRect),NSStringFromCGSize(self.size));
    CVPixelBufferRef pixelBuffer = NULL;
    NSDictionary * attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                            [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                            nil];
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height, kCVPixelFormatType_32BGRA,(__bridge CFDictionaryRef)attrs, &pixelBuffer);
    if(status == kCVReturnSuccess)
    {
        CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
        
        void * data = CVPixelBufferGetBaseAddress(pixelBuffer);
        
        CGContextRef context = CGBitmapContextCreate(data,
                                                     size.width,
                                                     size.height,
                                                     8,
                                                     CVPixelBufferGetBytesPerRow(pixelBuffer),
                                                     CGColorSpaceCreateDeviceRGB(),
                                                     kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        
        CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, cropRect);
        CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), imageRef);
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
        
        CGContextRelease(context);
        CGImageRelease(imageRef);
    }
    return pixelBuffer;
}

- (CVPixelBufferRef)buffer
{
    NSDictionary * attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                            [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                            nil];
    CVPixelBufferRef pixelBuffer;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, self.size.width, self.size.height, kCVPixelFormatType_32BGRA,(__bridge CFDictionaryRef)attrs, &pixelBuffer);
    if(status == kCVReturnSuccess)
    {
        CVPixelBufferLockBaseAddress(pixelBuffer,kCVPixelBufferLock_ReadOnly);
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
- (CGRect)cropSize:(CGSize)size toSize:(CGSize)aSize
{
    size_t w = aSize.width;
    size_t h = aSize.height;
    double hRation = w / size.width;
    double vRation = h / size.height;
    double ration = MAX(hRation, vRation);
    w /= ration;
    h /= ration;
    return CGRectMake(((size_t)size.width - (size_t)w)/2.0, ((size_t)size.height - (size_t)h)/2.0f, w,h);
}
@end
