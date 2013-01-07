//
//  ACPhoto.h
//  AllieCam
//
//  Created by Mark Blackwell on 2/01/13.
//  Copyright (c) 2013 Mark Blackwell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EGOPhotoSource.h"

@protocol ACPhoto <EGOPhoto>

//- (UIImage *)thumbnail;
@property (nonatomic, retain) UIImage *thumbnail;


@end
