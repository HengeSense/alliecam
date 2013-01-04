//
//  ACLocalPhotoSource.h
//  AllieCam2
//
//  Created by Mark Blackwell on 24/12/12.
//  Copyright (c) 2012 Mark Blackwell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACPhotoSource.h"
#import "ACLocalPhoto.h"

@interface ACLocalPhotoSource : NSObject <EGOPhotoSource>

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
- (ACLocalPhoto *)photoAtURL:(NSString *)url;
    
- (void)releaseImages;

@end
