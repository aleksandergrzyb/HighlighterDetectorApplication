//
//  AGMatToUIImageConverter.m
//  Highlighter
//
//  Created by Aleksander Grzyb on 05/05/14.
//  Copyright (c) 2014 Aleksander Grzyb. All rights reserved.
//

#import "AGMatToUIImageConverter.h"

@implementation AGMatToUIImageConverter

// Methods found on the internet. Only modification I made was regarding orientation of the image after convertion. Sometimes image was rotated (90 or -90 degrees). To change this behaviour we need to switch cols for rows and vice versa when converting to cv::Mat.

+ (UIImage *)UIImageFromMat:(cv::Mat)mat withOrientation:(UIImageOrientation)imageOrientation
{
    NSData *data = [NSData dataWithBytes:mat.data
                                  length:mat.elemSize() * mat.total()];
    CGColorSpaceRef colorSpace;
    if (mat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    }
    else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    CGImageRef imageRef = CGImageCreate(mat.cols, mat.rows, 8, 8 * mat.elemSize(), mat.step[0], colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
    
    // Orientation dependent code below
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:imageOrientation];
    
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    return finalImage;
}

+ (cv::Mat)matFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = 0.0f;
    CGFloat rows = 0.0f;
    
//    NSLog(@"w: %zu", CGImageGetWidth(image.CGImage));
//    NSLog(@"h: %zu", CGImageGetHeight(image.CGImage));
    // Orientation dependent code below.
    if  (image.imageOrientation == UIImageOrientationLeft || image.imageOrientation == UIImageOrientationRight) {
        cols = image.size.height;
        rows = image.size.width;
    }
    else {
        cols = image.size.width;
        rows = image.size.height;
    }

    cv::Mat cvMat(rows, cols, CV_8UC4);
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data, cols, rows, 8, cvMat.step[0], colorSpace, kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault);
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    return cvMat;
}

@end
