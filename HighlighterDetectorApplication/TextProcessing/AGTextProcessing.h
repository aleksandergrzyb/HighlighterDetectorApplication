//
//  AGTextProcessing.h
//  HighlighterDetectorApplication
//
//  Created by Aleksander Grzyb on 01/06/14.
//  Copyright (c) 2014 Aleksander Grzyb. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AGTextProcessing;

@protocol AGTextProcessingDelegate <NSObject>

- (void)textProcessing:(AGTextProcessing *)textProcessing recognizedText:(NSString *)text inImage:(UIImage *)image;

@end

@interface AGTextProcessing : NSObject

- (void)recognizeTextInImage:(UIImage *)image;

@property (weak, nonatomic) id <AGTextProcessingDelegate> delegate;

@end
