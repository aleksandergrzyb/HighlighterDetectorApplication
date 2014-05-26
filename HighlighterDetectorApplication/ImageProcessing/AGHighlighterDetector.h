//
//  AGHighlighterDetector.h
//  HighlighterDetectorApplication
//
//  Created by Aleksander Grzyb on 26/05/14.
//  Copyright (c) 2014 Aleksander Grzyb. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AGHighlighterDetector : NSObject

- (UIImage *)processImageToFindGreenHighlighterArea:(UIImage *)image;

@end
