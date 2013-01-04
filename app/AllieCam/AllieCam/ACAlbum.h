//
//  ACAlbum.h
//  AllieCam2
//
//  Created by Mark Blackwell on 25/12/12.
//  Copyright (c) 2012 Mark Blackwell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EGOPhotoSource.h"

@protocol ACPhotoManager;
@protocol ACPhoto;

@protocol ACAlbum <EGOPhotoSource>

@property (nonatomic, assign) id<ACPhotoManager> manager;

@property (nonatomic, copy) NSString* name;

- (UIImage *)posterImage;

- (id<ACPhoto>)photoAtURL:(NSString *)url;


@end
