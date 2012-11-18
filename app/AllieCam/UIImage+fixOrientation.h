//
//  UIImage+fixOrientation.h
//  AllieCam
//
//  Created by Mark Blackwell on 18/11/12.
//
//

// from http://stackoverflow.com/questions/5427656/ios-uiimagepickercontroller-result-image-orientation-after-upload

#import <UIKit/UIKit.h>

@interface UIImage (fixOrientation)

- (UIImage *)fixOrientation;

@end
