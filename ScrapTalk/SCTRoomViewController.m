//
//  SCTRoomViewController.m
//  ScrapTalk
//
//  Created by yukatou on 2014/02/15.
//  Copyright (c) 2014年 yukatou. All rights reserved.
//

#import "SCTRoomViewController.h"
#import "UIView+move.h"
#import "SCTPhotoManager.h"
#import "JMImageCache.h"
#import "SVProgressHUD.h"

@interface SCTRoomViewController ()
@property (nonatomic, strong) AVCaptureStillImageOutput *imageOutput;
@property (strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property (strong, nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) UIView *previewView;
@property (strong, nonatomic) NSMutableArray *queuePhotoList;

@end

@implementation SCTRoomViewController
{
    BOOL _isInitialLoaded;
    BOOL _isExpand;
    CGRect _preExpandFrame;
    CGSize _imageSize;
    
    NSMutableArray *_imageViewList;
    UISwipeGestureRecognizer *_newPhotoSwipeGesture;
    UISwipeGestureRecognizer *_cancelSwipeGesture;
    UISwipeGestureRecognizer *_closeViewSwiprGesture;
    UISwipeGestureRecognizer *_showPickerViewSwiprGesture;
    AVCaptureVideoPreviewLayer *_captureVideoPreviewLayer;
    NSTimer *_checkTimer;
    NSTimer *_pushTimer;
}

static const NSInteger kCameraViewTag = 10;
static const CGFloat kCheckTimerSec = 1.5f;
static const CGFloat kPushTimerSec = 3.0f;


- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    if (_session) {
        // カメラ再開
        [_session startRunning];
    }
    
    if (_isInitialLoaded) {
        [self setCheckTimer];
        [self setPushTimer];
    }
    
    self.tabBarController.tabBar.hidden = YES;
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (_session) {
        // カメラ停止
        [_session stopRunning];
    }
    
    [self stopCheckTimer];
    [self stopPushTimer];
    
    self.tabBarController.tabBar.hidden = NO;
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (void) setCheckTimer
{
    _checkTimer = [NSTimer scheduledTimerWithTimeInterval:kCheckTimerSec
                                                   target:self
                                                 selector:@selector(checkUpdate)
                                                 userInfo:nil
                                                  repeats:YES];
}

- (void) stopCheckTimer
{
    if (_checkTimer && [_checkTimer isValid]) {
        [_checkTimer invalidate];
    }
}


- (void) setPushTimer
{
    _pushTimer = [NSTimer scheduledTimerWithTimeInterval:kPushTimerSec
                                                  target:self
                                                selector:@selector(pushImageView)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void) stopPushTimer
{
    if (_pushTimer && [_pushTimer isValid]) {
        [_pushTimer invalidate];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    CGRect deviceRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = deviceRect.size.height;
    CGFloat screenWidth = deviceRect.size.width;
    
    
    // ステータスバーの非表示
    [self prefersStatusBarHidden];
    
    _isExpand = NO;
    _isInitialLoaded = NO;
    _imageViewList = [[NSMutableArray alloc] init];
    _imageSize = CGSizeMake(screenWidth / 2.0f, screenHeight / 2.0f);
    
    // スワイプジェスチャー
    _newPhotoSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(newPhotoSwipeGesture:)];
    _newPhotoSwipeGesture.direction = UISwipeGestureRecognizerDirectionDown;
    _cancelSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(cancelSwipeGesture:)];
    _cancelSwipeGesture.direction = UISwipeGestureRecognizerDirectionUp;
    
    _closeViewSwiprGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(closeViewSwipeGesture:)];
    _closeViewSwiprGesture.direction = UISwipeGestureRecognizerDirectionRight;
    [_leftSideView addGestureRecognizer:_closeViewSwiprGesture];
    
    _showPickerViewSwiprGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showPickerViewSwipeGesture:)];
    _showPickerViewSwiprGesture.direction = UISwipeGestureRecognizerDirectionUp;
    [_footerView addGestureRecognizer:_showPickerViewSwiprGesture];
    
    // プレビュー用のビューを生成
    _previewView = [[UIImageView alloc] initWithFrame:CGRectMake(_imageSize.width, 0, _imageSize.width, _imageSize.height)];
    _previewView.userInteractionEnabled = YES;
    _previewView.tag = kCameraViewTag;
    
    // フッターを非表示
    _footerView.hidden = YES;
    
    [self setInitialPhotoImageList];
    
    
    _queuePhotoList = [[NSMutableArray alloc] init];
    
    // カメラのセットアップ
    [self setupAVCapture];
    
    
}

