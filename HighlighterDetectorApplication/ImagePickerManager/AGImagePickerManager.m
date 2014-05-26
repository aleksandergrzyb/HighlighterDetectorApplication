//
//  AGImagePickerManager.m
//  Highlighter
//
//  Created by Aleksander Grzyb on 05/05/14.
//  Copyright (c) 2014 Aleksander Grzyb. All rights reserved.
//

#import "AGImagePickerManager.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation AGImagePickerManager

#pragma mark -
#pragma mark Public Methods

+ (UIImagePickerController *)getImagePickerControllerWithSourceTypeCamera
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        NSLog(@"Your device doesn't support taking pictures.");
        return nil;
    }
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
    if (![availableMediaTypes containsObject:(NSString *)kUTTypeImage]) {
        NSLog(@"Your device doesn't support taking pictures.");
        return nil;
    }
    imagePickerController.mediaTypes = @[(NSString *)kUTTypeImage];
    return imagePickerController;
}

+ (UIImagePickerController *)getImagePickerControllerWithSourceTypeSavedPhotosAlbum
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
        NSLog(@"Your device doesn't support getting photos from album.");
        return nil;
    }
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
    if (![availableMediaTypes containsObject:(NSString *)kUTTypeImage]) {
        NSLog(@"Your device doesn't support getting photos from album.");
        return nil;
    }
    imagePickerController.mediaTypes = @[(NSString *)kUTTypeImage];
    return imagePickerController;
}

@end
