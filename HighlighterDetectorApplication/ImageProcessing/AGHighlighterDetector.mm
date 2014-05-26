//
//  AGHighlighterDetector.m
//  HighlighterDetectorApplication
//
//  Created by Aleksander Grzyb on 26/05/14.
//  Copyright (c) 2014 Aleksander Grzyb. All rights reserved.
//

#import "AGHighlighterDetector.h"
#import "AGMatToUIImageConverter.h"
#import "UIImage+OpenCV.h"
#import "AGColorDetector.h"
#import "AGCornerDetector.h"
#include <opencv2/opencv.hpp>

using namespace cv;
using namespace std;

@implementation AGHighlighterDetector

- (UIImage *)processImageToFindGreenHighlighterArea:(UIImage *)image
{
    cv::Mat matImage = [image convertToMat];
    vector<cv::Point> corners;
    AGCornerDetector cornerDetector;
    cornerDetector.findCornersInImage(matImage, corners);
    cornerDetector.cropDetectedCornersInImage(matImage, corners, 100);
    cv::Mat croppedImage = matImage(cv::Rect(corners[TOP_LEFT_POINT].x, corners[TOP_LEFT_POINT].y, corners[TOP_RIGHT_POINT].x - corners[TOP_LEFT_POINT].x, corners[BOTTOM_LEFT_POINT].y - corners[TOP_LEFT_POINT].y));
    
    // Detecting green color on sheet of paper
    AGColorDetector colorDetector;
    Mat hsvImage;
    vector<cv::Point> greenArea, greenAreaCorners;
    colorDetector.detectGreenColorInImage(croppedImage, hsvImage);
    colorDetector.findGreenColorAreaInImage(hsvImage, hsvImage, greenArea);
    colorDetector.findCornersOfGreenColorContour(greenArea, greenAreaCorners, 10);
    
    // Adding offset caused by cropping image earlier
    for (int i = 0; i < greenAreaCorners.size(); i++) {
        greenAreaCorners[i].x += corners[TOP_LEFT_POINT].x;
        greenAreaCorners[i].y += corners[TOP_LEFT_POINT].y;
    }
    
    // Drawing corners of green highlighter
    //    AGDrawing::drawCornersInImage(sheetImage, greenAreaCorners);
    Mat greenHighlighterArea = matImage(cv::Rect(greenAreaCorners[TOP_LEFT_POINT].x, greenAreaCorners[TOP_LEFT_POINT].y, greenAreaCorners[TOP_RIGHT_POINT].x - greenAreaCorners[TOP_LEFT_POINT].x, greenAreaCorners[BOTTOM_LEFT_POINT].y - greenAreaCorners[TOP_LEFT_POINT].y));
//    UIImage *output = [AGMatToUIImageConverter UIImageFromMat:matImage];
    UIImage *output = [UIImage imageWithMat:greenHighlighterArea andImageOrientation:image.imageOrientation];
    return output;
}

@end