- (void)setInitialPhotoImageList
{
    [SVProgressHUD showWithStatus:@"Loading..."];
    
    [[SCTPhotoManager sharedInstance] requestPhotoList:^(NSArray *list, NSError *error) {
        
        [SVProgressHUD dismiss];
        
        if (error || list.count == 0) {
            [[[UIAlertView alloc] initWithTitle:@"エラー"
                                        message:@"取得に失敗しました"
                                       delegate:nil
                              cancelButtonTitle:nil
                              otherButtonTitles:@"了解", nil] show];
            return;
        }
        
        
        NSInteger i = 0;
        NSMutableArray *newList = [[NSMutableArray alloc] init];
        for (SCTPhotoItem *row in list) {
            if (i > 3) break;
            [newList addObject:row];
            i += 1;
        }
        
        CGRect rect;
        
        i = 0;
        for (SCTPhotoItem *item in [newList reverseObjectEnumerator]) {
            switch (i) {
                case 0:
                    rect = CGRectMake(0, 0, _imageSize.width, _imageSize.height);
                    break;
                case 1:
                    rect = CGRectMake(0, _imageSize.height, _imageSize.width, _imageSize.height);
                    break;
                case 2:
                    rect = CGRectMake(_imageSize.width, _imageSize.height, _imageSize.width, _imageSize.height);
                    break;
                case 3:
                    rect = CGRectMake(_imageSize.width, 0, _imageSize.width, _imageSize.height);
                    break;
            }
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:rect];
            [imageView setImageWithURL:item.photoUrl placeholder:nil];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView.clipsToBounds = YES;
            imageView.userInteractionEnabled = YES;
            [self.mainView addSubview:imageView];
            [_imageViewList addObject:imageView];
            i += 1;
        }

        // カメラ表示ジェスチャーを追加
        UIImageView  *imageView = [_imageViewList lastObject];
        [imageView addGestureRecognizer:_newPhotoSwipeGesture];
        
        // タイマー設定
        [self setCheckTimer];
        [self setPushTimer];
        
        _isInitialLoaded = YES;
    }];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    if ([touch.view isKindOfClass:[UIImageView class]] || touch.view.tag == kCameraViewTag) {
        [self.mainView bringSubviewToFront:touch.view];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    
    if (touch.view.tag == kCameraViewTag) {
        if (!_isExpand) {
            [self expandPreviewView];
        } else {
            [self contractPreviewView];
        }
    } else if ([touch.view isKindOfClass:[UIImageView class]]) {
        if (!_isExpand) {
            [self expandImageView:(UIImageView *)touch.view];
        } else {
            [self contractImageView:(UIImageView *)touch.view];
        }
    }
}

- (void)expandPreviewView
{
    CGRect tmpFrame = _previewView.frame;
    _previewView.frame = [[UIScreen mainScreen] bounds];
    _captureVideoPreviewLayer.frame = _previewView.bounds;
    _isExpand = YES;
    _preExpandFrame = tmpFrame;
}

- (void)expandImageView:(UIImageView *)imageView
{
    CGRect tmpFrame = imageView.frame;
    
    [UIView animateWithDuration:0.3f animations:^{
        imageView.frame = [[UIScreen mainScreen] bounds];
    } completion:^(BOOL finished) {
        if (finished) {
            _isExpand = YES;
            _preExpandFrame = tmpFrame;
        }
    }];
}

