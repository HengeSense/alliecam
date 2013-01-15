//
//  EGOPhotoController.m
//  EGOPhotoViewer
//
//  Created by Devin Doty on 1/8/10.
//  Copyright 2010 enormego. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "EGOPhotoViewController.h"
#import "ACLocalAlbum.h"
#import "ACLocalPhotoManager.h"

// the actual upload method will allow fewer than this for memory reasons, but don't tell user
#define kMaxSimultaneousUploadsForUI   20

@interface EGOPhotoViewController (Private)
- (void)loadScrollViewWithPage:(NSInteger)page;
- (void)layoutScrollViewSubviews;
- (void)setupScrollViewContentSize;
- (void)enqueuePhotoViewAtIndex:(NSInteger)theIndex;
- (void)setBarsHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)setStatusBarHidden:(BOOL)hidden animated:(BOOL)animated;
- (NSInteger)centerPhotoIndex;
- (void)setupToolbar;
- (void)setViewState;
- (void)setupViewForPopover;
- (void)autosizePopoverToImageSize:(CGSize)imageSize photoImageView:(EGOPhotoImageView*)photoImageView;
@end


@implementation EGOPhotoViewController

@synthesize scrollView=_scrollView;
@synthesize photoSource=_photoSource; 
@synthesize photoViews=_photoViews;
@synthesize _fromPopover;

- (id)initWithPhoto:(id<EGOPhoto>)aPhoto {
	return [self initWithPhotoSource:[[[EGOQuickPhotoSource alloc] initWithPhotos:[NSArray arrayWithObjects:aPhoto,nil]] autorelease]];
}

- (id)initWithImage:(UIImage*)anImage {
	return [self initWithPhoto:[[[EGOQuickPhoto alloc] initWithImage:anImage] autorelease]];
}

- (id)initWithImageURL:(NSURL*)anImageURL {
	return [self initWithPhoto:[[[EGOQuickPhoto alloc] initWithImageURL:anImageURL] autorelease]];
}

- (id)initWithPhotoSource:(id <EGOPhotoSource> )aSource atIndex:(NSInteger)index{
	if (self = [super init]) {
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleBarsNotification:) name:@"EGOPhotoViewToggleBars" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoViewDidFinishLoading:) name:@"EGOPhotoDidFinishLoading" object:nil];
		
//		self.hidesBottomBarWhenPushed = YES;
		self.wantsFullScreenLayout = YES;
		_photoSource = [aSource retain];
		_pageIndex=index;
		
	}
	
	return self;
}

- (id)initWithPopoverController:(id)aPopoverController photoSource:(id <EGOPhotoSource>)aPhotoSource {
	if (self = [self initWithPhotoSource:aPhotoSource]) {
		_popover = aPopoverController;
	}
	
	return self;
}


#pragma mark -
#pragma mark View Controller Methods

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.view.backgroundColor = [UIColor blackColor];
	self.wantsFullScreenLayout = YES;
	
	if (!_scrollView) {
		
		_scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
		_scrollView.delegate=self;
		_scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		_scrollView.multipleTouchEnabled=YES;
		_scrollView.scrollEnabled=YES;
		_scrollView.directionalLockEnabled=YES;
		_scrollView.canCancelContentTouches=YES;
		_scrollView.delaysContentTouches=YES;
		_scrollView.clipsToBounds=YES;
		_scrollView.alwaysBounceHorizontal=YES;
		_scrollView.bounces=YES;
		_scrollView.pagingEnabled=YES;
		_scrollView.showsVerticalScrollIndicator=NO;
		_scrollView.showsHorizontalScrollIndicator=NO;
		_scrollView.backgroundColor = self.view.backgroundColor;
		[self.view addSubview:_scrollView];

	}
	
	if (!_captionView) {
		
		EGOPhotoCaptionView *view = [[EGOPhotoCaptionView alloc] initWithFrame:CGRectMake(0.0f, self.view.frame.size.height, self.view.frame.size.width, 1.0f)];
		[self.view addSubview:view];
		_captionView=view;
		[view release];
		
	}
	
	//  load photoviews lazily
	NSMutableArray *views = [[NSMutableArray alloc] init];
	for (unsigned i = 0; i < [self.photoSource numberOfPhotos]; i++) {
		[views addObject:[NSNull null]];
	}
	self.photoViews = views;
	[views release];


#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	if ([self.photoSource numberOfPhotos] == 1 && UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad) {
		
		[self.navigationController setNavigationBarHidden:YES animated:NO];
		[self.navigationController setToolbarHidden:YES animated:NO];
		
		[self enqueuePhotoViewAtIndex:_pageIndex];
		[self loadScrollViewWithPage:_pageIndex];
		[self setViewState];
		
	}
#endif
    
}

