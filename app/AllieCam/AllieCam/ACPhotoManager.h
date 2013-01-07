//
//  ACPhotoSourceManager.h
//  AllieCam
//
//  Created by Mark Blackwell on 2/01/13.
//  Copyright (c) 2013 Mark Blackwell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACAlbum.h"

@protocol ACPhotoManager <NSObject>

- (void)initializeWithCallback:(void (^)(NSArray *albums))done;

@property (nonatomic, readonly) NSInteger numberOfAlbums;

@property (nonatomic, readonly) NSInteger maxAlbumIndex;

- (id<ACAlbum>)albumAtIndex:(NSInteger)index;

@property(nonatomic,readonly,retain) NSArray *albums;

- (void)loadThumbnail:(id<ACPhoto>)photo
              success:(void (^)(UIImage *thumbnail))success;


@end
