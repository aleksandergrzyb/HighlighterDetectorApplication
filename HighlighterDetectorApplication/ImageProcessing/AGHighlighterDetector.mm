//
//  AGHighlighterDetector.m
//  HighlighterDetectorApplication
//
//  Created by Aleksander Grzyb on 26/05/14.
//  Copyright (c) 2014 Aleksander Grzyb. All rights reserved.
//

#import "AGHighlighterDetector.h"
#import "UIImage+OpenCV.h"
#import "AGColorDetector.h"
#import "AGDrawing.h"
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
//    AGDrawing::drawCornersInImage(matImage, greenAreaCorners);
    Mat greenHighlighterArea = matImage(cv::Rect(greenAreaCorners[TOP_LEFT_POINT].x, greenAreaCorners[TOP_LEFT_POINT].y, greenAreaCorners[TOP_RIGHT_POINT].x - greenAreaCorners[TOP_LEFT_POINT].x, greenAreaCorners[BOTTOM_LEFT_POINT].y - greenAreaCorners[TOP_LEFT_POINT].y));
    
    
    cvtColor(greenHighlighterArea, greenHighlighterArea, CV_BGRA2GRAY);
    medianBlur(greenHighlighterArea, greenHighlighterArea, 3);
//    adaptiveThreshold(greenHighlighterArea, greenHighlighterArea, 255, CV_ADAPTIVE_THRESH_GAUSSIAN_C, CV_THRESH_BINARY, 91, 3);
//    morphologyEx(greenHighlighterArea, greenHighlighterArea, MORPH_OPEN, getStructuringElement(MORPH_RECT, cv::Size(1, 1)));
//    medianBlur(greenHighlighterArea, greenHighlighterArea, 3);
//    UIImage *output = [AGMatToUIImageConverter UIImageFromMat:matImage];
    
    threshold(greenHighlighterArea, greenHighlighterArea, 125, 255, THRESH_BINARY);
    morphologyEx(greenHighlighterArea, greenHighlighterArea, MORPH_CLOSE, getStructuringElement(MORPH_RECT, cv::Size(1, 1)));
    
    cv::Mat totalImage(cv::Size(greenHighlighterArea.size().width + 20.0f, greenHighlighterArea.size().height + 20.0f), greenHighlighterArea.type());
    totalImage.setTo(cv::Scalar(255, 255, 255));
    greenHighlighterArea.copyTo(totalImage(cv::Rect(10.0f, 10.0f, greenHighlighterArea.size().width, greenHighlighterArea.size().height)));
    
    UIImage *output = [UIImage imageWithMat:totalImage andImageOrientation:UIImageOrientationUp];
    return output;
    
    
//    UIImage *output = [UIImage imageWithMat:totalImage andImageOrientation:UIImageOrientationUp];
//    return output
//    NSLog(@"Output UIImage width - %f, height - %f and orientation: %ld", output.size.width, output.size.height, output.imageOrientation);
    
//    UIImageWriteToSavedPhotosAlbum(output, nil, nil, nil);
    ;
}

@end
