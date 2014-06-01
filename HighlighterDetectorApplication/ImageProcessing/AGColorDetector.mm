//
//  AGColorDetector.cpp
//  HighlighterDetector
//
//  Created by Aleksander Grzyb on 25/05/14.
//  Copyright (c) 2014 Aleksander Grzyb. All rights reserved.
//

#include "AGColorDetector.h"
#import <opencv2/opencv.hpp>

using namespace cv;
using namespace std;

void AGColorDetector::detectGreenColorInImage(cv::Mat& image, cv::Mat& outputImage)
{
    int lowHue = 40, highHue = 50;
    int lowSaturation = 0, highSaturation = 255;
    int lowValue = 0, highValue = 255;

    Mat blurredImage, hsvImage;
    medianBlur(image, blurredImage, 5);
    cvtColor(blurredImage, hsvImage, CV_BGR2HSV);
    inRange(hsvImage, Scalar(lowHue, lowSaturation, lowValue), Scalar(highHue, highSaturation, highValue), outputImage);
    morphologyEx(outputImage, outputImage, MORPH_OPEN, getStructuringElement(MORPH_RECT, cv::Size(9, 9)));
    cvtColor(outputImage, outputImage, CV_GRAY2BGR);
}

void AGColorDetector::findGreenColorAreaInImage(cv::Mat& image, cv::Mat& outputImage, std::vector<cv::Point>& greenArea)
{
    int treshold = 100;
    Mat processingImage;
    vector<vector<cv::Point>> contours;
    vector<Vec4i> hierarchy;
    cvtColor(image, processingImage, CV_BGR2GRAY);
    Canny(processingImage, processingImage, treshold, 2 * treshold);
    findContours(processingImage, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
    int maxContourArea = 0, maxContourIndex = 0;
    vector<vector<cv::Point>> hull(contours.size());
    for (int i = 0; i < contours.size(); i++) {
        convexHull(Mat(contours[i]), hull[i], false);
    }
    for(int i = 0; i < contours.size(); i++) {
        drawContours(outputImage, contours, i, Scalar(0, 255, 0), 2, 8, hierarchy, 0, cv::Point());
        drawContours(outputImage, hull, i, Scalar(0, 0, 255), 1, 8, vector<Vec4i>(), 0, cv::Point());
        if (maxContourArea < contourArea(hull[i], false)) {
            maxContourArea = contourArea(hull[i], false);
            maxContourIndex = i;
        }
    }
    Mat drawing = Mat::zeros(processingImage.size(), CV_8UC3);
    drawContours(outputImage, contours, maxContourIndex, Scalar(0, 255, 0), 2, 8, hierarchy, 0, cv::Point());
    greenArea = contours[maxContourIndex];
}

void AGColorDetector::findCornersOfGreenColorContour(std::vector<cv::Point>& greenColorContour, std::vector<cv::Point>& corners, int offset)
{
    int minX = greenColorContour[0].x, minY = greenColorContour[0].y, maxX = 0, maxY = 0;
    cv::Point middlePoint;
    for (int i = 0; i < greenColorContour.size(); i++) {
        if (minX > greenColorContour[i].x) {
            minX = greenColorContour[i].x;
        }
        if (minY > greenColorContour[i].y) {
            minY = greenColorContour[i].y;
        }
        if (maxX < greenColorContour[i].x) {
            maxX = greenColorContour[i].x;
        }
        if (maxY < greenColorContour[i].y) {
            maxY = greenColorContour[i].y;
        }
    }
    middlePoint.x = (minX + maxX) * 0.5; middlePoint.y = (minY + maxY) * 0.5;
    int topLeftPointIndex = 0, topRightPointIndex = 0, bottomRightPointIndex = 0, bottomLeftPointIndex = 0;
    int topLeftDistance = 0, topRightDistance = 0, bottomRightDistance = 0, bottomLeftDistance = 0;
    for (int i = 0; i < greenColorContour.size(); i++) {
        int currentDistance = sqrt(pow(middlePoint.x - greenColorContour[i].x, 2.0) + pow(middlePoint.y - greenColorContour[i].y, 2.0));
        if (greenColorContour[i].x <= middlePoint.x && greenColorContour[i].y <= middlePoint.y) {
            if (topLeftDistance < currentDistance) {
                topLeftDistance = currentDistance;
                topLeftPointIndex = i;
            }
        }
        else if (greenColorContour[i].x > middlePoint.x && greenColorContour[i].y <= middlePoint.y) {
            if (topRightDistance < currentDistance) {
                topRightDistance = currentDistance;
                topRightPointIndex = i;
            }
        }
        else if (greenColorContour[i].x > middlePoint.x && greenColorContour[i].y > middlePoint.y) {
            if (bottomRightDistance < currentDistance) {
                bottomRightDistance = currentDistance;
                bottomRightPointIndex = i;
            }
        }
        else {
            if (bottomLeftDistance < currentDistance) {
                bottomLeftDistance = currentDistance;
                bottomLeftPointIndex = i;
            }
        }
    }
    cv::Point topLeftPoint, topRightPoint, bottomRightPoint, bottomLeftPoint;
    if (greenColorContour[topLeftPointIndex].x < greenColorContour[bottomLeftPointIndex].x) {
        topLeftPoint.x = greenColorContour[topLeftPointIndex].x;
        bottomLeftPoint.x = greenColorContour[topLeftPointIndex].x;
    }
    else {
        topLeftPoint.x = greenColorContour[bottomLeftPointIndex].x;
        bottomLeftPoint.x = greenColorContour[bottomLeftPointIndex].x;
    }
    
    if (greenColorContour[topLeftPointIndex].y < greenColorContour[topRightPointIndex].y) {
        topLeftPoint.y = greenColorContour[topLeftPointIndex].y;
        topRightPoint.y = greenColorContour[topLeftPointIndex].y;
    }
    else {
        topLeftPoint.y = greenColorContour[topRightPointIndex].y;
        topRightPoint.y = greenColorContour[topRightPointIndex].y;
    }
    
    if (greenColorContour[bottomRightPointIndex].x > greenColorContour[topRightPointIndex].x) {
        bottomRightPoint.x = greenColorContour[bottomRightPointIndex].x;
        topRightPoint.x = greenColorContour[bottomRightPointIndex].x;
    }
    else {
        bottomRightPoint.x = greenColorContour[topRightPointIndex].x;
        topRightPoint.x = greenColorContour[topRightPointIndex].x;
    }
    
    if (greenColorContour[bottomRightPointIndex].y > greenColorContour[bottomLeftPointIndex].y) {
        bottomRightPoint.y = greenColorContour[bottomRightPointIndex].y;
        bottomLeftPoint.y = greenColorContour[bottomRightPointIndex].y;
    }
    else {
        bottomRightPoint.y = greenColorContour[bottomLeftPointIndex].y;
        bottomLeftPoint.y = greenColorContour[bottomLeftPointIndex].y;
    }
    
    topLeftPoint.x -= offset; topLeftPoint.y -= 2 * offset; topRightPoint.x += offset; topRightPoint.y -= 2 * offset;
    bottomRightPoint.x += offset; bottomRightPoint.y += 2 * offset; bottomLeftPoint.x -= offset; bottomLeftPoint.y += 2 * offset;
    
    corners.push_back(topLeftPoint);
    corners.push_back(topRightPoint);
    corners.push_back(bottomRightPoint);
    corners.push_back(bottomLeftPoint);
}