- (void)viewWillAppear:(BOOL)animated{
    DLog(@"viewWillAppear called");
	[super viewWillAppear:animated];
	
	if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 3.2) {
		
		UIView *view = self.view;
		if (self.navigationController) {
			view = self.navigationController.view;
		}
		
		while (view != nil) {
			
			if ([view isKindOfClass:NSClassFromString(@"UIPopoverView")]) {
				
				_popover = view;
				break;
			
			} 
			view = view.superview;
		}
		
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
		if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad && _popover==nil) {
			[self.navigationController setNavigationBarHidden:NO animated:NO];
		}
#endif
		
	} else {
		
		_popover = nil;
		
	}
	
	if(!_storedOldStyles) {
		_oldStatusBarSyle = [UIApplication sharedApplication].statusBarStyle;
		
		_oldNavBarTintColor = [self.navigationController.navigationBar.tintColor retain];
		_oldNavBarStyle = self.navigationController.navigationBar.barStyle;
		_oldNavBarTranslucent = self.navigationController.navigationBar.translucent;
		
		_oldToolBarTintColor = [self.navigationController.toolbar.tintColor retain];
		_oldToolBarStyle = self.navigationController.toolbar.barStyle;
		_oldToolBarTranslucent = self.navigationController.toolbar.translucent;
		_oldToolBarHidden = [self.navigationController isToolbarHidden];
		
		_storedOldStyles = YES;
	}	
	
	if ([self.navigationController isToolbarHidden] && (!_popover || ([self.photoSource numberOfPhotos] > 1))) {
		[self.navigationController setToolbarHidden:NO animated:YES];
	}
	
	if (!_popover) {
		self.navigationController.navigationBar.tintColor = nil;
		self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
		self.navigationController.navigationBar.translucent = YES;
		
		self.navigationController.toolbar.tintColor = nil;
		self.navigationController.toolbar.barStyle = UIBarStyleBlack;
		self.navigationController.toolbar.translucent = YES;
	}

	
	[self setupToolbar];
	[self setupScrollViewContentSize];
	[self moveToPhotoAtIndex:_pageIndex animated:NO];
	
	if (_popover) {
		[self addObserver:self forKeyPath:@"contentSizeForViewInPopover" options:NSKeyValueObservingOptionNew context:NULL];
	}
	
}

- (void)viewWillDisappear:(BOOL)animated{
	[super viewWillDisappear:animated];
	
	self.navigationController.navigationBar.barStyle = _oldNavBarStyle;
	self.navigationController.navigationBar.tintColor = _oldNavBarTintColor;
	self.navigationController.navigationBar.translucent = _oldNavBarTranslucent;
	
	[[UIApplication sharedApplication] setStatusBarStyle:_oldStatusBarSyle animated:YES];
	
	if(!_oldToolBarHidden) {
		
		if ([self.navigationController isToolbarHidden]) {
			[self.navigationController setToolbarHidden:NO animated:YES];
		}
		
		self.navigationController.toolbar.barStyle = _oldNavBarStyle;
		self.navigationController.toolbar.tintColor = _oldNavBarTintColor;
		self.navigationController.toolbar.translucent = _oldNavBarTranslucent;
		
	} else {
		
		[self.navigationController setToolbarHidden:_oldToolBarHidden animated:YES];
		
	}
	
	if (_popover) {
		[self removeObserver:self forKeyPath:@"contentSizeForViewInPopover"];
	}
    
    // this may have been altered by photo viewer
    if ([_photoSource isKindOfClass:[ACLocalAlbum class]])
        [[ACLocalPhotoManager sharedInstance] writeUploadedImagesToFile];
	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		return YES;
	}
#endif
	
   	return (UIInterfaceOrientationIsLandscape(interfaceOrientation) || interfaceOrientation == UIInterfaceOrientationPortrait);
	
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
	_rotating = YES;
	
	if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation) && !_popover) {
		CGRect rect = [[UIScreen mainScreen] bounds];
		self.scrollView.contentSize = CGSizeMake(rect.size.height * [self.photoSource numberOfPhotos], rect.size.width);
	}
	
	//  set side views hidden during rotation animation
	NSInteger count = 0;
	for (EGOPhotoImageView *view in self.photoViews){
		if ([view isKindOfClass:[EGOPhotoImageView class]]) {
			if (count != _pageIndex) {
				[view setHidden:YES];
			}
		}
		count++;
	}
	
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
	
	for (EGOPhotoImageView *view in self.photoViews){
		if ([view isKindOfClass:[EGOPhotoImageView class]]) {
			[view rotateToOrientation:toInterfaceOrientation];
		}
	}
		
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
	
	[self setupScrollViewContentSize];
	[self moveToPhotoAtIndex:_pageIndex animated:NO];
	[self.scrollView scrollRectToVisible:((EGOPhotoImageView*)[self.photoViews objectAtIndex:_pageIndex]).frame animated:YES];
	
	//  unhide side views
	for (EGOPhotoImageView *view in self.photoViews){
		if ([view isKindOfClass:[EGOPhotoImageView class]]) {
			[view setHidden:NO];
		}
	}
	_rotating = NO;
	
}

