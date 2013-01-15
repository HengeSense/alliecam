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

@property (nonatomic, retain) UIActivityIndicatorView *waitingForDataIndicator;

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

- (void)loadView {
	UIView *containerView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	containerView.backgroundColor = [UIColor blackColor];
	self.view = containerView;
    [containerView release];
    
    _state = ACRootViewControllerStateTransitioning;
    DLog(@"initializing");
    [[ACLocalPhotoManager sharedInstance] initializeWithCallback:^(NSArray *albums) {
        DLog(@"finished initializing... setting up new AlbumSelector");
        ACAlbumSelectorViewController *svc = [[[ACAlbumSelectorViewController alloc] initWithAlbums:albums] autorelease];
        svc.manager = [ACLocalPhotoManager sharedInstance];
        svc.title = @"Phone photos";
        
        [self applyBarButtonItemsTo:svc viewTitle:@"View Web Photos"];
        
        UINavigationController *nav = [[[UINavigationController alloc] initWithRootViewController:svc] autorelease];
        [svc.navigationController setToolbarHidden:NO];
//        nav.view.frame = CGRectMake(0,0,320,460);
//        [self.view addSubview:nav.view];
        [self presentViewController:nav animated:NO completion:nil];
        _state = ACRootViewControllerStateShowingLocalPhotos;
        self.localPhotoNavigator = nav;
        self.localPhotoViewer = svc;
        
        _visibleNavigator = nav;
        _visibleViewer = svc;
    }];
    [[ACAlliecamPhotoManager sharedInstance] initializeWithCallback:^(NSArray *albums) {
        DLog(@"finished initializing... setting up new AlbumSelector");
        ACAlbumSelectorViewController *svc = [[[ACAlbumSelectorViewController alloc] initWithAlbums:albums] autorelease];
        svc.manager = [ACAlliecamPhotoManager sharedInstance];
        svc.title = @"Web photos";
        
        [self applyBarButtonItemsTo:svc viewTitle:@"View Phone Photos"];
        
        UINavigationController *nav = [[[UINavigationController alloc] initWithRootViewController:svc] autorelease];
        [svc.navigationController setToolbarHidden:NO];
//        nav.view.frame = CGRectMake(0,0,320,460);
        self.alliecamNavigator = nav;
        self.alliecamViewer = svc;
    }];
}

- (void)applyBarButtonItemsTo:(ACAlbumSelectorViewController *)vc viewTitle:(NSString *)title {
    UIBarButtonItem *changeSourceButton =
        [[UIBarButtonItem alloc] initWithTitle:title
                                         style:UIBarButtonItemStyleBordered
                                        target:self
                                        action:@selector(changeSourceButtonTapped:)];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIBarButtonItem *refreshButton =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                  target:self
                                                  action:@selector(refreshButtonTapped:)];
    
    [vc setToolbarItems:@[ changeSourceButton, flex, refreshButton ]];
    [changeSourceButton release];
    [flex release];
    [refreshButton release];
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
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

//// since the nav controller is added as a subview, UIKit seems to call the rotation methods here
//// rather than the ones on the visible view controller (probably because it doesn't know that the
//// subview is full screen)
//// so, HACK away...
//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
//    return [_visibleNavigator.visibleViewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
//}
//- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
//    [_visibleNavigator.visibleViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
//}
//- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
//	
//    [_visibleNavigator.visibleViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
//}
//
//- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
//    [_visibleNavigator.visibleViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
//}



