//
//  ACAlliecamAlbum.m
//  AllieCam
//
//  Created by Mark Blackwell on 3/01/13.
//  Copyright (c) 2013 Mark Blackwell. All rights reserved.
//

#import "ACAlliecamAlbum.h"
#import "ACAlbum.h"
#import "ACAlliecamPhoto.h"

@interface ACAlliecamAlbum ()

@property(nonatomic,retain) NSMutableArray *photos;

@end

@implementation ACAlliecamAlbum

- (id)initWithName:(NSString *)name createDate:(NSDate *)date uniqid:(NSString *)uniqid {
    if (self = [super init]) {
        self.name = name;
        self.createDate = date;
        self.uniqid = uniqid;
        _photos = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)addPhoto:(ACAlliecamPhoto *)photo {
    [_photos addObject:photo];
}
- (id)photoAtIndex:(NSInteger)index {
    ACAlliecamPhoto *photo = [_photos objectAtIndex:index];
//    DLog(@"getting photo at index=%d, with URL %@", index, photo.URL);
    return photo;
}

- (NSInteger)numberOfPhotos {
    return _photos.count;
}

- (UIImage *)posterImage {
    return [[_photos objectAtIndex:0] thumbnail];
}

- (id<ACPhoto>)photoAtURL:(NSString *)url {
    
}

- (void)dealloc {
    [super dealloc];
    [_photos release];
}

@end