- (void)done:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (void)setupToolbar {
	
	[self setupViewForPopover];

	if(_popover && [self.photoSource numberOfPhotos] == 1) {
		[self.navigationController setToolbarHidden:YES animated:NO];
		return;
	}
	
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	if (!_popover && UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad && !_fromPopover) {
		if (self.modalPresentationStyle == UIModalPresentationFullScreen) {
			UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(done:)];
			self.navigationItem.rightBarButtonItem = doneButton;
			[doneButton release];
		}
	} else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
	}
#else 
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
#endif
	
	UIBarButtonItem *action =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                      target:self
                                                      action:@selector(actionButtonHit:)];
	UIBarButtonItem *flex =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                      target:nil
                                                      action:nil];
	
//	if ([self.photoSource numberOfPhotos] > 1) {
//		
//		UIBarButtonItem *fixedCenter = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
//		fixedCenter.width = 80.0f;
//		UIBarButtonItem *fixedLeft = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
//		fixedLeft.width = 40.0f;
//		
//		if (_popover && [self.photoSource numberOfPhotos] > 1) {
//			UIBarButtonItem *scaleButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"egopv_fullscreen_button.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(toggleFullScreen:)];
//			self.navigationItem.rightBarButtonItem = scaleButton;
//			[scaleButton release];
//		}		
//
//		
//		UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"egopv_left.png"] style:UIBarButtonItemStylePlain target:self action:@selector(moveBack:)];
//		UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"egopv_right.png"] style:UIBarButtonItemStylePlain target:self action:@selector(moveForward:)];
//		
//		[self setToolbarItems:[NSArray arrayWithObjects:fixedLeft, flex, left, fixedCenter, right, flex, action, nil]];
//		
//		_rightButton = right;
//		_leftButton = left;
//		
//		[fixedCenter release];
//		[fixedLeft release];
//		[right release];
//		[left release];
//		
//	} else {
//		[self setToolbarItems:[NSArray arrayWithObjects:flex, action, nil]];
//	}
//    
//    UIBarButtonItem *cameraButton =
//    [[UIBarButtonItem alloc] initWithTitle:@"Camera"
//                                     style:UIBarButtonItemStyleBordered
//                                    target:self
//                                    action:@selector(cameraButtonTapped:)];
    
    ACLabelledProgressViewController *progress = [[ACLabelledProgressViewController alloc] initWithNibName:@"ACLabelledProgressViewController" bundle:nil];
    UIBarButtonItem *progressItem = [[UIBarButtonItem alloc] initWithCustomView:progress.view];
    progress.view.hidden = YES;
    self.progressViewController = progress;
    
    [self setToolbarItems:[NSArray arrayWithObjects:flex, progressItem, flex, action, nil]];
	
	_actionButton=action;
	
//    [cameraButton release];
	[action release];
	[flex release];
    [progress release];
    [progressItem release];
	
}

- (NSInteger)currentPhotoIndex{
	
	return _pageIndex;
	
}

// added by MRB, only for use while view is not visible
- (void)presetPhotoIndex:(NSInteger)ix {
    DLog(@"presetting photo index to %d", ix);
    _pageIndex = ix;
}


#pragma mark -
#pragma mark Popver ContentSize Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{	
	[self setupScrollViewContentSize];
	[self layoutScrollViewSubviews];
}


#pragma mark -
#pragma mark Bar/Caption Methods

- (void)setStatusBarHidden:(BOOL)hidden animated:(BOOL)animated{
	if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad) return; 
	
	if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 3.2) {
		
		[[UIApplication sharedApplication] setStatusBarHidden:hidden withAnimation:UIStatusBarAnimationFade];
		
	} else {
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 30200
		[[UIApplication sharedApplication] setStatusBarHidden:hidden animated:animated];
#endif
	}

}

- (void)setBarsHidden:(BOOL)hidden animated:(BOOL)animated{
	if (hidden&&_barsHidden) return;
	
	if (_popover && [self.photoSource numberOfPhotos] == 0) {
		[_captionView setCaptionHidden:hidden];
		return;
	}
		
	[self setStatusBarHidden:hidden animated:animated];
	
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		
		if (!_popover) {
			
			if (animated) {
				[UIView beginAnimations:nil context:NULL];
				[UIView setAnimationDuration:0.3f];
				[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
			}
			
			self.navigationController.navigationBar.alpha = hidden ? 0.0f : 1.0f;
			self.navigationController.toolbar.alpha = hidden ? 0.0f : 1.0f;
			
			if (animated) {
				[UIView commitAnimations];
			}
			
		} 
		
	} else {
		
		[self.navigationController setNavigationBarHidden:hidden animated:animated];
		[self.navigationController setToolbarHidden:hidden animated:animated];
		
	}
#else
	
	[self.navigationController setNavigationBarHidden:hidden animated:animated];
	[self.navigationController setToolbarHidden:hidden animated:animated];
	
#endif
	
	if (_captionView) {
		[_captionView setCaptionHidden:hidden];
	}
	
	_barsHidden=hidden;
	
}

