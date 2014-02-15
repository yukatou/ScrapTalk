//
//  UIView+move.m
//  ScrapTalk
//
//  Created by yukatou on 2014/02/15.
//  Copyright (c) 2014年 yukatou. All rights reserved.
//

#import "UIView+move.h"

@implementation UIView (move)


- (void)moveTo:(CGPoint)point
{
     self.frame = CGRectMake(point.x, point.y, self.frame.size.width, self.frame.size.height);
}
@end
