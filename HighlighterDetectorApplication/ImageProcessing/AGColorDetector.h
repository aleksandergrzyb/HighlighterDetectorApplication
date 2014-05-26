//
//  AGColorDetector.h
//  HighlighterDetector
//
//  Created by Aleksander Grzyb on 25/05/14.
//  Copyright (c) 2014 Aleksander Grzyb. All rights reserved.
//

#ifndef __HighlighterDetector__AGColorDetector__
#define __HighlighterDetector__AGColorDetector__

#import <opencv2/opencv.hpp>

class AGColorDetector {
public:
    void detectGreenColorInImage(cv::Mat& image, cv::Mat& outputImage);
    void findGreenColorAreaInImage(cv::Mat& image, cv::Mat& outputImage, std::vector<cv::Point>& greenArea);
    void findCornersOfGreenColorContour(std::vector<cv::Point>& greenColorContour, std::vector<cv::Point>& corners, int offset);
};

#endif /* defined(__HighlighterDetector__AGColorDetector__) */
