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

//#define ALLIECAM_URL             @"http://www.alliecam.net/"
#define ALLIECAM_URL             @"http://localhost/~mblackwell8/alliecam/"

@interface ACAlliecamPhotoManager ()

@property (retain, nonatomic) NSMutableArray *albums;

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

- (void)dealloc {
    [super dealloc];
    [_albums release];
}

@end
