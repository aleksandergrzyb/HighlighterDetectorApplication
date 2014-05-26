//
//  AGMatToUIImageConverter.h
//  Highlighter
//
//  Created by Aleksander Grzyb on 05/05/14.
//  Copyright (c) 2014 Aleksander Grzyb. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AGMatToUIImageConverter : NSObject

/**
 This class is responsible for converting UIImage to Mat and vice versa. There is one problem regarding this conversion.
 Sometimes image after conversion has bad orientation. To fix this you need to uncomment one line in UIImageFromMat: method.
 */

+ (UIImage *)UIImageFromMat:(cv::Mat)cvMat;
+ (cv::Mat)matFromUIImage:(UIImage *)image;

@end
