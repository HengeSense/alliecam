//
//  ACAlliecamAlbum.h
//  AllieCam
//
//  Created by Mark Blackwell on 3/01/13.
//  Copyright (c) 2013 Mark Blackwell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AllieCam.h"

@protocol ACAlbum;
@protocol ACPhotoManager;
@class ACAlliecamPhoto;

@interface ACAlliecamAlbum : NSObject <ACAlbum>

- (id)initWithName:(NSString *)name createDate:(NSDate *)date uniqid:(NSString *)uniqid;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSDate *createDate;
@property (nonatomic, copy) NSString *uniqid;

@property (nonatomic, assign) id<ACPhotoManager> manager;

- (void)addPhoto:(ACAlliecamPhoto *)photo;

@end
