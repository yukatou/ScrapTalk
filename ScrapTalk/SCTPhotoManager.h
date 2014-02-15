//
//  SCTImageManager.h
//  ScrapTalk
//
//  Created by yukatou on 2014/02/15.
//  Copyright (c) 2014年 yukatou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCTPhotoItem.h"

@interface SCTPhotoManager : NSObject
@property (nonatomic, strong) NSDate *lastUploadedAt;

+ (SCTPhotoManager *)sharedInstance;
- (void)requestPhotoList:(void(^)(NSArray *list, NSError *error))completion;
- (void)uploadPhoto:(NSData *)data completion:(void(^)(NSError *error))completion;
- (void)getUploadedPhotoList:(void(^)(NSArray *list, NSError *error))completion;
@end
