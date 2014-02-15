//
//  NSDate+Addtion.m
//  ScrapTalk
//
//  Created by yukatou on 2014/02/16.
//  Copyright (c) 2014年 yukatou. All rights reserved.
//

#import "NSDate+Addtion.h"

@implementation NSDate (Addtion)

+ (NSDate *) transformFromGMTFormat:(NSString *)datestring
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ja_JP"]];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"JST"]];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:sszzz"];
    
    return [formatter dateFromString:datestring];
}

@end
