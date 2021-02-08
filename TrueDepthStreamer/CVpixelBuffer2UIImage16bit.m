//
//  CVpixelBuffer2UIImage16bit.m
//  TrueDepthStreamer
//  Copyright © 2018年 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "CVpixelBuffer2UIImage16bit.h"
@interface PhotoView()<AVCapturePhotoCaptureDelegate>

@property (nonatomic, retain) AVCaptureSession *session;
@property (nonatomic, retain) AVCaptureDeviceInput *input;
@property (nonatomic, retain) AVCaptureDevice *device;
@property (nonatomic, retain) AVCapturePhotoOutput *imageOutput;
@property (nonatomic, retain) AVCaptureVideoPreviewLayer *preview;
@property (nonatomic, retain) AVCapturePhotoSettings *outputSettings;

@end

@implementation PhotoView
{
    TakePhotoSuccess _takePhotoSuccess;
}

- (instancetype)initWithFrame:(CGRect)frame withPositionDevice:(BOOL)isBack withTakePhotoSuccess:(TakePhotoSuccess)takePhotoSuccess {
    if (self = [super initWithFrame:frame]) {
        _takePhotoSuccess = takePhotoSuccess;
        [self initCameraInPosition:isBack];
    }
    return self;
}


- (void)initCameraInPosition:(BOOL)isBack {
    self.session = [AVCaptureSession new];
    [self.session beginConfiguration];
    [self.session setSessionPreset:AVCaptureSessionPresetPhoto];
    
    _device = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInTrueDepthCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
    
    
    NSError *error;
    
    self.input = [[AVCaptureDeviceInput alloc] initWithDevice:self.device error:&error];
    if ([self.session canAddInput:self.input]) {
        [self.session addInput:self.input];
    }
    
    self.imageOutput = [[AVCapturePhotoOutput alloc] init];
    
    NSDictionary *setDic = @{AVVideoCodecKey:AVVideoCodecTypeJPEG};
    _outputSettings = [AVCapturePhotoSettings photoSettingsWithFormat:setDic];
    [self.imageOutput setPhotoSettingsForSceneMonitoring:_outputSettings];
    [self.session addOutput:self.imageOutput];
    //一定要放在session之后
    self.imageOutput.depthDataDeliveryEnabled = true;
    
    self.preview = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.preview setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self.preview setFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    [self.layer addSublayer:self.preview];
    [self.session commitConfiguration];
    
    [self.session startRunning];
    
    UIButton *takeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    takeButton.frame = CGRectMake((self.frame.size.width - 70)/2, self.frame.size.height - 100, 70, 70);
    takeButton.layer.masksToBounds = YES;
    takeButton.layer.cornerRadius = takeButton.frame.size.height/2;
    takeButton.backgroundColor = [UIColor colorWithWhite:1 alpha:0.7];
    [takeButton setTitle:@"拍照" forState:UIControlStateNormal];
    takeButton.titleLabel.font = [UIFont systemFontOfSize:16];
    takeButton.titleLabel.numberOfLines = 0;
    [takeButton setTitleColor:[UIColor colorWithRed:40.2f/255 green:180.2f/255 blue:247.2f/255 alpha:0.9] forState:UIControlStateNormal];
    [takeButton addTarget:self action:@selector(takePhoto) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:takeButton];
    
}

- (void)takePhoto {
    NSDictionary *setDic = @{AVVideoCodecKey:AVVideoCodecTypeJPEG};
    AVCapturePhotoSettings *outputSettings = [AVCapturePhotoSettings photoSettingsWithFormat:setDic];
    outputSettings.depthDataDeliveryEnabled = true;
    [self.imageOutput capturePhotoWithSettings:outputSettings delegate:self];
}

