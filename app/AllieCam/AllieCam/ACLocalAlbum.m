//
//  ACLocalAlbum.m
//  AllieCam2
//
//  Created by Mark Blackwell on 25/12/12.
//  Copyright (c) 2012 Mark Blackwell. All rights reserved.
//

#import "ACLocalAlbum.h"
#import "ACLocalPhoto.h"
#import "ACAlbum.h"

@interface ACLocalAlbum ()

@property(nonatomic,retain) NSMutableArray *photos;

@end

@implementation ACLocalAlbum

- (id)init {
    if (self = [super init]) {
        self.photos = [[[NSMutableArray alloc] init] autorelease];
    }
    
    return self;
}

- (void)addPhoto:(ACLocalPhoto *)photo {
    [_photos addObject:photo];
}
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
    DLog(@"%d photos in album", _photos.count);
    return _photos.count;
}

- (NSString *)name {
    if (_name.length == 0 && _assetGroup)
        return [_assetGroup valueForProperty:ALAssetsGroupPropertyName];
    
    return _name;
}

- (UIImage *)posterImage {
    CGImageRef posterImageRef = [_assetGroup posterImage];
    return [UIImage imageWithCGImage:posterImageRef];
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
