//
//  ACPhotoSource.h
//  AllieCam2
//
//  Created by Mark Blackwell on 25/12/12.
//  Copyright (c) 2012 Mark Blackwell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Three20/Three20.h"

@protocol ACAlbum;

@protocol ACPhotoSource <TTPhotoSource>

/**
 * The total number of photos in the source, independent of the number that have been loaded.
 */
@property (nonatomic, readonly) NSInteger numberOfAlbums;

/**
 * The maximum index of photos that have already been loaded.
 */
@property (nonatomic, readonly) NSInteger maxAlbumIndex;

- (id<ACAlbum>)albumAtIndex:(NSInteger)index;

@end
