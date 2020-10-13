//
//  CVpixelBuffer2UIImage16bit.h
//  TrueDepthStreamer
//  Copyright © 2018年 Apple. All rights reserved.
//


#ifndef CVpixelBuffer2UIImage16bit_h
#define CVpixelBuffer2UIImage16bit_h

#import <UIKit/UIKit.h>

typedef void(^TakePhotoSuccess)(void);

@interface PhotoView : UIView

- (instancetype)initWithFrame:(CGRect)frame withPositionDevice:(BOOL)isBack withTakePhotoSuccess:(TakePhotoSuccess)takePhotoSuccess;

- (void)startRunning;
- (UIImage*)depthBufferToImage:(CVPixelBufferRef) pixelBufffer;
- (void)stopRunning;
@end
#endif /* CVpixelBuffer2UIImage16bit_h */