- (void)toggleBarsNotification:(NSNotification*)notification{
	[self setBarsHidden:!_barsHidden animated:YES];
}


#pragma mark -
#pragma mark FullScreen Methods

- (void)setupViewForPopover{
	
	if (!_popoverOverlay && _popover && [self.photoSource numberOfPhotos] == 1) {
				
		UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0f, self.view.frame.size.height, self.view.frame.size.width, 40.0f)];
		view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
		view.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.2f];
		_popoverOverlay = view;
		[self.view addSubview:view];
		[view release];
		
		UIView *borderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, _popoverOverlay.frame.size.width, 1.0f)];
		borderView.autoresizingMask = view.autoresizingMask;
		[_popoverOverlay addSubview:borderView];
		[borderView setBackgroundColor:[UIColor colorWithWhite:1.0f alpha:0.4f]];
		[borderView release];
		
		UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
		[button setImage:[UIImage imageNamed:@"egopv_fullscreen_button.png"] forState:UIControlStateNormal];
		button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
		[button addTarget:self action:@selector(toggleFullScreen:) forControlEvents:UIControlEventTouchUpInside];
		button.frame = CGRectMake(view.frame.size.width - 40.0f, 0.0f, 40.0f, 40.0f);
		[view addSubview:button];
		
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.3f];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		view.frame = CGRectMake(0.0f, self.view.bounds.size.height - 40.0f, self.view.bounds.size.width, 40.0f);
		[UIView commitAnimations];
		
	}
	
}

- (CATransform3D)transformForCurrentOrientation{
	
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	
	switch (orientation) {
		case UIInterfaceOrientationPortraitUpsideDown:
			return CATransform3DMakeRotation((M_PI/180)*180, 0.0f, 0.0f, 1.0f);
			break;
		case UIInterfaceOrientationLandscapeRight:
			return CATransform3DMakeRotation((M_PI/180)*90, 0.0f, 0.0f, 1.0f);
			break;
		case UIInterfaceOrientationLandscapeLeft:
			return CATransform3DMakeRotation((M_PI/180)*-90, 0.0f, 0.0f, 1.0f);
			break;
		default:
			return CATransform3DIdentity;
			break;
	}
	
}

- (void)toggleFullScreen:(id)sender{
	
	_fullScreen = !_fullScreen;
	
	if (!_fullScreen) {
		
		NSInteger pageIndex = 0;
		if (self.modalViewController && [self.modalViewController isKindOfClass:[UINavigationController class]]) {
			UIViewController *controller = [((UINavigationController*)self.modalViewController) visibleViewController];
			if ([controller isKindOfClass:[self class]]) {
				pageIndex = [(EGOPhotoViewController*)controller currentPhotoIndex];
			}
		}		
		[self moveToPhotoAtIndex:pageIndex animated:NO];
		[self.navigationController dismissModalViewControllerAnimated:NO];
		
	}
	
	EGOPhotoImageView *_currentView = [self.photoViews objectAtIndex:_pageIndex];
	BOOL enabled = [UIView areAnimationsEnabled];
	[UIView setAnimationsEnabled:NO];
	[_currentView killScrollViewZoom];
	[UIView setAnimationsEnabled:enabled];
	UIImageView *_currentImage = _currentView.imageView;
	
	UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
	UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
	backgroundView.layer.transform = [self transformForCurrentOrientation];
	[keyWindow addSubview:backgroundView];
	backgroundView.frame = [[UIScreen mainScreen] applicationFrame];
	_transferView = backgroundView;
	[backgroundView release];
	
	CGRect newRect = [self.view convertRect:_currentView.scrollView.frame toView:_transferView];
	UIImageView *_imageView = [[UIImageView alloc] initWithFrame:_fullScreen ? newRect : _transferView.bounds];	
	_imageView.contentMode = UIViewContentModeScaleAspectFit;
	[_imageView setImage:_currentImage.image];
	[_transferView addSubview:_imageView];
	[_imageView release];
	
	self.scrollView.hidden = YES;
	
	CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
	animation.fromValue = _fullScreen ? (id)[UIColor clearColor].CGColor : (id)[UIColor blackColor].CGColor;
	animation.toValue = _fullScreen ? (id)[UIColor blackColor].CGColor : (id)[UIColor clearColor].CGColor;
	animation.removedOnCompletion = NO;
	animation.fillMode = kCAFillModeForwards;
	animation.duration = 0.4f;
	[_transferView.layer addAnimation:animation forKey:@"FadeAnimation"];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.4f];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(fullScreenAnimationDidStop:finished:context:)];
	_imageView.frame = _fullScreen ? _transferView.bounds : newRect;
	[UIView commitAnimations];
	
}

