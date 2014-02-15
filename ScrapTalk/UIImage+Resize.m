//
//  UIImage+Resize.m
//  ScrapTalk
//
//  Created by yukatou on 2014/02/15.
//  Copyright (c) 2014年 yukatou. All rights reserved.
//

#import "UIImage+Resize.h"

@implementation UIImage (Resize)

- (UIImage *)resizingImageTo:(CGSize)resize
{
    UIGraphicsBeginImageContextWithOptions(resize, YES, 0.0);
    [self drawInRect:CGRectMake(0, 0, resize.width, resize.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resizedImage;
}
@end
