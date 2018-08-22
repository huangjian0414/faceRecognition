//
//  ViewController.m
//  faceRecognitionTest
//
//  Created by huangjian on 2018/8/16.
//  Copyright © 2018年 huangjian. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
API_AVAILABLE(ios(10.0))
@interface ViewController ()<AVCaptureMetadataOutputObjectsDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>
@property (strong,nonatomic)AVCaptureDevice * device;
@property (strong,nonatomic)AVCaptureDeviceInput * input;
@property (strong,nonatomic)AVCaptureMetadataOutput * output;
@property (strong,nonatomic)AVCaptureVideoDataOutput *videoOutput;
@property (strong,nonatomic)AVCapturePhotoOutput *photoOutput;
@property (strong,nonatomic)AVCaptureSession * session;
@property (strong,nonatomic)AVCaptureVideoPreviewLayer * preview;

@property (nonatomic,weak)UIView *faceView;
@property (nonatomic,weak)UIView *leftEyeView;
@property (nonatomic,weak)UIView *leftEye;
@property (nonatomic,weak)UIView *mouth;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setConfiger];
}
//AVCaptureVideoDataOutput获取实时图像,这个代理方法的回调频率很快,几乎与手机屏幕的刷新频率一样快
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    UIImage *constantImage = [self imageFromSampleBuffer:sampleBuffer];
    [self addFaceFrameWithImage:constantImage];
    
}
//CMSampleBufferRef转UIImage
-(UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    // 为媒体数据设置一个CMSampleBuffer的Core Video图像缓存对象
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // 锁定pixel buffer的基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    // 得到pixel buffer的基地址
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    // 得到pixel buffer的行字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // 得到pixel buffer的宽和高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    // 创建一个依赖于设备的RGB颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // 用抽样缓存的数据创建一个位图格式的图形上下文(graphics context)对象
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // 根据这个位图context中的像素数据创建一个Quartz image对象
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    // 释放context和颜色空间
    CGContextRelease(context); CGColorSpaceRelease(colorSpace);
    // 用Quartz image创建一个UIImage对象image
    UIImage *image = [UIImage imageWithCGImage:quartzImage scale:1 orientation:UIImageOrientationUp];
    // 释放Quartz image对象
    CGImageRelease(quartzImage);
    return (image);
}

