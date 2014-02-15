//
//  SCTImageManager.m
//  ScrapTalk
//
//  Created by yukatou on 2014/02/15.
//  Copyright (c) 2014年 yukatou. All rights reserved.
//

#import "SCTPhotoManager.h"
#import "AFNetworking.h"

@interface SCTPhotoManager ()
@property (nonatomic, copy, readwrite) NSMutableArray *imageList;
@end


@implementation SCTPhotoManager

- (void)requestPhotoList:(void(^)(NSArray *list, NSError *error))completion
{
    NSString *urlString = @"http://v157-7-202-155.z1d4.static.cnode.jp/scraptalk/api/v1/talk/";
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url
                                                  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                              timeoutInterval:60.0f];
    
    
    NSMutableArray *list = [[NSMutableArray alloc] init];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
     {
         
         if (connectionError) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 completion(nil, connectionError);
             });
             return;
         }
         
         NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data
                                                              options:NSJSONReadingAllowFragments
                                                                error:nil];
         
         for (NSDictionary *row in dict[@"content_list"]) {
             SCTPhotoItem *item = [[SCTPhotoItem alloc] init];
             item.photoUrl = [NSURL URLWithString:row[@"photo_url"]];
             [list addObject:item];
         }
         
         if (completion) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 completion(list.copy, nil);
             });
         }
    }];
}

@end
