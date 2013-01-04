//
//  ACLocalAlbum.h
//  AllieCam2
//
//  Created by Mark Blackwell on 25/12/12.
//  Copyright (c) 2012 Mark Blackwell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "AllieCam.h"

@protocol ACAlbum;
@protocol ACPhotoManager;
@class ACLocalPhoto;

@interface ACLocalAlbum : NSObject <ACAlbum>

@property (nonatomic, assign) id<ACPhotoManager> manager;

@property (nonatomic, copy) NSString* name;


@property (nonatomic, retain) ALAssetsGroup *assetGroup;
- (ACLocalPhoto *)photoAtURL:(NSString *)url;
- (void)releaseImages;

- (void)addPhoto:(ACLocalPhoto *)photo;

@end
