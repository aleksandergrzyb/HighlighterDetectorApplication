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

@interface AGMainViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) AGHighlighterDetector *highlighterDetector;
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
    self.imageView.contentMode = UIViewContentModeTopLeft;
}

- (void)updateScrollViewContentSize
{
    self.scrollView.contentSize = self.imageView.image.size;
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
    self.imageView.image = [self.highlighterDetector processImageToFindGreenHighlighterArea:[info objectForKey:UIImagePickerControllerOriginalImage]];
    [self updateScrollViewContentSize];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
