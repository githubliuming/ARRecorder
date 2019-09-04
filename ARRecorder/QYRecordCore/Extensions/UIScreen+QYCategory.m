//
//  UIScreen+QYCategory.m
//  ARRecorder
//
//  Created by Yuri Boyka on 2019/9/4.
//  Copyright © 2019 Yuri Boyka. All rights reserved.
//

#import "UIScreen+QYCategory.h"

@implementation UIScreen (QYCategory)
- (BOOL) qy_isPhone10{
    CGSize size = self.nativeBounds.size;
    return CGSizeEqualToSize(size, CGSizeMake(1125, 2436)) ||
           CGSizeEqualToSize(size, CGSizeMake(2436, 1125));
}
@end
