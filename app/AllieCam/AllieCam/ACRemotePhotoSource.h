//
//  ACRemotePhotoSource.h
//  AllieCam
//
//  Created by Mark Blackwell on 2/01/13.
//  Copyright (c) 2013 Mark Blackwell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACPhotoSource.h"

@interface ACRemotePhotoSource : NSObject <ACPhotoSource>

/*
 * Array containing photo data objects.
 */
@property(nonatomic,readonly,retain) NSArray *photos;

/*
 * Number of photos.
 */
@property(nonatomic,readonly) NSInteger numberOfPhotos;

/*
 * Should return a photo from the photos array, at the index passed.
 */
- (id)photoAtIndex:(NSInteger)index;


@property (nonatomic, readonly) NSInteger numberOfAlbums;

@property (nonatomic, readonly) NSInteger maxAlbumIndex;

@property(nonatomic,readonly,retain) NSArray *albums;

- (id<ACAlbum>)albumAtIndex:(NSInteger)index;

- (ACLocalPhoto *)photoAtURL:(NSString *)url;


@end
