//
//  NSData+Resize.m
//  ScrapTalk
//
//  Created by yukatou on 2014/02/16.
//  Copyright (c) 2014年 yukatou. All rights reserved.
//

#import "NSData+Resize.h"

@implementation NSData (Resize)


- (NSData *)resizeImageToSize:(CGSize)size
{
    UIImage *image = [[UIImage alloc] initWithData:self];
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    image =  UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return UIImageJPEGRepresentation(image, 0.5f);
}

@end
