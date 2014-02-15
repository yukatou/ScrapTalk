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

@interface SCTRoomViewController ()
@property (nonatomic, strong) AVCaptureStillImageOutput *imageOutput;

@property (strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property (strong, nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) UIView *previewView;
@end

@implementation SCTRoomViewController
{
    BOOL _isExpand;
    CGRect _preExpandFrame;
    CGSize _imageSize;
    
    NSMutableArray *_imageViewList;
    UISwipeGestureRecognizer *_newPhotoSwipeGesture;
    UISwipeGestureRecognizer *_cancelSwipeGesture;
    UISwipeGestureRecognizer *_closeViewSwiprGesture;
//    AVCaptureVideoPreviewLayer *_previewLayer;
    AVCaptureVideoPreviewLayer *_captureVideoPreviewLayer;
}

static const NSInteger kCameraViewTag = 10;


- (void)viewWillAppear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = YES;
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = NO;
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    CGRect deviceRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = deviceRect.size.height;
    CGFloat screenWidth = deviceRect.size.width;
    
    _isExpand = NO;
    _imageViewList = [[NSMutableArray alloc] init];
    _imageSize = CGSizeMake(screenWidth / 2.0f, screenHeight / 2.0f);
    
    // スワイプジェスチャー
    _newPhotoSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(newPhotoSwipeGesture:)];
    _newPhotoSwipeGesture.direction = UISwipeGestureRecognizerDirectionDown;
    _cancelSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(cancelSwipeGesture:)];
    _cancelSwipeGesture.direction = UISwipeGestureRecognizerDirectionUp;
    
    _closeViewSwiprGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(closeViewSwipeGesture:)];
    _closeViewSwiprGesture.direction = UISwipeGestureRecognizerDirectionRight;
    [_sideView addGestureRecognizer:_closeViewSwiprGesture];
    
    // プレビュー用のビューを生成
    _previewView = [[UIImageView alloc] initWithFrame:CGRectMake(_imageSize.width, 0, _imageSize.width, _imageSize.height)];
    _previewView.userInteractionEnabled = YES;
    _previewView.tag = kCameraViewTag;
    
    // フッターを非表示
    _footerView.hidden = YES;
    
    
    SCTPhotoManager *photoManager = [[SCTPhotoManager alloc] init];
    [photoManager requestPhotoList:^(NSArray *list, NSError *error) {
        
        NSInteger i = 0;
        CGRect rect;
        
        for (SCTPhotoItem *row in list) {
            
            if (i > 3) break;
            
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
            [imageView setImageWithURL:row.photoUrl placeholder:nil];
//            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:row.photoUrl]];
//            imageView.image = image;
            imageView.userInteractionEnabled = YES;
            [self.mainView addSubview:imageView];
            [_imageViewList addObject:imageView];
            
            i += 1;
        }

        UIImageView  *imageView = [_imageViewList lastObject];
        [imageView addGestureRecognizer:_newPhotoSwipeGesture];
    }];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    _captureVideoPreviewLayer.frame = [[UIScreen mainScreen] bounds];
    _previewView.layer.frame = [[UIScreen mainScreen] bounds];
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
    _captureVideoPreviewLayer.frame = _preExpandFrame;
    _previewView.layer.frame = _preExpandFrame;
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
    
    // カメラのセットアップ
    [self setupAVCapture];
    
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
    CGPoint point;
    
    // カメラをしまう
    [_previewView removeFromSuperview];
    _footerView.hidden = YES;
    
    // キャンセルジェスチャーの削除
    [[_imageViewList lastObject] removeGestureRecognizer:_cancelSwipeGesture];
    
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
        
        [UIView animateWithDuration:0.2f animations:^{
            [imageView moveTo:CGPointMake(point.x, point.y)];
        } completion:^(BOOL finished) {
            [[_imageViewList lastObject] addGestureRecognizer:_newPhotoSwipeGesture];
        }];
    }
}


- (void) closeViewSwipeGesture:(UIGestureRecognizer *)gesture
{
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)addPhotoWithImage:(UIImage *)image
{
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(_imageSize.width, 0, _imageSize.width, _imageSize.height)];
    imageView.image = image;
    imageView.userInteractionEnabled = YES;
//    imageView.contentMode = UIViewContentModeScaleAspect;
//    [imageView setClipsToBounds:YES];
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
     }];
}

@end
