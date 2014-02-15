//
//  NSDate+Addtion.h
//  ScrapTalk
//
//  Created by yukatou on 2014/02/16.
//  Copyright (c) 2014年 yukatou. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Addtion)
+ (NSDate *) transformFromGMTFormat:(NSString *)datestring;
@end
