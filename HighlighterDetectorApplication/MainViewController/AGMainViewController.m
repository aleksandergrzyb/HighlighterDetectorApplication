//
//  AGMainViewController.m
//  HighlighterDetectorApplication
//
//  Created by Aleksander Grzyb on 26/05/14.
//  Copyright (c) 2014 Aleksander Grzyb. All rights reserved.
//

#import "AGMainViewController.h"
#import "AGImagePickerManager.h"
#import "AGHighlighterDetector.h"
#import "UIImage+FixOrientation.h"
#import "AGTextProcessing.h"

@interface AGMainViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, AGTextProcessingDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *recognizedText;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) AGHighlighterDetector *highlighterDetector;
@property (strong, nonatomic) AGTextProcessing *textProcessing;
@end

@implementation AGMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configureImageView];
    [self updateScrollViewContentSize];
}

#pragma mark -
#pragma mark Getters

- (AGHighlighterDetector *)highlighterDetector
{
    if (!_highlighterDetector) {
        _highlighterDetector = [[AGHighlighterDetector alloc] init];
    }
    return _highlighterDetector;
}

- (AGTextProcessing *)textProcessing
{
    if (!_textProcessing) {
        _textProcessing = [[AGTextProcessing alloc] init];
        _textProcessing.delegate = self;
    }
    return _textProcessing;
}

#pragma mark -
#pragma mark Private Methods

- (void)showImagePickerControllerWithSourceTypeCamera
{
    UIImagePickerController *imagePickerController = [AGImagePickerManager getImagePickerControllerWithSourceTypeCamera];
    imagePickerController.delegate = self;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)showImagePickerControllerWithSourceTypeSavedPhotosAlbum
{
    UIImagePickerController *imagePickerController = [AGImagePickerManager getImagePickerControllerWithSourceTypeSavedPhotosAlbum];
    imagePickerController.delegate = self;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)configureImageView
{
//    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.contentMode = UIViewContentModeTopLeft;
}

- (void)updateScrollViewContentSize
{
//    self.scrollView.contentSize = self.imageView.frame.size;
    self.scrollView.contentSize = self.imageView.image.size;
}

- (void)startProcessingImage:(UIImage *)image
{
    [self.activityIndicator startAnimating];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *processedImage = [self.highlighterDetector processImageToFindGreenHighlighterArea:image];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            self.imageView.image = processedImage;
//            [self.activityIndicator stopAnimating];
//        });
        [self.textProcessing recognizeTextInImage:processedImage];
    });
}

#pragma mark -
#pragma mark Actions

- (IBAction)takePhotoButtonPressed:(UIBarButtonItem *)sender
{
    [self showImagePickerControllerWithSourceTypeCamera];
}

- (IBAction)chosePhotoButtonPressed:(UIBarButtonItem *)sender
{
    [self showImagePickerControllerWithSourceTypeSavedPhotosAlbum];
}

#pragma mark -
#pragma mark Image Picker Controller Delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
//    UIImageWriteToSavedPhotosAlbum([[info objectForKey:UIImagePickerControllerOriginalImage] fixOrientation], nil, nil, nil);
    UIImage *fixedImage = [[info objectForKey:UIImagePickerControllerOriginalImage] fixOrientation];
    [self startProcessingImage:fixedImage];
    self.imageView.image = fixedImage;
    [self updateScrollViewContentSize];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark Text Processing Delegate

- (void)textProcessing:(AGTextProcessing *)textProcessing recognizedText:(NSString *)text inImage:(UIImage *)image
{
    self.recognizedText.text = text;
    self.imageView.image = image;
    [self.activityIndicator stopAnimating];
}

@end
