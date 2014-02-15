//
//  SCTImageManager.m
//  ScrapTalk
//
//  Created by yukatou on 2014/02/15.
//  Copyright (c) 2014年 yukatou. All rights reserved.
//

#import "SCTPhotoManager.h"
#import "AFNetworking.h"
#import "NSDate+Addtion.h"
#import "NSData+Resize.h"

@interface SCTPhotoManager ()
@end

@implementation SCTPhotoManager

static NSString *const kPhotoAPIURL = @"http://v157-7-202-155.z1d4.static.cnode.jp/scraptalk/api/v1/talk/";

+ (SCTPhotoManager *) sharedInstance
{
    static dispatch_once_t onceToken = 0;
    __strong static SCTPhotoManager *_sharedObject = nil;
    dispatch_once(&onceToken, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}


- (void)requestPhotoList:(void(^)(NSArray *list, NSError *error))completion
{
    NSURL *url = [NSURL URLWithString:kPhotoAPIURL];
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url
                                                  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                              timeoutInterval:60.0f];
    
    
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
     {
         
         int status = ((NSHTTPURLResponse *)response).statusCode;
         NSLog(@"get status = %d", status);
         NSLog(@"get data = %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
         
         if (connectionError || data.length == 0) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 completion(nil, connectionError);
             });
             return;
         }
         
         NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data
                                                              options:NSJSONReadingAllowFragments
                                                                error:nil];
         
         if ([dict isEqual:[NSNull null]]) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 completion(nil, connectionError);
             });
             return;
         }
         

         NSMutableArray *list = [[NSMutableArray alloc] init];
         
         for (NSDictionary *row in dict[@"content_list"]) {
             SCTPhotoItem *item = [[SCTPhotoItem alloc] init];
             item.photoUrl = [NSURL URLWithString:row[@"photo_url"]];
             item.uploadedAt = [NSDate transformFromGMTFormat:row[@"exif_camera_day"]];
             [list addObject:item];
             
             if (!self.lastUploadedAt || [item.uploadedAt compare:self.lastUploadedAt] == NSOrderedDescending) {
                 self.lastUploadedAt = item.uploadedAt;
             }
         }
         
         
         
         if (completion) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 completion(list.copy, nil);
             });
         }
    }];
}

- (void)uploadPhoto:(NSData *)data completion:(void(^)(NSError *error))completion
{

    NSData *resizeData = [data resizeImageToSize:CGSizeMake(320.0f, 568.0f)];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    [manager POST:kPhotoAPIURL parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:resizeData name:@"file" fileName:@"file" mimeType:@"image/jpeg"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSLog(@"upload status = %ld", (long)operation.response.statusCode);
        
        _lastUploadedAt = [NSDate date];
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil);
            });
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        NSLog(@"Error: %@", error);
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(error);
            });
        }
    }];
}

- (void)getUploadedPhotoList:(void(^)(NSArray *list, NSError *error))completion
{
    NSURL *url = [NSURL URLWithString:kPhotoAPIURL];
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url
                                                  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                              timeoutInterval:60.0f];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
     {
         
         NSInteger status = ((NSHTTPURLResponse *)response).statusCode;
         NSLog(@"get status = %d", status);
         NSLog(@"get data = %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
         
         if (connectionError || data.length == 0) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 completion(nil, connectionError);
             });
             return;
         }
         
         NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data
                                                              options:NSJSONReadingAllowFragments
                                                                error:nil];
         
         if ([dict isEqual:[NSNull null]]) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 completion(nil, connectionError);
             });
             return;
         }

         NSMutableArray *list = [[NSMutableArray alloc] init];
         
         for (NSDictionary *row in dict[@"content_list"]) {
             SCTPhotoItem *item = [[SCTPhotoItem alloc] init];
             item.photoUrl = [NSURL URLWithString:row[@"photo_url"]];
             item.uploadedAt = [NSDate transformFromGMTFormat:row[@"exif_camera_day"]];
             
             if ([item.uploadedAt compare:_lastUploadedAt] == NSOrderedDescending) {
                 [list addObject:item];
             }
         }
         
         if (list.count > 0) {
             SCTPhotoItem *item = [list firstObject];
             self.lastUploadedAt = item.uploadedAt;
         }
         
         if (completion) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 completion(list.copy, nil);
             });
         }
   }];
}

@end
