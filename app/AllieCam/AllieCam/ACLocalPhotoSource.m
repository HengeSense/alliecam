//
//  ACLocalPhotoSource.m
//  AllieCam2
//
//  Created by Mark Blackwell on 24/12/12.
//  Copyright (c) 2012 Mark Blackwell. All rights reserved.
//

#import "ACLocalPhotoSource.h"

@interface ACLocalPhotoSource ()

@property(nonatomic,retain) NSMutableArray *photos;

@end

@implementation ACLocalPhotoSource

- (id)photoAtIndex:(NSInteger)index {
    DLog(@"getting photo at index=%d", index);
    return [_photos objectAtIndex:index];
}

- (ACLocalPhoto *)photoAtURL:(NSString *)url {
    if (!_photos)
        return nil;
    
    for (ACLocalPhoto *photo in _photos) {
        if ([photo.URL.description isEqualToString:url])
            return photo;
    }
    
    return nil;
}

- (NSInteger)numberOfPhotos {
    return _photos.count;
}

- (void)releaseImages {
    DLog(@"releasing all images");
    for (ACLocalPhoto *photo in _photos) {
        if (photo.image) {
            DLog(@"setting image at '%@' to nil", photo.URL);
            [photo setImage:nil];
        }
    }
}


- (void)dealloc {
    [_photos release];
    
    [super dealloc];
}

@end
