//
//  AGTextProcessing.m
//  HighlighterDetectorApplication
//
//  Created by Aleksander Grzyb on 01/06/14.
//  Copyright (c) 2014 Aleksander Grzyb. All rights reserved.
//

#import "AGTextProcessing.h"
#import <TesseractOCR/TesseractOCR.h>

@interface AGTextProcessing()
@property (strong, nonatomic) Tesseract *tesseract;
@end

@implementation AGTextProcessing

#pragma mark -
#pragma mark Getters

- (Tesseract *)tesseract
{
    if (!_tesseract) {
        _tesseract = [[Tesseract alloc] initWithLanguage:@"pol"];
        [_tesseract setVariableValue:@"\"/\\(),*.-_%0123456789aąbcćdeęfghijklmnńoópqrsśtuvwxyzżźAĄBCĆDEĘFGHIJKLMNŃOÓPQRSŚTUVWXYZŻŹ" forKey:@"tessedit_char_whitelist"];
        [_tesseract setVariableValue:@"3" forKey:@"tessedit_pageseg_mode"];
    }
    return _tesseract;
}

#pragma mark -
#pragma mark Public Methods

- (void)recognizeTextInImage:(UIImage *)image
{
    [self.tesseract setImage:image];
    [self.tesseract recognize];
    NSString *recognizedText = [self.tesseract recognizedText];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate textProcessing:self recognizedText:recognizedText inImage:image];
    });
}

@end
