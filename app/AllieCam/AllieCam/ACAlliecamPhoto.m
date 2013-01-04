//
//  ACAlliecamPhoto.m
//  AllieCam
//
//  Created by Mark Blackwell on 3/01/13.
//  Copyright (c) 2013 Mark Blackwell. All rights reserved.
//

#import "ACAlliecamPhoto.h"

@implementation ACAlliecamPhoto

- (id)initWithURL:(NSURL *)url {
    if (self = [super init]) {
		_URL = [url retain];
    }
    return self;
}
- (UIImage *)thumbnail {
    NSData *imageData = [NSData dataWithContentsOfURL:_thumbnailURL];
    UIImage *poster = [UIImage imageWithData:imageData];
    return poster;
}

- (void)dealloc {
    [super dealloc];
    [_URL release];
}

@end
