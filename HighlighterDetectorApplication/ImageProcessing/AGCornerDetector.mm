//
//  CornerDetector.cpp
//  HighlighterDetector
//
//  Created by Aleksander Grzyb on 24/05/14.
//  Copyright (c) 2014 Aleksander Grzyb. All rights reserved.
//

#include "AGCornerDetector.h"

using namespace cv;
using namespace std;

#define BIGGEST_AREA 6000.0f
#define A_COEFFICIENT 0
#define B_COEFFICIENT 1
#define LEFT_SIDE 0
#define RIGHT_SIDE 1

double AGCornerDetector::angle(cv::Point point1, cv::Point point2, cv::Point point3)
{
    double dx1 = point1.x - point3.x;
    double dy1 = point1.y - point3.y;
    double dx2 = point2.x - point3.x;
    double dy2 = point2.y - point3.y;
    return (dx1 * dx2 + dy1 * dy2) / sqrt((dx1 * dx1 + dy1 * dy1) * (dx2 * dx2 + dy2 * dy2) + 1e-10);
}

void AGCornerDetector::findSquaresInImage(cv::Mat &image, vector<vector<cv::Point> > &squares)
{
    // blur will enhance edge detection
    Mat blurred;
    medianBlur(image, blurred, 9);
    
    Mat gray0(blurred.size(), CV_8U), gray;
    vector<vector<cv::Point>> contours;
    
    // find squares in every color plane of the image
    for (int c = 0; c < 3; c++) {
        int ch[] = {c, 0};
        mixChannels(&blurred, 1, &gray0, 1, ch, 1);
        
        // try several threshold levels
        const int threshold_level = 2;
        for (int l = 0; l < threshold_level; l++) {
            // Use Canny instead of zero threshold level!
            // Canny helps to catch squares with gradient shading
            if (l == 0) {
                Canny(gray0, gray, 10, 20, 3); //
                
                // Dilate helps to remove potential holes between edge segments
                dilate(gray, gray, Mat(), cv::Point(-1,-1));
            }
            else {
                gray = gray0 >= (l+1) * 255 / threshold_level;
            }
            
            // Find contours and store them in a list
            findContours(gray, contours, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
            
            // Test contours
            vector<cv::Point> approx;
            for (size_t i = 0; i < contours.size(); i++) {
                // approximate contour with accuracy proportional
                // to the contour perimeter
                approxPolyDP(Mat(contours[i]), approx, arcLength(Mat(contours[i]), true)*0.02, true);
                
                // Note: absolute value of an area is used because
                // area may be positive or negative - in accordance with the
                // contour orientation
                if (approx.size() == 4 && fabs(contourArea(Mat(approx))) > 1000 && isContourConvex(Mat(approx))) {
                    double maxCosine = 0;
                    for (int j = 2; j < 5; j++){
                        double cosine = fabs(angle(approx[j%4], approx[j-2], approx[j-1]));
                        maxCosine = MAX(maxCosine, cosine);
                    }
                    if (maxCosine < 0.3) {
                        squares.push_back(approx);
                    }
                }
            }
        }
    }
}

cv::Point AGCornerDetector::calculatePointAfterCrop(vector<double>& lineCoefficientVector, cv::Point pointToMove, bool side, int distance)
{
    cv::Point newPoint;
    double aCoefficient = lineCoefficientVector[A_COEFFICIENT], bCoefficient = lineCoefficientVector[B_COEFFICIENT], a = 0.0, b = 0.0, c = 0.0;
    double delta = 0.0f, solutionOne = 0.0f, solutionTwo = 0.0f;
    a = 1 + pow(aCoefficient, 2.0);
    b = 2 * aCoefficient * bCoefficient - 2 * (double)pointToMove.y * aCoefficient - 2 * (double)pointToMove.x;
    c = pow((double)pointToMove.x, 2) + pow(bCoefficient, 2) - 2 * (double)pointToMove.y * bCoefficient + pow((double)pointToMove.y, 2) - pow(distance, 2);
    
    delta = sqrt(pow(b, 2) - 4 * a * c);
    
    solutionOne = (-b + delta) / (2 * a);
    solutionTwo = (-b - delta) / (2 * a);
    
    if (side == LEFT_SIDE) {
        if (solutionOne > pointToMove.x) {
            newPoint.x = solutionOne;
        }
        else {
            newPoint.x = solutionTwo;
        }
    }
    if (side == RIGHT_SIDE) {
        if (solutionOne < pointToMove.x) {
            newPoint.x = solutionOne;
        }
        else {
            newPoint.x = solutionTwo;
        }
    }
    
    newPoint.y = aCoefficient * newPoint.x + bCoefficient;
    
    return newPoint;
}

void AGCornerDetector::calculateLineEquationFromPoints(vector<cv::Point> &pointVector, vector<double>& lineCoefficientVector)
{
    double aCoefficient = 0, bCoefficient = 0, numerator = pointVector[1].y - pointVector[0].y, denominator = pointVector[1].x - pointVector[0].x;
    aCoefficient = numerator / denominator;
    bCoefficient = (double)pointVector[0].y - aCoefficient * (double)pointVector[0].x;
    lineCoefficientVector.push_back(aCoefficient); lineCoefficientVector.push_back(bCoefficient);
}

void AGCornerDetector::findCornersInImage(Mat& image, vector<cv::Point>& imageCorners)
{
    // Resizing image to 10 % of original image and saving size in insance veriables.
    Mat resizedImage, grayImage;
    resize(image, resizedImage, cv::Size(0,0), 0.1, 0.1);
    double widthRatio = image.size().width / resizedImage.size().width;
    double heightRatio = image.size().height / resizedImage.size().height;
    
    // Convering to 8 bit color space
    cvtColor(resizedImage, grayImage, CV_BGRA2GRAY);
    
    // Removing noise from image.
    GaussianBlur(grayImage, grayImage, cv::Size(7, 7), 2.0, 2.0);
    
    // Performing Canny edge detection with treshold of 50 (experimental).
    float tresh = 50.0f;
    Canny(grayImage, grayImage, tresh, 2 * tresh, 3);
    
    // Creating data structures.
    vector<vector<cv::Point>> contours, hull(contours.size()), contoursTwo;
    vector<Vec4i> hierarchy, hierarchyTwo;
    cv::Point topLeftPoint, topRightPoint, bottomLeftPoint, bottomRightPoint;
    bool cornersOutside = false;
    
    // Finding contours of image after Canny edge detection.
    findContours(grayImage, contours, hierarchy, CV_RETR_CCOMP, CV_CHAIN_APPROX_NONE, cv::Point(0, 0));
    
    // Checking if any contours were found.
    if (!contours.empty()) {
        
        // Creating convex hull around contours.
        for(int i = 0; i < contours.size(); i++) {
            if (!contours.empty() && !hull.empty()) {
                convexHull(Mat(contours[i]), hull[i], false);
            }
        }
        
        // Here we are drawing contours on new image, because during experimenting I found that performing again the same procedure results with better receipt shape recognition.
        Mat drawing = Mat::zeros(grayImage.size(), CV_8UC3);
        for(int i = 0; i < contours.size(); i++) {
            drawContours(drawing, contours, i, Scalar(255, 255, 0), 1, 8, hierarchy, 0, cv::Point());
        }
        
        // Morphology operation. Linking any gaps in contours.
        Mat element = getStructuringElement(MORPH_RECT, cv::Size(3, 3), cv::Point(1,1));
        dilate(drawing, drawing, element, cv::Point(-1,-1), 1);
        erode(drawing, drawing, element, cv::Point(-1,-1), 1);
        
        // Second procedure of finding contours and creating convex hull around contours.
        cvtColor(drawing, drawing, CV_BGR2GRAY);
        findContours(drawing, contoursTwo, hierarchyTwo, CV_RETR_CCOMP, CV_CHAIN_APPROX_NONE, cv::Point(0, 0));
        vector<vector<cv::Point>> hullTwo(contoursTwo.size());
        for(int i = 0; i < contoursTwo.size(); i++) {
            convexHull(Mat(contoursTwo[i]), hullTwo[i], false);
        }
        
        // Below is algorithm I invented to determine corners of receipt. Algorithm find four corners of receipt. I don't exactly remember my idea back then (idea was evolving during experimentation) but in general algorithm looks on the coordinates of convex hull and tries to determine corners of receipt.
        vector<int> upDownHull;
        bool downDetected = false, upDetected = false, upDownDetected = false;
        double sizeOfContour = 0;
        int index = 0;
        for (int i = 0; i < hullTwo.size(); i++) {
            if (sizeOfContour < contourArea(hullTwo[i], false)) {
                sizeOfContour = contourArea(hullTwo[i], false);
                index = i;
            }
            downDetected = false, upDetected = false, upDownDetected = false;
            for (int a = 0; a < hullTwo[i].size(); a++) {
                if (hullTwo[i][a].x == 1) {
                    upDetected = true;
                }
                if (hullTwo[i][a].x == drawing.size().width - 2) {
                    downDetected = true;
                }
                if (upDetected && downDetected && !upDownDetected) {
                    upDownHull.push_back(i);
                    upDownDetected = true;
                }
            }
        }
        if (upDownHull.size() == 2) {
            for (int i = 0; i < hullTwo[upDownHull[0]].size(); i++) {
                if (hullTwo[upDownHull[0]][i].x == 1) {
                    topLeftPoint.x = 0;
                    topLeftPoint.y = hullTwo[upDownHull[0]][i].y;
                }
                if (hullTwo[upDownHull[0]][i].x == drawing.size().width - 2) {
                    bottomLeftPoint.x = drawing.size().width;
                    bottomLeftPoint.y = hullTwo[upDownHull[0]][i].y;
                }
            }
            for (int i = 0; i < hullTwo[upDownHull[1]].size(); i++) {
                if (hullTwo[upDownHull[1]][i].x == 1) {
                    topRightPoint.x = 0;
                    topRightPoint.y = hullTwo[upDownHull[1]][i].y;
                }
                if (hullTwo[upDownHull[1]][i].x == drawing.size().width - 2) {
                    bottomRightPoint.x = drawing.size().width;
                    bottomRightPoint.y = hullTwo[upDownHull[1]][i].y;
                }
            }
            if (topRightPoint.y > topLeftPoint.y) {
                int tempY = topRightPoint.y;
                topRightPoint.y = topLeftPoint.y;
                topLeftPoint.y = tempY;
                
                tempY = bottomRightPoint.y;
                bottomRightPoint.y = bottomLeftPoint.y;
                bottomLeftPoint.y = tempY;
            }
            
            if (bottomLeftPoint.x > bottomRightPoint.x) {
                bottomLeftPoint.x = bottomRightPoint.x;
            }
            else {
                bottomRightPoint.x = bottomLeftPoint.x;
            }
            if (topLeftPoint.x > topRightPoint.x) {
                topRightPoint.x = topLeftPoint.x;
            }
            else {
                topLeftPoint.x = topRightPoint.x;
            }
            
            if (bottomLeftPoint.y < topLeftPoint.y) {
                bottomLeftPoint.y = topLeftPoint.y;
            }
            else {
                topLeftPoint.y = bottomLeftPoint.y;
            }
            if (topRightPoint.y < bottomRightPoint.y) {
                topRightPoint.y = bottomRightPoint.y;
            }
            else {
                bottomRightPoint.y = topRightPoint.y;
            }
            
            cornersOutside = true;
        }
        else if (upDownHull.size() == 1) {
            for (int i = 0; i < hullTwo[upDownHull[0]].size(); i++) {
                if (hullTwo[upDownHull[0]][i].x == 1) {
                    topLeftPoint.x = 0;
                    topLeftPoint.y = hullTwo[upDownHull[0]][i].y;
                }
                if (hullTwo[upDownHull[0]][i].x == drawing.size().width - 2) {
                    bottomLeftPoint.x = drawing.size().width;
                    bottomLeftPoint.y = hullTwo[upDownHull[0]][i].y;
                }
            }
            int leftSide = 0;
            int rightSide = 0;
            for (int i = 0; i < hullTwo.size(); i++) {
                for (int a = 0; a < hullTwo[i].size(); a++) {
                    if (bottomLeftPoint.y < hullTwo[i][a].y) {
                        leftSide++;
                    }
                    else {
                        rightSide++;
                    }
                }
            }
            if (leftSide > rightSide) {
                topRightPoint.x = 0;
                topRightPoint.y = grayImage.size().height;
                bottomRightPoint.x = grayImage.size().width;
                bottomRightPoint.y = grayImage.size().height;
            }
            else {
                topRightPoint.x = 0;
                topRightPoint.y = 0;
                bottomRightPoint.x = grayImage.size().width;
                bottomRightPoint.y = 0;
            }
            if (topRightPoint.y > topLeftPoint.y) {
                int tempY = topRightPoint.y;
                topRightPoint.y = topLeftPoint.y;
                topLeftPoint.y = tempY;
                
                tempY = bottomRightPoint.y;
                bottomRightPoint.y = bottomLeftPoint.y;
                bottomLeftPoint.y = tempY;
            }
            
            if (bottomLeftPoint.x > bottomRightPoint.x) {
                bottomLeftPoint.x = bottomRightPoint.x;
            }
            else {
                bottomRightPoint.x = bottomLeftPoint.x;
            }
            if (topLeftPoint.x > topRightPoint.x) {
                topRightPoint.x = topLeftPoint.x;
            }
            else {
                topLeftPoint.x = topRightPoint.x;
            }
            
            if (bottomLeftPoint.y < topLeftPoint.y) {
                bottomLeftPoint.y = topLeftPoint.y;
            }
            else {
                topLeftPoint.y = bottomLeftPoint.y;
            }
            if (topRightPoint.y < bottomRightPoint.y) {
                topRightPoint.y = bottomRightPoint.y;
            }
            else {
                bottomRightPoint.y = topRightPoint.y;
            }
            cornersOutside = true;
        }
        else {
            std::vector<cv::Point> biggestContour;
            biggestContour = hullTwo[index];
            
            // Case where all corners are outside of screen.
            if (contourArea(biggestContour, false) < BIGGEST_AREA) {
                topLeftPoint.x = 0;
                topLeftPoint.y = grayImage.size().height;
                topRightPoint.x = 0;
                topRightPoint.y = 0;
                bottomLeftPoint.x = grayImage.size().width;
                bottomLeftPoint.y = grayImage.size().height;
                bottomRightPoint.x = grayImage.size().width;
                bottomRightPoint.y = 0;
                cornersOutside = true;
            }
            else {
                double xSum = 0.0;
                double ySum = 0.0;
                
                for (int i = 0; i < biggestContour.size(); i ++) {
                    xSum += biggestContour[i].x;
                    ySum += biggestContour[i].y;
                }
                
                double xMean = xSum / biggestContour.size();
                double yMean = ySum / biggestContour.size();
                
                double tlDistance = 0.0;
                int tlIndex = 0;
                double trDistance = 0.0;
                int trIndex = 0;
                double blDistance = 0.0;
                int blIndex = 0;
                double brDistance = 0.0;
                int brIndex = 0;
                for (int i = 0; i < biggestContour.size(); i ++) {
                    double distance = sqrt(pow(fabs(biggestContour[i].y - yMean), 2) + pow(fabs(biggestContour[i].x - xMean), 2));
                    if (biggestContour[i].x < xMean && biggestContour[i].y < yMean) {
                        if (tlDistance < distance) {
                            tlDistance = distance;
                            tlIndex = i;
                        }
                    }
                    else if (biggestContour[i].x > xMean && biggestContour[i].y < yMean) {
                        if (trDistance < distance) {
                            trDistance = distance;
                            trIndex = i;
                        }
                    }
                    else if (biggestContour[i].x < xMean && biggestContour[i].y > yMean) {
                        if (blDistance < distance) {
                            blDistance = distance;
                            blIndex = i;
                        }
                    }
                    else if (biggestContour[i].x > xMean && biggestContour[i].y > yMean) {
                        if (brDistance < distance) {
                            brDistance = distance;
                            brIndex = i;
                        }
                    }
                }
                topLeftPoint.x = biggestContour[blIndex].x;
                topLeftPoint.y = biggestContour[blIndex].y;
                topRightPoint.x = biggestContour[tlIndex].x;
                topRightPoint.y = biggestContour[tlIndex].y;
                bottomLeftPoint.x = biggestContour[brIndex].x;
                bottomLeftPoint.y = biggestContour[brIndex].y;
                bottomRightPoint.x = biggestContour[trIndex].x;
                bottomRightPoint.y = biggestContour[trIndex].y;
            }
        }
    }
    else {
        topLeftPoint.x = 0;
        topLeftPoint.y = grayImage.size().height;
        topRightPoint.x = 0;
        topRightPoint.y = 0;
        bottomLeftPoint.x = grayImage.size().width;
        bottomLeftPoint.y = grayImage.size().height;
        bottomRightPoint.x = grayImage.size().width;
        bottomRightPoint.y = 0;
    }
    
    topLeftPoint.x *= widthRatio; topLeftPoint.y *= heightRatio;
    topRightPoint.x *= widthRatio; topRightPoint.y *= heightRatio;
    bottomLeftPoint.x *= widthRatio; bottomLeftPoint.y *= heightRatio;
    bottomRightPoint.x *= widthRatio; bottomRightPoint.y *= heightRatio;
    
    imageCorners.push_back(topLeftPoint); imageCorners.push_back(topRightPoint); imageCorners.push_back(bottomLeftPoint); imageCorners.push_back(bottomRightPoint);
}

void AGCornerDetector::sortCorners(vector<cv::Point>& corners)
{
    int topLeftPointIndex = 0, bottomRightPointIndex = 0, topRightPointIndex = 0, bottomLeftPointIndex = 0;
    int middleX = 0, middleY = 0;
    int minX = corners[0].x, maxX = 0, minY = corners[0].y, maxY = 0;
    for (int i = 0; i < corners.size(); i++) {
        if (corners[i].x > maxX) {
            maxX = corners[i].x;
        }
        if (corners[i].x < minX) {
            minX = corners[i].x;
        }
        if (corners[i].y > maxY) {
            maxY = corners[i].y;
        }
        if (corners[i].y < minY) {
            minY = corners[i].y;
        }
    }
    middleX = (minX + maxX) * 0.5;
    middleY = (minY + maxY) * 0.5;
    for (int i = 0; i < corners.size(); i++) {
        if (corners[i].x <= middleX && corners[i].y <= middleY) {
            topLeftPointIndex = i;
        }
        else if (corners[i].x > middleX && corners[i].y <= middleY) {
            topRightPointIndex = i;
        }
        else if (corners[i].x > middleX && corners[i].y > middleY) {
            bottomRightPointIndex = i;
        }
        else {
            bottomLeftPointIndex = i;
        }
    }
    cv::Point topLeftPoint = corners[topLeftPointIndex], topRightPoint = corners[topRightPointIndex], bottomRightPoint = corners[bottomRightPointIndex], bottomLeftPoint = corners[bottomLeftPointIndex];
    corners.clear();
    corners.push_back(topLeftPoint); corners.push_back(topRightPoint); corners.push_back(bottomRightPoint); corners.push_back(bottomLeftPoint);
}

void AGCornerDetector::cropDetectedCornersInImage(Mat& image, vector<cv::Point>& corners, int distance)
{
    this->sortCorners(corners);
    vector<double> lineCoefficientVector;
    vector<cv::Point> pointsVector;
    cv::Point newPoint, middlePointNew, movePointNew, middlePoint;
    middlePoint.x = (corners[BOTTOM_RIGHT_POINT].x - corners[TOP_LEFT_POINT].x) * 0.5;
    middlePoint.y = (corners[BOTTOM_RIGHT_POINT].y - corners[TOP_LEFT_POINT].y) * 0.5;
    // TOP LEFT
    middlePointNew.x = (image.size().height - middlePoint.y);
    middlePointNew.y = middlePoint.x;
    movePointNew.x = (image.size().height - corners[TOP_LEFT_POINT].y);
    movePointNew.y = corners[TOP_LEFT_POINT].x;
    pointsVector.push_back(middlePoint);
    pointsVector.push_back(corners[TOP_LEFT_POINT]);
    calculateLineEquationFromPoints(pointsVector, lineCoefficientVector);
    newPoint = this->calculatePointAfterCrop(lineCoefficientVector, corners[TOP_LEFT_POINT], LEFT_SIDE, distance);
    corners[TOP_LEFT_POINT].x = newPoint.x; corners[TOP_LEFT_POINT].y = newPoint.y;
    // TOP RIGHT
    pointsVector.clear();
    lineCoefficientVector.clear();
    pointsVector.push_back(middlePoint);
    pointsVector.push_back(corners[TOP_RIGHT_POINT]);
    newPoint.x = 0.0; newPoint.y = 0.0;
    calculateLineEquationFromPoints(pointsVector, lineCoefficientVector);
    newPoint = this->calculatePointAfterCrop(lineCoefficientVector, corners[TOP_RIGHT_POINT], RIGHT_SIDE, distance);
    corners[TOP_RIGHT_POINT].x = newPoint.x; corners[TOP_RIGHT_POINT].y = newPoint.y;
    // BOTTOM LEFT
    pointsVector.clear();
    lineCoefficientVector.clear();
    pointsVector.push_back(middlePoint);
    pointsVector.push_back(corners[BOTTOM_LEFT_POINT]);
    newPoint.x = 0.0; newPoint.y = 0.0;
    calculateLineEquationFromPoints(pointsVector, lineCoefficientVector);
    newPoint = this->calculatePointAfterCrop(lineCoefficientVector, corners[BOTTOM_LEFT_POINT], LEFT_SIDE, distance);
    corners[BOTTOM_LEFT_POINT].x = newPoint.x; corners[BOTTOM_LEFT_POINT].y = newPoint.y;
    // BOTTOM RIGHT
    pointsVector.clear();
    lineCoefficientVector.clear();
    pointsVector.push_back(middlePoint);
    pointsVector.push_back(corners[BOTTOM_RIGHT_POINT]);
    newPoint.x = 0.0; newPoint.y = 0.0;
    calculateLineEquationFromPoints(pointsVector, lineCoefficientVector);
    newPoint = this->calculatePointAfterCrop(lineCoefficientVector, corners[BOTTOM_RIGHT_POINT], RIGHT_SIDE, distance);
    corners[BOTTOM_RIGHT_POINT].x = newPoint.x; corners[BOTTOM_RIGHT_POINT].y = newPoint.y;
}





