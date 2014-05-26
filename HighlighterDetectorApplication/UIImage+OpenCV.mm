//
//  UIImage+OpenCV.m
//  HighlighterDetectorApplication
//
//  Created by Aleksander Grzyb on 26/05/14.
//  Copyright (c) 2014 Aleksander Grzyb. All rights reserved.
//

#import "UIImage+OpenCV.h"

@implementation UIImage (OpenCV)

- (cv::Mat)convertToMat
{
    CGImageRef imageRef = self.CGImage;
    
    const int srcWidth        = (int)CGImageGetWidth(imageRef);
    const int srcHeight       = (int)CGImageGetHeight(imageRef);
    
    CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
    CFDataRef rawData = CGDataProviderCopyData(dataProvider);
    
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    cv::Mat rgbaContainer(srcHeight, srcWidth, CV_8UC4);
    CGContextRef context = CGBitmapContextCreate(rgbaContainer.data,
                                                 srcWidth,
                                                 srcHeight,
                                                 8,
                                                 4 * srcWidth,
                                                 colorSpace,
                                                 kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Big);
    
    CGContextDrawImage(context, CGRectMake(0, 0, srcWidth, srcHeight), imageRef);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    CFRelease(rawData);
    
    cv::Mat t;
    cv::cvtColor(rgbaContainer, t, CV_RGBA2BGRA);
    
    return t;
}

+ (UIImage *)imageWithMat:(const cv::Mat&)mat andDeviceOrientation:(UIDeviceOrientation)orientation
{
    UIImageOrientation imgOrientation = UIImageOrientationUp;
    
    switch (orientation)
    {
        case UIDeviceOrientationLandscapeLeft:
            imgOrientation = UIImageOrientationUp; break;
            
        case UIDeviceOrientationLandscapeRight:
            imgOrientation = UIImageOrientationDown; break;
            
        case UIDeviceOrientationPortraitUpsideDown:
            imgOrientation = UIImageOrientationRightMirrored; break;
            
        default:
        case UIDeviceOrientationPortrait:
            imgOrientation = UIImageOrientationRight; break;
    };
    
    return [UIImage imageWithMat:mat andImageOrientation:imgOrientation];
}

+ (UIImage *)imageWithMat:(const cv::Mat&)mat andImageOrientation:(UIImageOrientation)orientation
{
    cv::Mat rgbaView;
    
    if (mat.channels() == 3)
    {
        cv::cvtColor(mat, rgbaView, CV_BGR2RGBA);
    }
    else if (mat.channels() == 4)
    {
        cv::cvtColor(mat, rgbaView, CV_BGRA2RGBA);
    }
    else if (mat.channels() == 1)
    {
        cv::cvtColor(mat, rgbaView, CV_GRAY2RGBA);
    }
    
    NSData *data = [NSData dataWithBytes:rgbaView.data length:rgbaView.elemSize() * rgbaView.total()];
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    CGBitmapInfo bmInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big;
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(rgbaView.cols,                                 //width
                                        rgbaView.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * rgbaView.elemSize(),                       //bits per pixel
                                        rgbaView.step.p[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        bmInfo,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef scale:1 orientation:orientation];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

@end
