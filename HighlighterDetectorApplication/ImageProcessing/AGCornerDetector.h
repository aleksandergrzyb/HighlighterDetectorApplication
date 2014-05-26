//
//  CornerDetector.h
//  HighlighterDetector
//
//  Created by Aleksander Grzyb on 24/05/14.
//  Copyright (c) 2014 Aleksander Grzyb. All rights reserved.
//

#ifndef __HighlighterDetector__CornerDetector__
#define __HighlighterDetector__CornerDetector__

#import <opencv2/opencv.hpp>

#define TOP_LEFT_POINT 0
#define TOP_RIGHT_POINT 1
#define BOTTOM_RIGHT_POINT 2
#define BOTTOM_LEFT_POINT 3

class AGCornerDetector {
    void calculateLineEquationFromPoints(std::vector<cv::Point>& pointVector, std::vector<double>& lineCoefficientVector);
    double angle(cv::Point point1, cv::Point point2, cv::Point point3);
    cv::Point calculatePointAfterCrop(std::vector<double>& lineCoefficientVector, cv::Point pointToMove, bool side, int distance);
    void sortCorners(std::vector<cv::Point>& corners);
public:
    void findCornersInImage(cv::Mat& image, std::vector<cv::Point>& corners);
    void findSquaresInImage(cv::Mat& image, std::vector<std::vector<cv::Point>>& squares);
    void cropDetectedCornersInImage(cv::Mat& image, std::vector<cv::Point>& corners, int distance);
};

#endif /* defined(__HighlighterDetector__CornerDetector__) */
