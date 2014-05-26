//
//  AGDrawing.h
//  HighlighterDetector
//
//  Created by Aleksander Grzyb on 25/05/14.
//  Copyright (c) 2014 Aleksander Grzyb. All rights reserved.
//

#ifndef __HighlighterDetector__AGDrawing__
#define __HighlighterDetector__AGDrawing__

#include <opencv2/opencv.hpp>

class AGDrawing {    
public:
    void static drawCornersInImage(cv::Mat& image, std::vector<cv::Point>& imageCorners);
    void static drawSquaresInImage(cv::Mat& image, std::vector<std::vector<cv::Point>>& squares);
};

#endif /* defined(__HighlighterDetector__AGDrawing__) */
