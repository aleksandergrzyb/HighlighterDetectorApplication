//
//  UIImage+OpenCV.h
//  HighlighterDetectorApplication
//
//  Created by Aleksander Grzyb on 26/05/14.
//  Copyright (c) 2014 Aleksander Grzyb. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (OpenCV)

+ (UIImage *)imageWithMat:(const cv::Mat&)mat andImageOrientation:(UIImageOrientation)orientation;
+ (UIImage *)imageWithMat:(const cv::Mat&)mat andDeviceOrientation:(UIDeviceOrientation)orientation;
- (cv::Mat)convertToMat;

@end