//人脸定位,添加框架
- (void)addFaceFrameWithImage:(UIImage *)images{
    //注意坐标的换算，CIFaceFeature计算出来的坐标的坐标系的Y轴与iOS的Y轴是相反的,需要自行处理

    CIContext * context = [CIContext contextWithOptions:nil ];
    CIImage * image = [CIImage imageWithCGImage:images.CGImage];
    float factor = self.view.bounds.size.width/images.size.width;
    image = [image imageByApplyingTransform:CGAffineTransformMakeScale(factor, factor)];
    NSDictionary * param = [NSDictionary dictionaryWithObject:CIDetectorAccuracyLow forKey:CIDetectorAccuracy];
    CIDetector * faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:context options:param];
    NSArray * detectResult = [faceDetector featuresInImage:image];
    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    for(CIFaceFeature* faceObject in detectResult){
        CGRect modifiedFaceBounds = faceObject.bounds;
        modifiedFaceBounds.origin.y = images.size.height-faceObject.bounds.size.height -faceObject.bounds.origin.y;
        // 标出脸部
        CGFloat faceWidth = faceObject.bounds.size.width;
        
//        if (self.faceView) {
//            self.faceView.center=CGPointMake(self.faceView.frame.origin.x+self.faceView.frame.size.width/2, self.view.bounds.size.height-self.faceView.frame.origin.y - self.faceView.bounds.size.height+self.faceView.frame.size.height/2);
//
//        }else
//        {
            UIView* faceView = [[UIView alloc] initWithFrame:faceObject.bounds];
            faceView.frame = CGRectMake(faceView.frame.origin.x, self.view.bounds.size.height-faceView.frame.origin.y - faceView.bounds.size.height, faceView.frame.size.width, faceView.frame.size.height);
            faceView.layer.borderWidth = 1;
            faceView.layer.borderColor = [[UIColor redColor] CGColor];
            [self.view addSubview:faceView];
       // }
        // 标出左眼
        if(faceObject.hasLeftEyePosition) {
//            if (self.leftEyeView) {
//                self.leftEyeView.center=CGPointMake(faceObject.leftEyePosition.x-faceWidth*0.15+faceWidth*0.3/2, self.view.bounds.size.height-(faceObject.leftEyePosition.y-faceWidth*0.15)-faceWidth*0.3+faceWidth*0.3/2);
//            }else
//            {
            UIImageView *leftEyeView=[[UIImageView alloc]initWithFrame:CGRectMake(faceObject.leftEyePosition.x-faceWidth*0.15,
                                                                                  self.view.bounds.size.height-(faceObject.leftEyePosition.y-faceWidth*0.15)-faceWidth*0.3, faceWidth*0.3, faceWidth*0.3)];
            leftEyeView.image=[UIImage imageNamed:@"1111"];
//                UIView* leftEyeView = [[UIView alloc] initWithFrame:
//                                       CGRectMake(faceObject.leftEyePosition.x-faceWidth*0.15,
//                                                  self.view.bounds.size.height-(faceObject.leftEyePosition.y-faceWidth*0.15)-faceWidth*0.3, faceWidth*0.3, faceWidth*0.3)];
               // [leftEyeView setBackgroundColor:[[UIColor blueColor] colorWithAlphaComponent:0.3]];
                //            [leftEyeView setCenter:faceFeature.leftEyePosition];
                leftEyeView.layer.cornerRadius = faceWidth*0.15;
                [self.view  addSubview:leftEyeView];
               // self.leftEye=leftEyeView;
   //         }
        }
        // 标出右眼
        if(faceObject.hasRightEyePosition) {
//            if (self.leftEye) {
//                self.leftEye.center=CGPointMake(faceObject.rightEyePosition.x-faceWidth*0.15+faceWidth*0.3/2, self.view.bounds.size.height-(faceObject.rightEyePosition.y-faceWidth*0.15)-faceWidth*0.3+faceWidth*0.3/2);
//
//            }else
//            {
            UIImageView* leftEye = [[UIImageView alloc] initWithFrame:
                               CGRectMake(faceObject.rightEyePosition.x-faceWidth*0.15,
                                          self.view.bounds.size.height-(faceObject.rightEyePosition.y-faceWidth*0.15)-faceWidth*0.3, faceWidth*0.3, faceWidth*0.3)];
            leftEye.image=[UIImage imageNamed:@"2222"];
//                UIView* leftEye = [[UIView alloc] initWithFrame:
//                                   CGRectMake(faceObject.rightEyePosition.x-faceWidth*0.15,
//                                              self.view.bounds.size.height-(faceObject.rightEyePosition.y-faceWidth*0.15)-faceWidth*0.3, faceWidth*0.3, faceWidth*0.3)];
//                [leftEye setBackgroundColor:[[UIColor blueColor] colorWithAlphaComponent:0.3]];
                leftEye.layer.cornerRadius = faceWidth*0.15;
                [self.view  addSubview:leftEye];
                //self.leftEye=leftEye;
          //  }
        }
        // 标出嘴部
        if(faceObject.hasMouthPosition) {
//            if (self.mouth) {
//                self.mouth.center=CGPointMake(faceObject.mouthPosition.x-faceWidth*0.2+faceWidth*0.4/2, self.view.bounds.size.height-(faceObject.mouthPosition.y-faceWidth*0.2)-faceWidth*0.4+faceWidth*0.4/2);
//            }else
//            {
            UIImageView* mouth = [[UIImageView alloc] initWithFrame:
                             CGRectMake(faceObject.mouthPosition.x-faceWidth*0.2,
                                        self.view.bounds.size.height-(faceObject.mouthPosition.y-faceWidth*0.2)-faceWidth*0.4, faceWidth*0.4, faceWidth*0.4)];
             mouth.image=[UIImage imageNamed:@"3333"];
//                UIView* mouth = [[UIView alloc] initWithFrame:
//                                 CGRectMake(faceObject.mouthPosition.x-faceWidth*0.2,
//                                            self.view.bounds.size.height-(faceObject.mouthPosition.y-faceWidth*0.2)-faceWidth*0.4, faceWidth*0.4, faceWidth*0.4)];
//                [mouth setBackgroundColor:[[UIColor greenColor] colorWithAlphaComponent:0.3]];
            
                mouth.layer.cornerRadius = faceWidth*0.2;
                [self.view  addSubview:mouth];
                //self.mouth=mouth;
         //   }
        }
        
    }
}

-(void)setConfiger
{
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    _input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:nil];
    
    _output = [[AVCaptureMetadataOutput alloc]init];
    
    if (@available(iOS 10.0, *)) {
        _photoOutput=[[AVCapturePhotoOutput alloc]init];
    }
    _videoOutput=[[AVCaptureVideoDataOutput alloc]init];
    [_videoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    //[_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    _session = [[AVCaptureSession alloc]init];
    [_session setSessionPreset:AVCaptureSessionPresetHigh];
    if ([_session canAddInput:_input])
    {
        [_session addInput:_input];
    }
    if ([_session canAddOutput:_output])
    {
        [_session addOutput:_output];
    }
//    if ([_session canAddOutput:_photoOutput]) {
//        [_session addOutput:_photoOutput];
//    }
    if ([_session canAddOutput:_videoOutput]) {
        [_session addOutput:_videoOutput];
    }
    //设置像素格式
    [_videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    
    if (TARGET_IPHONE_SIMULATOR != 1 || TARGET_OS_IPHONE != 1) {
        _output.metadataObjectTypes = @[AVMetadataObjectTypeFace];
    }
    // Preview
    _preview =[AVCaptureVideoPreviewLayer layerWithSession:_session];
    _preview.videoGravity =AVLayerVideoGravityResizeAspectFill;
    [_preview setFrame:self.view.layer.bounds];
    [self.view.layer insertSublayer:_preview atIndex:0];
    [_session startRunning];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