- (void)contractPreviewView
{
    _previewView.frame = _preExpandFrame;
    _captureVideoPreviewLayer.frame = _previewView.bounds;
    _isExpand = NO;
}


- (void)contractImageView:(UIImageView *)imageView
{
    [UIView animateWithDuration:0.3f animations:^{
        imageView.frame = _preExpandFrame;
    } completion:^(BOOL finished) {
        if (finished) _isExpand = NO;
    }];
}


- (void)newPhotoSwipeGesture:(UISwipeGestureRecognizer *)gesture
{
    // 拡大中はスワイプ処理させない
    if (_isExpand) return;
    
    [self stopPushTimer];
    
    
    [UIView animateWithDuration:0.3f animations:^{
        CGPoint point;
        for (UIImageView *imageView in _imageViewList) {
            if (imageView.frame.origin.x == 0 && imageView.frame.origin.y == 0) {
                point = CGPointMake(0, -_imageSize.height);
            } else if (imageView.frame.origin.x == _imageSize.width && imageView.frame.origin.y == 0) {
                point = CGPointMake(_imageSize.width, _imageSize.height);
            } else if (imageView.frame.origin.x == _imageSize.width && imageView.frame.origin.y == _imageSize.height) {
                point = CGPointMake(0, _imageSize.height);
            } else {
                point = CGPointMake(0, 0);
            }
            [imageView moveTo:CGPointMake(point.x, point.y)];
        }
        
    } completion:^(BOOL finished) {
        // プレビュー追加
        [_mainView addSubview:_previewView];
        
        // シャッターボタンを一番前に
        _footerView.hidden = NO;
        
        // 追加スワイプの削除
        [[_imageViewList lastObject] removeGestureRecognizer:_newPhotoSwipeGesture];
        
        // キャンセルスワイプ追加
        [[_imageViewList lastObject] addGestureRecognizer:_cancelSwipeGesture];
    }];
}

- (void)cancelSwipeGesture:(UISwipeGestureRecognizer *)gesture
{
    // カメラをしまう
    [_previewView removeFromSuperview];
    _footerView.hidden = YES;
    
    // キャンセルジェスチャーの削除
    [[_imageViewList lastObject] removeGestureRecognizer:_cancelSwipeGesture];
    
    [UIView animateWithDuration:0.2f animations:^{
        CGPoint point;
        for (UIImageView *imageView in _imageViewList) {
        
            if (imageView.frame.origin.x == 0 && imageView.frame.origin.y == 0) {
                point = CGPointMake(0, _imageSize.height);
            } else if (imageView.frame.origin.x == 0 && imageView.frame.origin.y == _imageSize.height) {
                point = CGPointMake(_imageSize.width, _imageSize.height);
            } else if (imageView.frame.origin.x == _imageSize.width && imageView.frame.origin.y == _imageSize.height) {
                point = CGPointMake(_imageSize.width, 0);
            } else {
                point = CGPointMake(0, 0);
            }
        
            [imageView moveTo:CGPointMake(point.x, point.y)];
        }
    } completion:^(BOOL finished) {
        [[_imageViewList lastObject] addGestureRecognizer:_newPhotoSwipeGesture];
        
        // タイマー再開
        [self setPushTimer];
    }];
}


- (void) closeViewSwipeGesture:(UIGestureRecognizer *)gesture
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void) showPickerViewSwipeGesture:(UIGestureRecognizer *)gesture
{
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.delegate = self;
    
    [pickerController setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [self presentViewController:pickerController animated:YES completion:nil];
}

- (void)addPhotoWithURL:(NSURL *)imageUrl
{
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(_imageSize.width, 0, _imageSize.width, _imageSize.height)];
    [imageView setImageWithURL:imageUrl placeholder:nil];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    imageView.userInteractionEnabled = YES;
    [self.mainView addSubview:imageView];
    [_imageViewList addObject:imageView];
    
    [imageView addGestureRecognizer:_newPhotoSwipeGesture];
}

