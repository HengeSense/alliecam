//
//  ACImagePickerDelegate.m
//  AllieCam
//
//  Created by Mark Blackwell on 14/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACImagePickerDelegate.h"

@implementation ACImagePickerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker 
didFinishPickingMediaWithInfo:(NSDictionary *)info 
{
    // if we are on WiFi, then immediately upload
    
    // if we are on 3G, then cache to upload later on
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    
}

// optional method
- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    
}

// optional method
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    
}
@end
