//
//  ACAlliecamPhoto.m
//  AllieCam
//
//  Created by Mark Blackwell on 3/01/13.
//  Copyright (c) 2013 Mark Blackwell. All rights reserved.
//


#import "ACAlliecamPhoto.h"
#import "AllieCam.h"

@implementation ACAlliecamPhoto

- (id)initWithURL:(NSURL *)url {
    if (self = [super init]) {
		_URL = [url retain];
    }
    return self;
}

- (BOOL) didFail {
    return _failed;
}
- (void)setFailed:(BOOL)failed {
    if (failed)
        DLog(@"ERROR: image at %@ FAILED", self.URL.relativeString);
    _failed=failed;
}

- (void)dealloc {
    [super dealloc];
    [_URL release];
    self.dateTaken = nil;
    self.uniqid = nil;
    self.fullsizeURL = nil;
    self.thumbnailURL = nil;
    self.thumbnail = nil;
}


@end
