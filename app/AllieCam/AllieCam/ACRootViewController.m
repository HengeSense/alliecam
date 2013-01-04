//
//  ACRootViewController.m
//  AllieCam
//
//  Created by Mark Blackwell on 3/01/13.
//  Copyright (c) 2013 Mark Blackwell. All rights reserved.
//

#import "ACRootViewController.h"
#import "ACAlbumSelectorViewController.h"
#import "ACPhotoManager.h"
#import "ACLocalPhotoManager.h"
#import "ACAlliecamPhotoManager.h"
#import "AllieCam.h"

@interface ACRootViewController ()

@end

@implementation ACRootViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    CGRect frm = self.view.frame;
    frm.origin.y = 0;
    self.view.frame = frm;
    _state = ACRootViewControllerStateTransitioning;
    DLog(@"initializing");
    [[ACLocalPhotoManager sharedInstance] initializeWithCallback:^(NSArray *albums) {
        DLog(@"finished initializing... setting up new AlbumSelector");
        ACAlbumSelectorViewController *svc = [[[ACAlbumSelectorViewController alloc] initWithAlbums:albums] autorelease];
        svc.title = @"Phone photos";
        UIBarButtonItem *changeSourceButton =
            [[UIBarButtonItem alloc] initWithTitle:@"View Web Photos"
                                             style:UIBarButtonItemStyleBordered
                                            target:self
                                            action:@selector(changeSourceButtonTapped:)];
        
        [svc setToolbarItems:[NSArray arrayWithObject:changeSourceButton]];
        [changeSourceButton release];
        
        UINavigationController *nav = [[[UINavigationController alloc] initWithRootViewController:svc] autorelease];
        [svc.navigationController setToolbarHidden:NO];
        [self.view addSubview:nav.view];
        _state = ACRootViewControllerStateShowingLocalPhotos;
        self.localPhotoNavigator = nav;
    }];
    [[ACAlliecamPhotoManager sharedInstance] initializeWithCallback:^(NSArray *albums) {
        DLog(@"finished initializing... setting up new AlbumSelector");
        ACAlbumSelectorViewController *svc = [[[ACAlbumSelectorViewController alloc] initWithAlbums:albums] autorelease];
        svc.title = @"Web photos";
        UIBarButtonItem *changeSourceButton =
            [[UIBarButtonItem alloc] initWithTitle:@"View Phone Photos"
                                             style:UIBarButtonItemStyleBordered
                                            target:self
                                            action:@selector(changeSourceButtonTapped:)];
        
        [svc setToolbarItems:[NSArray arrayWithObject:changeSourceButton]];
        [changeSourceButton release];
        
        UINavigationController *nav = [[[UINavigationController alloc] initWithRootViewController:svc] autorelease];
        [svc.navigationController setToolbarHidden:NO];
        self.alliecamNavigator = nav;
    }];
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
    DLog(@"ACRootViewController viewDidUnload called");
    
    [[ACLocalPhotoManager sharedInstance] releaseImages];
    
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    DLog(@"ACRootViewController received memory warning");
    [[ACLocalPhotoManager sharedInstance] releaseImages];
}


- (void)changeSourceButtonTapped:(id)sender {
    DLog(@"changeSourceButtonTapped...");
    switch (_state) {
        case ACRootViewControllerStateShowingLocalPhotos:
            _state = ACRootViewControllerStateTransitioning;
            [UIView transitionWithView:self.view
                              duration:0.75
                               options:UIViewAnimationOptionTransitionFlipFromLeft
                            animations:^{
                                [_localPhotoNavigator.view removeFromSuperview];
                                [self.view addSubview:_alliecamNavigator.view];
                            }
                            completion:^(BOOL finished){
                                _state = ACRootViewControllerStateShowingAlliecamPhotos;
                            }];
            break;
        case ACRootViewControllerStateShowingAlliecamPhotos:
            _state = ACRootViewControllerStateTransitioning;
            [UIView transitionWithView:self.view
                              duration:0.75
                               options:UIViewAnimationOptionTransitionFlipFromRight
                            animations:^{
                                [_alliecamNavigator.view removeFromSuperview];
                                [self.view addSubview:_localPhotoNavigator.view];
                            }
                            completion:^(BOOL finished){
                                _state = ACRootViewControllerStateShowingLocalPhotos;
                            }];
            break;
        case ACRootViewControllerStateTransitioning:
            DLog(@"transitioning... ignored");
            break;
            
        default:
            break;
    }
}

@end
