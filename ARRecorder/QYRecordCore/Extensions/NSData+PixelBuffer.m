//
//  NSData+PixelBuffer.m
//  ARDemo
//
//  Created by Yuri Boyka on 2019/9/20.
//  Copyright © 2019 11. All rights reserved.
//

#import "NSData+PixelBuffer.h"

@implementation NSData (PixelBuffer)

- (CVPixelBufferRef)pexelBuffer:(size_t)width height:(size_t)height
{
    CVPixelBufferRef buffer = NULL;
    
    unsigned char * pImageData = (unsigned char *)[self bytes];
    
    CFDictionaryRef empty;
    empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL,
                               0,
                               &kCFTypeDictionaryKeyCallBacks,
                               &kCFTypeDictionaryValueCallBacks);
    
    CFMutableDictionaryRef m_pPixelBufferAttribs = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                                                             3,
                                                                             &kCFTypeDictionaryKeyCallBacks,
                                                                             &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(m_pPixelBufferAttribs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    CFDictionarySetValue(m_pPixelBufferAttribs, kCVPixelBufferOpenGLCompatibilityKey, empty);
    CFDictionarySetValue(m_pPixelBufferAttribs, kCVPixelBufferCGBitmapContextCompatibilityKey, empty);
    
    CVPixelBufferCreateWithBytes(kCFAllocatorDefault,
                                 width,
                                 height,
                                 kCVPixelFormatType_32BGRA,
                                 pImageData,
                                 width * 4,
                                 NULL,
                                 NULL,
                                 m_pPixelBufferAttribs,
                                 &buffer);
    CFRelease(empty);
    return buffer;
}
@end
