//
//  ACAlliecamPhotoManager.h
//  AllieCam
//
//  Created by Mark Blackwell on 3/01/13.
//  Copyright (c) 2013 Mark Blackwell. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ACPhotoManager;

@interface ACAlliecamPhotoManager : NSObject <ACPhotoManager>

+ (ACAlliecamPhotoManager *)sharedInstance;
- (void)initializeWithCallback:(void (^)(NSArray *albums))done;


@end
