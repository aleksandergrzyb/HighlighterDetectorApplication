//
//  AGImagePickerManager.h
//  Highlighter
//
//  Created by Aleksander Grzyb on 05/05/14.
//  Copyright (c) 2014 Aleksander Grzyb. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AGImagePickerManager : NSObject

+ (UIImagePickerController *)getImagePickerControllerWithSourceTypeCamera;
+ (UIImagePickerController *)getImagePickerControllerWithSourceTypeSavedPhotosAlbum;

@end