- (void)fullScreenAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context{
	
	if (finished) {
		
		self.scrollView.hidden = NO;
		
		if (_transferView) {
			[_transferView removeFromSuperview];
			_transferView=nil;
		}
		
		if (_fullScreen) {
			
			BOOL enabled = [UIView areAnimationsEnabled];
			[UIView setAnimationsEnabled:NO];
			
			EGOPhotoViewController *controller = [[EGOPhotoViewController alloc] initWithPhotoSource:self.photoSource];
			controller._fromPopover = YES;
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
			
			navController.modalPresentationStyle = UIModalPresentationFullScreen;
			[self.navigationController presentModalViewController:navController animated:NO];
			[controller moveToPhotoAtIndex:_pageIndex animated:NO];
			
			[navController release];
			[controller release];
			
			[UIView setAnimationsEnabled:enabled];
			
			UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"egopv_minimize_fullscreen_button.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(toggleFullScreen:)];
			controller.navigationItem.rightBarButtonItem = button;
			[button release];
			
		}
		
	}
	
}



#pragma mark -
#pragma mark Photo View Methods

- (void)photoViewDidFinishLoading:(NSNotification*)notification{
	if (notification == nil) return;
	
//    DLog(@"checking whether photoViewDidFinishLoading object is centerPhotoIndex (%d)", [self centerPhotoIndex]);
	if ([[[notification object] objectForKey:@"photo"] isEqual:[self.photoSource photoAtIndex:[self centerPhotoIndex]]]) {
//        DLog(@"... it is");
		if ([[[notification object] objectForKey:@"failed"] boolValue]) {
			if (_barsHidden) {
				//  image failed loading
				[self setBarsHidden:NO animated:YES];
			}
		} 
		[self setViewState];
	}
}

- (NSInteger)centerPhotoIndex{
	
	CGFloat pageWidth = self.scrollView.frame.size.width;
//    DLog(@"centerPhotoIndex page width is %g", pageWidth);
    if (pageWidth == 0) {
        DLog(@"page width is zero!");
        // HACK, but appears to work for now... not sure what is resetting the pageWidth
        // to replicate:
        // 1. Browse to album
        // 2. Return to root, without viewing a picture
        // 3. Browse back to the album (or a different one)
        // 4. Select any picture
        return 0;
    }
//    DLog(@"centerPhotoIndex x offset is %g", self.scrollView.contentOffset.x);
	NSInteger cpi = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
//    DLog(@"center photo index is %d", cpi);
    
    return cpi;
	
}

- (void)moveForward:(id)sender{
    DLog(@"moveForward called");
	[self moveToPhotoAtIndex:[self centerPhotoIndex]+1 animated:NO];	
}

- (void)moveBack:(id)sender{
    DLog(@"moveBack called");
	[self moveToPhotoAtIndex:[self centerPhotoIndex]-1 animated:NO];
}

- (void)setViewState {	
	
//	if (_leftButton) {
//		_leftButton.enabled = !(_pageIndex-1 < 0);
//	}
//	
//	if (_rightButton) {
//		_rightButton.enabled = !(_pageIndex+1 >= [self.photoSource numberOfPhotos]);
//	}
	
    DLog(@"setting view state");
	if (_actionButton) {
		EGOPhotoImageView *imageView = [_photoViews objectAtIndex:[self centerPhotoIndex]];
		if ((NSNull*)imageView != [NSNull null]) {
			
			_actionButton.enabled = ![imageView isLoading];
			
		} else {
			
			_actionButton.enabled = NO;
		}
	}
	
	if ([self.photoSource numberOfPhotos] > 1) {
		self.title = [NSString stringWithFormat:@"%i of %i", _pageIndex+1, [self.photoSource numberOfPhotos]];
	} else {
		self.title = @"";
	}
	
	if (_captionView) {
        // MRB set the uploaded message
        id<EGOPhoto> photo = [_photoSource photoAtIndex:_pageIndex];
        if ([photo respondsToSelector:@selector(caption)]) {
            NSString *caption = [photo caption];
            DLog(@"setting caption view to %@", caption);
            [_captionView setCaptionText:caption hidden:NO];
        }
	}
    
	
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
			
	if([self respondsToSelector:@selector(setContentSizeForViewInPopover:)] && [self.photoSource numberOfPhotos] == 1) {
		
		EGOPhotoImageView *imageView = [_photoViews objectAtIndex:[self centerPhotoIndex]];
		if ((NSNull*)imageView != [NSNull null]) {
			self.contentSizeForViewInPopover = [imageView sizeForPopover];
		}
		
	}
	
#endif
    // no need to do this if there are uploads running
    if (_numUploadsRunningNow == 0)
        [self setUploadProgressView];
}

- (void)setUploadProgressView {
    if (_totalUploadsInProgressView > 0 && _currentUploadIndex < _totalUploadsInProgressView) {
        DLog(@"updating progress %d %d %d %d", _currentUploadIndex, _totalUploadsInProgressView, _bytesUploaded, _totalBytesToUploadInProgressView);
        _progressViewController.view.hidden = NO;
        _progressViewController.progressLabel.text = [NSString stringWithFormat:@"Uploading %d of %d", _currentUploadIndex + 1, _totalUploadsInProgressView];
        if (_totalBytesToUploadInProgressView > 0) {
            [_progressViewController.progressBar setProgress:((float)_bytesUploaded / _totalBytesToUploadInProgressView) animated:NO];
        }
    }
    else {
        DLog(@"hiding progress view");
        _progressViewController.view.hidden = YES;
        [_progressViewController.progressBar setProgress:0 animated:NO];
        _currentUploadIndex = 0;
        _totalUploadsInProgressView = 0;
    }
    
	
}