#pragma mark AVCapturePhotoCaptureDelegate
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(nullable NSError *)error NS_AVAILABLE_IOS(11_0)
{
    UIImage *depth = [self depthBufferToImage:photo.depthData.depthDataMap];
    UIImageWriteToSavedPhotosAlbum(depth, self, nil, nil);
    
    UIImage *color = [[UIImage alloc] initWithData:photo.fileDataRepresentation];
    UIImageWriteToSavedPhotosAlbum(color, self, nil, nil);
}
/*
 #define kBitsPerComponent (16)
 #define kBitsPerPixel (16)
 #define kPixelChannelCount (2)//每一行的像素点占用的字节数，每个像素点的ARGB四个通道各占8个bit
 
 typedef unsigned char byte;
 
 -(UIImage*)depthBufferToImage:(CVPixelBufferRef) pixelBufffer{
 CVPixelBufferLockBaseAddress(pixelBufffer, 0);// 锁定pixel buffer的基地址
 void * baseAddress = CVPixelBufferGetBaseAddress(pixelBufffer);// 得到pixel buffer的基地址
 size_t width = CVPixelBufferGetWidth(pixelBufffer);
 //size_t width = 640;
 //size_t height = 480;
 size_t height = CVPixelBufferGetHeight(pixelBufffer);
 
 float16_t *array = (float16_t *) malloc(width*height*sizeof(float16_t));
 memcpy(array, baseAddress, width*height*sizeof(float16_t));
 for (int j = 0; j<height; j++) {
 for (int i =0; i<width; i++) {
 unsigned long index = j * width + i;
 float16_t depth =((float16_t *)baseAddress)[index];
 array[ index ] = (uint16_t)depth * 1000;
 }
 }
 
 //CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();// 创建一个依赖于设备的RGB颜色空间
 CGColorSpaceRef grayColorSpace = CGColorSpaceCreateDeviceGray();
 CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, array, width*height*kPixelChannelCount, NULL);
 
 
 CGImageRef cgImage = CGImageCreate(width,
 height,
 kBitsPerComponent,
 kBitsPerPixel,
 width * kPixelChannelCount,
 grayColorSpace,
 kCGBitmapFloatComponents | kCGBitmapByteOrder16Little,
 provider,
 NULL,
 false,
 kCGRenderingIntentDefault);//这个是建立一个CGImageRef对象的函数
 
 UIImage *image = [UIImage imageWithCGImage:cgImage];
 CGImageRelease(cgImage);  //类似这些CG...Ref 在使用完以后都是需要release的，不然内存会有问题
 CGDataProviderRelease(provider);
 CGColorSpaceRelease(grayColorSpace);
 NSData* imageData = UIImagePNGRepresentation(image);
 UIImage* pngImage = [UIImage imageWithData:imageData];
 
 free(array);
 CVPixelBufferUnlockBaseAddress(pixelBufffer, 0);   // 解锁pixel buffer
 
 return pngImage;
 }*/

#define kBitsPerComponent (8)
#define kBitsPerPixel (32)
#define kPixelChannelCount (4)//每一行的像素点占用的字节数，每个像素点的ARGB四个通道各占8个bit

typedef unsigned char byte;

-(UIImage*)depthBufferToImage:(CVPixelBufferRef) pixelBufffer{
    CVPixelBufferLockBaseAddress(pixelBufffer, 0);// 锁定pixel buffer的基地址
    void * baseAddress = CVPixelBufferGetBaseAddress(pixelBufffer);// 得到pixel buffer的基地址
    size_t width = CVPixelBufferGetWidth(pixelBufffer);
    size_t height = CVPixelBufferGetHeight(pixelBufffer);
    
    byte *array = (byte *) malloc(width*height*4);
    
    for (int j = 0; j<height; j++) {
        for (int i =0; i<width; i++) {
            int index = j * width + i;
            //ARGB
//        lxk: change one channel depth to channel 4
            int depth =((__fp16 *)baseAddress)[index] * 10000;
            array[ index*kPixelChannelCount + 1] = (byte)(depth/255);
            array[ index*kPixelChannelCount + 2] = (byte)(depth%255);
            array[ index*kPixelChannelCount + 3] = 0;
            array[ index*kPixelChannelCount + 0] = 0;
        }
    }
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();// 创建一个依赖于设备的RGB颜色空间
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, array, width*height*kPixelChannelCount, NULL);
    
    
    CGImageRef cgImage = CGImageCreate(width,
                                       height,
                                       kBitsPerComponent,
                                       kBitsPerPixel,
                                       width * kPixelChannelCount,
                                       rgbColorSpace,
                                       kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrderDefault,
                                       provider,
                                       NULL,
                                       true,
                                       kCGRenderingIntentDefault);//这个是建立一个CGImageRef对象的函数
    
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);  //类似这些CG...Ref 在使用完以后都是需要release的，不然内存会有问题
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(rgbColorSpace);
    NSData* imageData = UIImagePNGRepresentation(image);
    UIImage* pngImage = [UIImage imageWithData:imageData];
    
    free(array);
    CVPixelBufferUnlockBaseAddress(pixelBufffer, 0);   // 解锁pixel buffer
    
    return pngImage;
}

- (void)startRunning{
    [_session startRunning];
}

- (void)stopRunning{
    [_session stopRunning];
}

@end
