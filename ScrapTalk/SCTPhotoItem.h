//
//  SCTPhotoItem.h
//  ScrapTalk
//
//  Created by yukatou on 2014/02/15.
//  Copyright (c) 2014年 yukatou. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCTPhotoItem : NSObject
@property (nonatomic, strong) NSURL *photoUrl;
@property (nonatomic, strong) NSDate *uploadedAt;
@end