- (void)moveToPhotoAtIndex:(NSInteger)index animated:(BOOL)animated {
	NSAssert(index < [self.photoSource numberOfPhotos] && index >= 0, @"Photo index passed out of bounds. index=%d, numberOfPhotos=%d", index, [self.photoSource numberOfPhotos]);
	
    DLog(@"moving to photo at index %d", index);
	_pageIndex = index;
	[self setViewState];

	[self enqueuePhotoViewAtIndex:index];
	
//	[self loadScrollViewWithPage:index-2];
	[self loadScrollViewWithPage:index-1];
	[self loadScrollViewWithPage:index];
	[self loadScrollViewWithPage:index+1];
//	[self loadScrollViewWithPage:index+2];
	
	
	[self.scrollView scrollRectToVisible:((EGOPhotoImageView*)[self.photoViews objectAtIndex:index]).frame animated:animated];
	
	if ([[self.photoSource photoAtIndex:_pageIndex] didFail]) {
		[self setBarsHidden:NO animated:YES];
	}
	
	//  reset any zoomed side views
	if (index + 1 < [self.photoSource numberOfPhotos] && (NSNull*)[self.photoViews objectAtIndex:index+1] != [NSNull null]) {
		[((EGOPhotoImageView*)[self.photoViews objectAtIndex:index+1]) killScrollViewZoom];
	} 
	if (index - 1 >= 0 && (NSNull*)[self.photoViews objectAtIndex:index-1] != [NSNull null]) {
		[((EGOPhotoImageView*)[self.photoViews objectAtIndex:index-1]) killScrollViewZoom];
	} 	
    DLog(@"moved to photo at index %d", index);
	
}