- (void)addPhotoWithImage:(UIImage *)image
{
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(_imageSize.width, 0, _imageSize.width, _imageSize.height)];
    imageView.image = image;
    imageView.userInteractionEnabled = YES;
//    imageView.contentMode = UIViewContentModeScaleAspectFill;
//    imageView.clipsToBounds = YES;
    [self.mainView addSubview:imageView];
    [_imageViewList addObject:imageView];
    
    [imageView addGestureRecognizer:_newPhotoSwipeGesture];
}


- (void)setupAVCapture
{
    NSError *error = nil;
    
    // 入力と出力からキャプチャーセッションを作成
    self.session = [[AVCaptureSession alloc] init];
    
    // 正面に配置されているカメラを取得
    AVCaptureDevice *camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // カメラからの入力を作成し、セッションに追加
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:camera error:&error];
    [self.session addInput:self.videoInput];
    
    // 画像への出力を作成し、セッションに追加
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    [self.session addOutput:self.stillImageOutput];
    
    // キャプチャーセッションから入力のプレビュー表示を作成
    _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    _captureVideoPreviewLayer.frame = _previewView.bounds;
    _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    // レイヤーをViewに設定
    _previewView.layer.masksToBounds = YES;
    [_previewView.layer addSublayer:_captureVideoPreviewLayer];
    
    // セッション開始
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.session startRunning];
    });
}

// Camera切り替えアクション
- (IBAction)cameraToggleButtonPressed:(id)sender
{
    if ([[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 1)        //Only do if device has multiple cameras
    {
        NSError *error;
        AVCaptureDeviceInput *NewVideoInput;
        AVCaptureDevicePosition position = [[_videoInput device] position];
        // 今が通常カメラなら顔面カメラに
        if (position == AVCaptureDevicePositionBack)
        {
            NewVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self cameraWithPosition:AVCaptureDevicePositionFront] error:&error];
        }
        // 今が顔面カメラなら通常カメラに
        else if (position == AVCaptureDevicePositionFront)
        {
            NewVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self cameraWithPosition:AVCaptureDevicePositionBack] error:&error];
        }
        
        if (NewVideoInput != nil) {
            // beginConfiguration忘れずに！
            [_session beginConfiguration];            // 一度削除しないとダメっぽい
            [_session removeInput:_videoInput];
            if ([_session canAddInput:NewVideoInput]) {
                [_session addInput:NewVideoInput];
                _videoInput = NewVideoInput;
            }
            else {
                [_session addInput:_videoInput];
            }
            
            //Set the connection properties again
//            [self CameraSetOutputProperties];
            [_session commitConfiguration];
        }
    }
}
// カメラ切り替えの時に必要
- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) Position
{
    NSArray *Devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *Device in Devices) {
        if ([Device position] == Position) {
            return Device;
        }
    }
    return nil;
}

- (IBAction)pressShutterButton
{
    // ビデオ入力のAVCaptureConnectionを取得
    AVCaptureConnection *videoConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    
    if (videoConnection == nil) {
        return;
    }
    
    // ビデオ入力から画像を非同期で取得。ブロックで定義されている処理が呼び出され、画像データを引数から取得する
    [self.stillImageOutput
     captureStillImageAsynchronouslyFromConnection:videoConnection
     completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
         if (imageDataSampleBuffer == NULL) {
             return;
         }
         
         // 入力された画像データからJPEGフォーマットとしてデータを取得
         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
         
         [SVProgressHUD showWithStatus:@"Uploading..."];
         
         [[SCTPhotoManager sharedInstance] uploadPhoto:imageData completion:^(NSError *error) {
             
             [SVProgressHUD dismiss];
             
             // JPEGデータからUIImageを作成
             UIImage *image = [[UIImage alloc] initWithData:imageData];
             
             // アルバムに画像を保存
             UIImageWriteToSavedPhotosAlbum(image, self, nil, nil);
             
             // カメラをしまう
             [_previewView removeFromSuperview];
             _footerView.hidden = YES;
             
             // キャンセルジェスチャーを削除
             [[_imageViewList lastObject] removeGestureRecognizer:_cancelSwipeGesture];
                
             // 撮った写真を表示
             [self addPhotoWithImage:image];
             
             // タイマー設定
             [self setPushTimer];
         }];
     }];
}


