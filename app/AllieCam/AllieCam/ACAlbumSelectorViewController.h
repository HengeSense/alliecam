//
//  ACAlbumSelectorViewController.h
//  AllieCam
//
//  Created by Mark Blackwell on 3/01/13.
//  Copyright (c) 2013 Mark Blackwell. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ACAlbumSelectorViewController : UITableViewController

@property (retain, nonatomic) NSArray *albums;
- (id)initWithAlbums:(NSArray *)albums;
    
@end