- (void)layoutScrollViewSubviews{
	
	NSInteger _index = [self currentPhotoIndex];
	
	for (NSInteger page = _index -1; page < _index+3; page++) {
		
		if (page >= 0 && page < [self.photoSource numberOfPhotos]){
			
			CGFloat originX = self.scrollView.bounds.size.width * page;
			
			if (page < _index) {
				originX -= EGOPV_IMAGE_GAP;
			} 
			if (page > _index) {
				originX += EGOPV_IMAGE_GAP;
			}
			
			if ([self.photoViews objectAtIndex:page] == [NSNull null] || !((UIView*)[self.photoViews objectAtIndex:page]).superview){
				[self loadScrollViewWithPage:page];
			}
			
			EGOPhotoImageView *_photoView = (EGOPhotoImageView*)[self.photoViews objectAtIndex:page];
			CGRect newframe = CGRectMake(originX, 0.0f, self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
			
			if (!CGRectEqualToRect(_photoView.frame, newframe)) {	
				
				[UIView beginAnimations:nil context:NULL];
				[UIView setAnimationDuration:0.1];
				_photoView.frame = newframe;
				[UIView commitAnimations];
			
			}
			
		}
	}
	
}

- (void)setupScrollViewContentSize{
	
	CGFloat toolbarSize = _popover ? 0.0f : self.navigationController.toolbar.frame.size.height;	
	
	CGSize contentSize = self.view.bounds.size;
	contentSize.width = (contentSize.width * [self.photoSource numberOfPhotos]);
	
	if (!CGSizeEqualToSize(contentSize, self.scrollView.contentSize)) {
		self.scrollView.contentSize = contentSize;
	}
	
	_captionView.frame = CGRectMake(0.0f, self.view.bounds.size.height - (toolbarSize + 40.0f), self.view.bounds.size.width, 40.0f);

}

- (void)enqueuePhotoViewAtIndex:(NSInteger)theIndex{
	
	NSInteger count = 0;
	for (EGOPhotoImageView *view in self.photoViews){
		if ([view isKindOfClass:[EGOPhotoImageView class]]) {
			if (count > theIndex+1 || count < theIndex-1) {
				[view prepareForReusue];
				[view removeFromSuperview];
			} else {
				view.tag = 0;
			}
			
		} 
		count++;
	}	
	
}

- (EGOPhotoImageView*)dequeuePhotoView{
	
	NSInteger count = 0;
	for (EGOPhotoImageView *view in self.photoViews){
		if ([view isKindOfClass:[EGOPhotoImageView class]]) {
			if (view.superview == nil) {
				view.tag = count;
				return view;
			}
		}
		count ++;
	}	
	return nil;
	
}

- (void)loadScrollViewWithPage:(NSInteger)page {
	
    if (page < 0) return;
    if (page >= [self.photoSource numberOfPhotos]) return;
    
    DLog(@"loading scrollview page %d", page);
	
	EGOPhotoImageView * photoView = [self.photoViews objectAtIndex:page];
	if ((NSNull*)photoView == [NSNull null]) {
		
		photoView = [self dequeuePhotoView];
		if (photoView != nil) {
			[self.photoViews exchangeObjectAtIndex:photoView.tag withObjectAtIndex:page];
			photoView = [self.photoViews objectAtIndex:page];
		}
		
	}
	
	if (photoView == nil || (NSNull*)photoView == [NSNull null]) {
		
        // MRB: switched to autorelease because continues to be referenced below
		photoView = [[[EGOPhotoImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.scrollView.bounds.size.width, self.scrollView.bounds.size.height)] autorelease];
		[self.photoViews replaceObjectAtIndex:page withObject:photoView];
//		[photoView release];
		
	} 
	
    id<EGOPhoto> newPhoto = [self.photoSource photoAtIndex:page];
	[photoView setPhoto:newPhoto];
	
    if (photoView.superview == nil) {
		[self.scrollView addSubview:photoView];
	}
	
	CGRect frame = self.scrollView.frame;
	NSInteger centerPageIndex = _pageIndex;
	CGFloat xOrigin = (frame.size.width * page);
	if (page > centerPageIndex) {
		xOrigin = (frame.size.width * page) + EGOPV_IMAGE_GAP;
	} else if (page < centerPageIndex) {
		xOrigin = (frame.size.width * page) - EGOPV_IMAGE_GAP;
	}
	
	frame.origin.x = xOrigin;
	frame.origin.y = 0;
	photoView.frame = frame;
}


#pragma mark -
#pragma mark UIScrollView Delegate Methods


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	NSInteger index = [self centerPhotoIndex];
	if (index >= [self.photoSource numberOfPhotos] || index < 0) {
		return;
	}
	
    DLog(@"scrollViewDidScroll cpi = %d, pageIndex = %d, rotating = %d", index, _pageIndex, _rotating);
	if (_pageIndex != index && !_rotating) {
		[self setBarsHidden:YES animated:YES];
		_pageIndex = index;
		[self setViewState];
		
		if (![scrollView isTracking]) {
			[self layoutScrollViewSubviews];
		}
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	NSInteger index = [self centerPhotoIndex];
	if (index >= [self.photoSource numberOfPhotos] || index < 0) {
		return;
	}
	
	[self moveToPhotoAtIndex:index animated:YES];

}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView{
	[self layoutScrollViewSubviews];
}


#pragma mark -
#pragma mark Actions

//- (void)doneSavingImage{
//	DLog(@"done saving image");
//}

- (void)savePhoto {
    UIImageWriteToSavedPhotosAlbum(((EGOPhotoImageView*)[self.photoViews objectAtIndex:_pageIndex]).imageView.image, nil, nil, nil);
    
}
- (void)uploadPhoto {
    ACLocalPhoto *acp = [_photoSource photoAtIndex:_pageIndex];
    // this should never really fire, because the uploader will restrict access
    if (_numUploadsRunningNow >= kMaxSimultaneousUploadsForUI) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Max uploads reached"
                                                            message:[NSString stringWithFormat:@"There are %d uploads running.  Please wait a few minutes and try again", _numUploadsRunningNow]
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        return;
        
    }
    if (acp.isUploaded) {
        RIButtonItem *cancelItem = [RIButtonItem item];
        cancelItem.label = @"No fanks";
        cancelItem.action = nil;
        
        RIButtonItem *uploadAnyway = [RIButtonItem item];
        uploadAnyway.label = @"Upload anyway";
        uploadAnyway.action = ^ {
            [self doUploadPhoto:acp];
        };
        
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Already uploaded"
                                  message:@"This image is already uploaded!"
                                  cancelButtonItem:cancelItem
                                  otherButtonItems:uploadAnyway, nil];
        [alertView show];
        [alertView release];
    }
    else {
        [self doUploadPhoto:acp];
    }
    
}