- (void)changeSourceButtonTapped:(id)sender {
    DLog(@"changeSourceButtonTapped...");
    if (!_alliecamNavigator || !_alliecamViewer ||
        !_localPhotoNavigator || !_localPhotoViewer) {
        DLog(@"init process not finished... ignoring");
        return;
    }
    UINavigationController *incomingNavigator = nil;
    ACAlbumSelectorViewController *incomingViewer = nil;
    ACRootViewControllerState incomingState;
    switch (_state) {
        case ACRootViewControllerStateShowingLocalPhotos:
            incomingNavigator = _alliecamNavigator;
            incomingViewer = _alliecamViewer;
            incomingState = ACRootViewControllerStateShowingAlliecamPhotos;
            break;
        case ACRootViewControllerStateShowingAlliecamPhotos:
            incomingNavigator = _localPhotoNavigator;
            incomingViewer = _localPhotoViewer;
            incomingState = ACRootViewControllerStateShowingLocalPhotos;
            break;
        case ACRootViewControllerStateTransitioning:
            incomingState = ACRootViewControllerStateTransitioning;
            break;
        default:
            DLog(@"ERROR: unknown state: %d", _state);
    }
    if (incomingNavigator) {
        _state = ACRootViewControllerStateTransitioning;
        _visibleNavigator.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [_visibleNavigator dismissViewControllerAnimated:YES completion:^{
            incomingNavigator.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            [self presentViewController:incomingNavigator animated:YES completion:^{
                _visibleNavigator = incomingNavigator;
                _visibleViewer = incomingViewer;
                _state = incomingState;
            }];
        }];
    }
//    switch (_state) {
//        case ACRootViewControllerStateShowingLocalPhotos:
//            _state = ACRootViewControllerStateTransitioning;
//            [UIView transitionWithView:self.view
//                              duration:0.75
//                               options:UIViewAnimationOptionTransitionFlipFromLeft
//                            animations:^{
//                                [_localPhotoNavigator.view removeFromSuperview];
//                                [self.view addSubview:_alliecamNavigator.view];
//                            }
//                            completion:^(BOOL finished){
//                                _state = ACRootViewControllerStateShowingAlliecamPhotos;
//                                _visibleNavigator = _alliecamNavigator;
//                                _visibleViewer = _alliecamViewer;
//                            }];
//            break;
//        case ACRootViewControllerStateShowingAlliecamPhotos:
//            _state = ACRootViewControllerStateTransitioning;
//            [UIView transitionWithView:self.view
//                              duration:0.75
//                               options:UIViewAnimationOptionTransitionFlipFromRight
//                            animations:^{
//                                [_alliecamNavigator.view removeFromSuperview];
//                                [self.view addSubview:_localPhotoNavigator.view];
//                            }
//                            completion:^(BOOL finished){
//                                _state = ACRootViewControllerStateShowingLocalPhotos;
//                                _visibleNavigator = _localPhotoNavigator;
//                                _visibleViewer = _localPhotoViewer;
//                            }];
//            break;
//        case ACRootViewControllerStateTransitioning:
//            DLog(@"transitioning... ignored");
//            break;
//            
//        default:
//            break;
//    }
}


- (void)refreshButtonTapped:(id)sender {
    NSMutableArray *items = [_visibleViewer.toolbarItems mutableCopy];
    [items removeObjectAtIndex:2];
    
    UIActivityIndicatorView *waiting = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    UIBarButtonItem *bbi = [[UIBarButtonItem alloc] initWithCustomView:waiting];
    [items insertObject:bbi atIndex:2];
    [bbi release];
    self.waitingForDataIndicator = waiting;
    [waiting release];
    
    [_visibleViewer setToolbarItems:items animated:NO];
    [items release];
    
    [_waitingForDataIndicator startAnimating];
    
    [_visibleViewer.manager initializeWithCallback:^(NSArray *albums) {
        DLog(@"finished refreshing photo manager... assigning new albums");
        _visibleViewer.albums = albums;
        [_visibleViewer.tableView reloadData];
        dispatch_async(dispatch_get_main_queue(), ^{
            //tasks on main thread
            NSMutableArray *items = [_visibleViewer.toolbarItems mutableCopy];
            [items removeObjectAtIndex:2];
            UIBarButtonItem *bbi = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshButtonTapped:)];
            [items insertObject:bbi atIndex:2];
            [bbi release];
            
            [_visibleViewer setToolbarItems:items animated:NO];
            [items release];
            
            [_waitingForDataIndicator stopAnimating];
        });
    }];
}


@end
