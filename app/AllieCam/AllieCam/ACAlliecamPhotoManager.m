//
//  ACAlliecamPhotoManager.m
//  AllieCam
//
//  Created by Mark Blackwell on 3/01/13.
//  Copyright (c) 2013 Mark Blackwell. All rights reserved.
//

#import "ACAlliecamPhotoManager.h"
#import "AllieCam.h"
#import "ACAlbum.h"
#import "ACAlliecamAlbum.h"
#import "ACAlliecamPhoto.h"
#import "AFNetworking.h"

#define ALLIECAM_URL             @"http://www.alliecam.net/"
//#define ALLIECAM_URL             @"http://localhost/~mblackwell8/alliecam/"

@interface ACAlliecamPhotoManager ()

@property (retain, nonatomic) NSMutableArray *albums;
@property (retain, nonatomic) NSMutableDictionary *loadingThumbnails;

@end

@implementation ACAlliecamPhotoManager

static ACAlliecamPhotoManager *_sharedInstance;

- (id)init {
    if (self = [super init]) {
    }
    
    return self;
}

// want every thread to be working with the same instance, because it is written to file
+ (ACAlliecamPhotoManager *)sharedInstance {
    if (!_sharedInstance) {
        _sharedInstance = [[ACAlliecamPhotoManager alloc] init];
    }
    
    return _sharedInstance;
}

- (void)initializeWithCallback:(void (^)(NSArray *albums))done {
    _albums = [[NSMutableArray alloc] init];
    AFHTTPClient *alliecam = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:ALLIECAM_URL]];
    [alliecam registerHTTPOperationClass:[AFJSONRequestOperation class]];
	[alliecam setDefaultHeader:@"Accept" value:@"application/json"];
    
    [alliecam getPath:@"photos/raw_data"
           parameters:nil
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  NSDictionary *json = [(AFJSONRequestOperation *)operation responseJSON];
                  NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
                  [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                  NSURL *baseURL = [NSURL URLWithString:[json objectForKey:@"home"]];
                  for (NSDictionary *album in [json objectForKey:@"albums"]) {
                      ACAlliecamAlbum *ac_alb = [[ACAlliecamAlbum alloc]
                                                 initWithName:[album objectForKey:@"name"]
                                                 createDate:[formatter dateFromString:[album objectForKey:@"dateCreated"]]
                                                 uniqid:[album objectForKey:@"uniqid"]];
                      ac_alb.manager = self;
                      for (NSDictionary *photo in [album objectForKey:@"photos"]) {
                          ACAlliecamPhoto *ac_ph = [[ACAlliecamPhoto alloc] initWithURL:[NSURL URLWithString:[photo objectForKey:@"url"] relativeToURL:baseURL]];
                          
                          ac_ph.fullsizeURL = [NSURL URLWithString:[photo objectForKey:@"url_fullsize"] relativeToURL:baseURL];
                          ac_ph.thumbnailURL = [NSURL URLWithString:[photo objectForKey:@"url_thumbnail"] relativeToURL:baseURL];
                          NSString *dateTakenStr = [photo objectForKey:@"dateTaken"];
                          //FIXME: parse the metadata for a 'dateCreated' object
                          if (dateTakenStr) {
                              ac_ph.dateTaken = [formatter dateFromString:dateTakenStr];
                          }
                          ac_ph.parent = ac_alb;
                          [ac_alb addPhoto:ac_ph];
                          [ac_ph release];
                      }
                      [_albums addObject:ac_alb];
                      [ac_alb release];
                      
                      
                  }
                  done(_albums);
                  
              } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  DLog(@"alliecam album request failed with error: %@", error);
                  done(nil);
              }];
}

- (id<ACAlbum>)albumAtIndex:(NSInteger)index {
    return [_albums objectAtIndex:index];
}
- (NSInteger)numberOfAlbums {
    return _albums.count;
}
- (NSInteger)maxAlbumIndex {
    return _albums.count - 1;
}
- (NSArray *)albums {
    return _albums;
}

- (void)loadThumbnail:(id<ACPhoto>)photo
              success:(void (^)(UIImage *thumbnail))success {
    if (!photo) {
        DLog(@"cannot load thumbnail for nil photo.");
        return;
    }
    if (!photo.URL) {
        DLog(@"photo does not have URL... probably not set up yet?");
        return;
    }
    if (!_loadingThumbnails)
         _loadingThumbnails = [[NSMutableDictionary alloc] init];
    else if ([_loadingThumbnails objectForKey:photo.URL.absoluteString])
        return;
    
    [_loadingThumbnails setObject:photo forKey:photo.URL.absoluteString];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ACAlliecamPhoto *ac_photo = (ACAlliecamPhoto *)photo;
        NSData *imageData = [NSData dataWithContentsOfURL:ac_photo.thumbnailURL];
        UIImage *image = [UIImage imageWithData:imageData];
        
        CGSize size = image.size;
        CGSize croppedSize;
        CGFloat ratio = 64.0;
        CGFloat offsetX = 0.0;
        CGFloat offsetY = 0.0;
        
        // check the size of the image, we want to make it
        // a square with sides the size of the smallest dimension
        if (size.width > size.height) {
            offsetX = (size.height - size.width) / 2;
            croppedSize = CGSizeMake(size.height, size.height);
        } else {
            offsetY = (size.width - size.height) / 2;
            croppedSize = CGSizeMake(size.width, size.width);
        }
        
        // Crop the image before resize
        CGRect clippedRect = CGRectMake(offsetX * -1, offsetY * -1, croppedSize.width, croppedSize.height);
        CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], clippedRect);
        
        // Done cropping
        // Resize the image
        CGRect rect = CGRectMake(0.0, 0.0, ratio, ratio);
        UIGraphicsBeginImageContext(rect.size);
        [[UIImage imageWithCGImage:imageRef] drawInRect:rect];
        UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        ac_photo.thumbnail = thumbnail;
        
        if (success)
            success(thumbnail);
        [_loadingThumbnails removeObjectForKey:photo.URL.absoluteString];
    });
}

- (void)dealloc {
    [super dealloc];
    [_albums release];
    [_loadingThumbnails release];
}

@end