- (void)doUploadPhoto:(ACLocalPhoto *)acp {
    DLog(@"upload to S3 starting");
    _totalUploadsInProgressView += 1;
    _numUploadsRunningNow += 1;
    ACLocalPhotoManager *localPhotoManager = [ACLocalPhotoManager sharedInstance];
    [localPhotoManager setUploadStatus:UploadStatusPreDispatch forImage:acp];
    [self setViewState];
    
    NSString *albumname = [acp defaultAlbumName];
    ACAppDelegate *del = (ACAppDelegate *)[[UIApplication sharedApplication] delegate];
    __block int nProgressUpdatesIgnored = -1;
    DLog(@"upload of '%@' to '%@' starting", acp, albumname);
    [del upload:acp
      albumname:albumname
     // HACK: this will only work for one upload at a time
       progress:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
           if ((nProgressUpdatesIgnored++ > 10 ||
                nProgressUpdatesIgnored == -1 ||
                bytesWritten == totalBytesExpectedToWrite) &&
               !_rotating) {
               _bytesUploaded = totalBytesWritten;
               _totalBytesToUploadInProgressView = totalBytesExpectedToWrite;
               [self performSelectorOnMainThread:@selector(setUploadProgressView)
                                      withObject:nil
                                   waitUntilDone:NO];
               
               nProgressUpdatesIgnored = 0;
           }
           
       }
        success:^(ACLocalPhoto *photo) {
            DLog(@"upload of '%@' to '%@' FINISHING", photo, albumname);
            // gotcha... need to set upload status before setting image is uploaded
            // because the underlying dictionary takes the photo description as at
            // when setImageIsUploaded is called
            [localPhotoManager setUploadStatus:UploadStatusFinished forImage:photo];
            //             [_photoSource setImageIsUploaded:photo];
            // HACK: this is written atomically to a sharedInstance... but could we get
            // contention or dirty read problems here?
            [localPhotoManager writeUploadedImagesToFile];
            DLog(@"upload of '%@' to '%@' FINISHED", photo, albumname);
            [self performSelectorOnMainThread:@selector(setViewState)
                                   withObject:nil
                                waitUntilDone:NO];
            _numUploadsRunningNow -= 1;
            _currentUploadIndex += 1;
        }
        failure:^(NSError *error) {
            [self performSelectorOnMainThread:@selector(setViewState)
                                   withObject:nil
                                waitUntilDone:NO];
            _numUploadsRunningNow -= 1;
            _currentUploadIndex += 1;
            
        }];
    
}


- (void)copyPhoto{
	
	[[UIPasteboard generalPasteboard] setData:UIImagePNGRepresentation(((EGOPhotoImageView*)[self.photoViews objectAtIndex:_pageIndex]).imageView.image) forPasteboardType:@"public.png"];
	
}

- (void)emailPhoto{
	
	MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
	[mailViewController setSubject:@"Shared Photo"];
	[mailViewController addAttachmentData:[NSData dataWithData:UIImagePNGRepresentation(((EGOPhotoImageView*)[self.photoViews objectAtIndex:_pageIndex]).imageView.image)] mimeType:@"image/png" fileName:@"Photo.png"];
	mailViewController.mailComposeDelegate = self;
	
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad) {
		mailViewController.modalPresentationStyle = UIModalPresentationPageSheet;
	}
#endif
	
	[self presentModalViewController:mailViewController animated:YES];
	[mailViewController release];
	
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error{
	
	[self dismissModalViewControllerAnimated:YES];
	
	NSString *mailError = nil;
	
	switch (result) {
		case MFMailComposeResultSent: ; break;
		case MFMailComposeResultFailed: mailError = @"Failed sending media, please try again...";
			break;
		default:
			break;
	}
	
	if (mailError != nil) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:mailError delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
	
}


#pragma mark -
#pragma mark UIActionSheet Methods

- (void)actionButtonHit:(id)sender{
	
	UIActionSheet *actionSheet;
	
    NSString *saveButtonTitle = [_photoSource isKindOfClass:[ACLocalAlbum class]] ? @"Upload" : @"Save";
	if ([MFMailComposeViewController canSendMail]) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && !_popover) {
			actionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:saveButtonTitle, @"Copy", @"Email", nil];
		} else {
			actionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:saveButtonTitle, @"Copy", @"Email", nil];
		}
#else
		actionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:saveButtonTitle, @"Copy", @"Email", nil];
#endif
		
	} else {
		
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && !_popover) {
			actionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:saveButtonTitle, @"Copy", nil];
		} else {
			actionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:saveButtonTitle, @"Copy", nil];
		}
#else
		actionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:saveButtonTitle, @"Copy", nil];
#endif
		
	}
	
	actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
	actionSheet.delegate = self;
	
	[actionSheet showInView:self.view];
	[self setBarsHidden:YES animated:YES];
	
	[actionSheet release];
	
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
	
	[self setBarsHidden:NO animated:YES];
	
	if (buttonIndex == actionSheet.cancelButtonIndex) {
		return;
	} else if (buttonIndex == actionSheet.firstOtherButtonIndex) {
        if ([_photoSource isKindOfClass:[ACLocalAlbum class]])
            [self uploadPhoto];
        else
            [self savePhoto];
	} else if (buttonIndex == actionSheet.firstOtherButtonIndex + 1) {
		[self copyPhoto];	
	} else if (buttonIndex == actionSheet.firstOtherButtonIndex + 2) {
		[self emailPhoto];	
	}
}


#pragma mark -
#pragma mark Memory

- (void)didReceiveMemoryWarning{
	[super didReceiveMemoryWarning];
    
    DLog(@"EGOPhotoViewController received memory warning");
}

- (void)viewDidUnload{
	
	self.photoViews=nil;
	self.scrollView=nil;
	_captionView=nil;
	
}

- (void)dealloc {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	_captionView=nil;
	[_photoViews release], _photoViews=nil;
	[_photoSource release], _photoSource=nil;
	[_scrollView release], _scrollView=nil;
	[_oldToolBarTintColor release], _oldToolBarTintColor = nil;
	[_oldNavBarTintColor release], _oldNavBarTintColor = nil;
	
    [super dealloc];
}


@end
