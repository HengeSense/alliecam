//
//  ACRootViewController.h
//  AllieCam
//
//  Created by Mark Blackwell on 3/01/13.
//  Copyright (c) 2013 Mark Blackwell. All rights reserved.
//

#import <UIKit/UIKit.h>
@class  ACAlbumSelectorViewController;

typedef NS_ENUM(NSInteger, ACRootViewControllerState) {
    ACRootViewControllerStateShowingLocalPhotos,
    ACRootViewControllerStateShowingAlliecamPhotos,
    ACRootViewControllerStateTransitioning
};

@interface ACRootViewController : UIViewController {
    ACRootViewControllerState _state;
    
    ACAlbumSelectorViewController *_visibleViewer;
    UINavigationController *_visibleNavigator;
}

@property (nonatomic, retain) UINavigationController *alliecamNavigator;
@property (nonatomic, assign) ACAlbumSelectorViewController *alliecamViewer;
@property (nonatomic, retain) UINavigationController *localPhotoNavigator;
@property (nonatomic, assign) ACAlbumSelectorViewController *localPhotoViewer;

@end