- (void)checkUpdate
{
    [[SCTPhotoManager sharedInstance] getUploadedPhotoList:^(NSArray *list, NSError *error) {
        NSLog(@"update count = %lu", (unsigned long)list.count);
        if (error || list.count == 0) return;
        
        for (SCTPhotoItem *item in [list reverseObjectEnumerator]) {
            [_queuePhotoList addObject:item];
        }
    }];
}

- (void)pushImageView
{
    if (_queuePhotoList.count == 0) return;
    
    SCTPhotoItem *item = [_queuePhotoList firstObject];
    [_queuePhotoList removeObject:item];
 
    UIImageView *destroyImageView;
    for (UIImageView *imageView in _imageViewList) {
        if (imageView.frame.origin.x == 0 && imageView.frame.origin.y == 0) {
            destroyImageView = imageView;
            break;
        }
    }
    
    [UIView animateWithDuration:0.3f animations:^{
        CGPoint point;
        for (UIImageView *imageView in _imageViewList) {
            if (imageView.frame.origin.x == 0 && imageView.frame.origin.y == 0) {
                point = CGPointMake(0, -_imageSize.height);
            } else if (imageView.frame.origin.x == _imageSize.width && imageView.frame.origin.y == 0) {
                point = CGPointMake(_imageSize.width, _imageSize.height);
            } else if (imageView.frame.origin.x == _imageSize.width && imageView.frame.origin.y == _imageSize.height) {
                point = CGPointMake(0, _imageSize.height);
            } else {
                point = CGPointMake(0, 0);
            }
            [imageView moveTo:CGPointMake(point.x, point.y)];
        }
        
    } completion:^(BOOL finished) {
        if (destroyImageView) {
            [_imageViewList removeObject:destroyImageView];
        }
        
        [self addPhotoWithURL:item.photoUrl];
    }];
}


- (IBAction)tapImagePickerButton:(id)sender
{
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.delegate = self;
    
    [pickerController setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [self presentViewController:pickerController animated:YES completion:nil];
}

#pragma mark - UIImagePickerViewControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSLog(@"%@", info.debugDescription);
    UIImage *image = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
   
    [picker dismissViewControllerAnimated:YES completion:^{
        
        [SVProgressHUD showWithStatus:@"Uploading..."];
        [[SCTPhotoManager sharedInstance] uploadPhoto:UIImageJPEGRepresentation(image, 1.0) completion:^(NSError *error) {
            
            [SVProgressHUD dismiss];
            
            if (error) {
                [[[UIAlertView alloc] initWithTitle:@"エラー"
                                            message:@"アップロードに失敗しました"
                                           delegate:nil
                                  cancelButtonTitle:nil
                                  otherButtonTitles:@"了解", nil] show];   
                
                return;
            }
            
            // カメラをしまう
            [_previewView removeFromSuperview];
            _footerView.hidden = YES;
            
            // キャンセルジェスチャーを削除
            [[_imageViewList lastObject] removeGestureRecognizer:_cancelSwipeGesture];
            
            // 撮った写真を表示
            [self addPhotoWithImage:image];
            
            // タイマー設定
            [self setPushTimer];
        }];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}


// ステータスバーの非表示
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
