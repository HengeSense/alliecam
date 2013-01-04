//
//  ACMasterViewController.h
//  AllieCam
//
//  Created by Mark Blackwell on 5/12/12.
//  Copyright (c) 2012 Mark Blackwell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EGOPhotoViewController.h"

#import "AlbumContentsTableViewCell.h"
@protocol ACAlbum;

//@class ACDetailViewController;

@interface ACAlbumViewController : UITableViewController <AlbumContentsTableViewCellSelectionDelegate> {
    NSInteger lastSelectedRow;
}

- (id)initWithAlbum:(id<ACAlbum>)album;
    
@property (nonatomic, retain) EGOPhotoViewController *photoController;
@property (nonatomic, retain) id<ACAlbum> album;
@property (nonatomic, assign) IBOutlet AlbumContentsTableViewCell *tmpCell;



@end
