//
//  MADToolboxViewController.m
//  MAD
//
//  Created by Michael Thomason on 10/28/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADToolboxViewController.h"
#import "MADToolboxControllerProtocol.h"
#import "MADNavigationController.h"
#import "MADViewControllerDocumentProtocol.h"
#import "MADThemeManager.h"

#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import <UIKit/UIAppearance.h>
#import <UIKit/UIStoryboard.h>
#import <UIKit/UIAccessibility.h>
#import <UIKit/UIPresentationController.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UISegmentedControl.h>
#import <UIKit/UITableViewController.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIGraphics.h>

NSString * const MADIdentifierStoryboardLayout      = @"MADIdentifierStoryboardLayout";
NSString * const MADIdentifierStoryboardFormat      = @"MADIdentifierStoryboardFormat";
NSString * const MADIdentifierStoryboardStyle       = @"MADIdentifierStoryboardStyle";

const CGFloat MADNavigationBarSizeHeightNormal = 44.0000f;
const CGFloat MADNavigationBarSizeHeightConstrained = 32.0000f;

typedef UIViewController <MADToolboxControllerProtocol, MADToolboxDisplayProtocol, MADViewControllerDocumentProtocol> MADToolboxPanel;
typedef UITableViewController <MADToolboxControllerProtocol, MADToolboxDisplayProtocol, MADViewControllerDocumentProtocol> MADToolboxPanelTable;


@interface MADToolboxViewController ()

@property (nonatomic, assign) UIModalTransitionStyle segmentedControlActionStyle;
@property (nonatomic, strong) MADToolboxPanel *layout;
@property (nonatomic, strong) MADToolboxPanel *format;

@property (nonatomic, weak) IBOutlet UISegmentedControl *sceneSelector;
@property (nonatomic, weak) IBOutlet UINavigationItem *navigationItemSceneSelector;

@property (nonatomic, weak) UIViewController *currentViewController;
@property (nonatomic, strong) UINavigationController *styleNavigationController;

@end

@implementation MADToolboxViewController

@synthesize document = _document;

#pragma mark -
#pragma mark Static

+ (void)initialize {
    [super initialize];
    if (self == [MADToolboxViewController class]) {
        @autoreleasepool {
            UISegmentedControl *controlAppearance;
            id classes;
            classes = [[NSArray alloc] initWithObjects:[UINavigationBar class], nil];
            controlAppearance = [UISegmentedControl appearanceWhenContainedInInstancesOfClasses: classes];
            controlAppearance.tintColor = [UIColor whiteColor];
        }
    }
}

+ (instancetype)newToolboxViewController {
    UIStoryboard *storyboard;
    id toolbox;
    
    storyboard = [UIStoryboard storyboardWithName: @"MADDesignerToolbox"
                                           bundle: [NSBundle mainBundle]];
    toolbox = [storyboard instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardToolbox"];
    return toolbox;
}

+ (NSString *)keyPathSelectedObjectIds {
    NSString *selectedElementIDs = NSStringFromSelector(@selector(selectedElementIDs));
    return selectedElementIDs;
}

- (CGSize)preferredContentSize {
    switch (self.sceneSelector.selectedSegmentIndex) {
        case 0:
            return CGSizeMake(320.0000, 240.0000f);
            break;
        case 1:
            return CGSizeMake(320.0000, 480.0000f);
            break;
        case 2:
            return CGSizeMake(320.0000, 280.0000f);
            break;
        default:
            return CGSizeMake(320.0000f, 480.0000f);
    }
}

#pragma mark -
#pragma mark View Controller

- (void)dealloc {

    [self removeObserver: self
              forKeyPath: NSStringFromSelector(@selector(document))];

    [self removeObserver: self
              forKeyPath: [MADToolboxViewController keyPathSelectedObjectIds]];
    
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {

    if (self = [super initWithCoder:aDecoder]) {
		UIStoryboard *storyboard = [UIStoryboard storyboardWithName: @"MADDesignerToolbox" bundle: [NSBundle mainBundle]];
		self.layout = [storyboard instantiateViewControllerWithIdentifier:MADIdentifierStoryboardLayout];
		self.format = [storyboard instantiateViewControllerWithIdentifier:MADIdentifierStoryboardFormat];

		UINavigationController *navigationController = [UINavigationController navigationControllerWithType: MADNavigationControllerTypeFontPicker];
		[MADThemeManager applyAppearanceToNavigationController:navigationController traitCollection:self.traitCollection];

		self.styleNavigationController = navigationController;
		self.currentViewController = self.styleNavigationController;
		self.segmentedControlActionStyle = UIModalTransitionStyleCoverVertical;
		
		
		[self addObserver: self
			   forKeyPath: [MADToolboxViewController keyPathSelectedObjectIds]
				  options: (NSKeyValueObservingOptions)0
				  context: NULL];
		
		[self addObserver: self
			   forKeyPath: NSStringFromSelector(@selector(document))
				  options: (NSKeyValueObservingOptions)0
				  context: NULL];
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.modalPresentationStyle = UIModalPresentationPopover;
	self.modalTransitionStyle = self.segmentedControlActionStyle;
	
	self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
	self.navigationController.navigationBar.translucent = YES;
	self.sceneSelector.tintColor = [UIColor whiteColor];
	self.navigationController.navigationBar.barTintColor = [MADColorEverydayApps newColorBlue];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.styleNavigationController popToRootViewControllerAnimated:animated];
	
	self.clearsBackground = self.clearsBackground;
	MADToolboxPanelTable *style = (MADToolboxPanelTable *)self.styleNavigationController.viewControllers.firstObject;
	[style setDocument:self.document];
	[style setSelectedDocumentObjects:self.selectedElementIDs];
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];
	if (self.childViewControllers.count == 0) {
		[self showInitalChildViewController];
	}
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	self.sceneSelector.center = CGPointMake(self.view.center.x, self.navigationItem.titleView.center.y);
}

#pragma mark -
#pragma mark Helpers

- (void)showInitalChildViewController {
	UIViewController *viewControllerToShow = self.styleNavigationController;
	self.currentViewController = viewControllerToShow;
	
	MADToolboxPanelTable *viewControllerToUpdate = (MADToolboxPanelTable *)self.styleNavigationController.viewControllers.firstObject;
	[viewControllerToUpdate setSelectedDocumentObjects: self.selectedElementIDs];
	viewControllerToUpdate.document = self.document;
	viewControllerToShow.modalPresentationStyle = UIModalPresentationOverCurrentContext;
	viewControllerToShow.modalTransitionStyle = self.segmentedControlActionStyle;
	viewControllerToShow.view.frame = self.view.bounds;
	[self addChildViewController:viewControllerToShow];
	[viewControllerToShow beginAppearanceTransition:YES animated:NO];
	[self.view addSubview:viewControllerToShow.view];
	[viewControllerToShow didMoveToParentViewController:self];
	[viewControllerToShow endAppearanceTransition];
}

- (void)showStyleViewController {
	
	MADToolboxPanel *viewControllerToUpdate = (MADToolboxPanel *)self.styleNavigationController.viewControllers.firstObject;
	UIViewController *viewControllerToShow = self.styleNavigationController;
	self.currentViewController = viewControllerToShow;
	
	UIViewAnimationOptions options = UIViewAnimationOptionTransitionFlipFromRight;
	options = UIViewAnimationOptionTransitionCrossDissolve;
	[viewControllerToUpdate setSelectedDocumentObjects: self.selectedElementIDs];
	viewControllerToUpdate.document = self.document;
	viewControllerToShow.modalPresentationStyle = UIModalPresentationOverCurrentContext;
	viewControllerToShow.modalTransitionStyle = self.segmentedControlActionStyle;
	
	UIViewController *viewControllerToHide = self.childViewControllers.firstObject;
	viewControllerToShow.view.frame = self.view.bounds;
	
	[self addChildViewController:viewControllerToShow];
	[viewControllerToHide willMoveToParentViewController:nil];
	[viewControllerToShow beginAppearanceTransition:YES animated:YES];
	[self.styleNavigationController.topViewController beginAppearanceTransition:YES animated:YES];
	
	[self transitionFromViewController: viewControllerToHide
					  toViewController: viewControllerToShow
							  duration: 0.23232323f
							   options: options
							animations:^{ } completion:^(BOOL finished) {
		
		if (!finished) return;
		
		[viewControllerToHide removeFromParentViewController];
		[viewControllerToShow didMoveToParentViewController:self];
		[((UINavigationController *)viewControllerToShow).topViewController didMoveToParentViewController:self];
		
		
	}];
	
}

#pragma mark -
#pragma mark Accessors

- (void)setClearsBackground:(BOOL)clearsBackground {
	_clearsBackground = clearsBackground;
	self.layout.clearsBackground = clearsBackground;
	self.format.clearsBackground = clearsBackground;
	for (UIViewController <MADToolboxDisplayProtocol> *viewController in self.styleNavigationController.viewControllers) {
		viewController.clearsBackground = clearsBackground;
	}
}

- (IBAction)done:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (MADToolboxPanel *)delegateForController:(UIViewController *)controller {
	MADToolboxPanel *delegate;
	if ([controller isKindOfClass:[UINavigationController class]]) {
		delegate = (MADToolboxPanel *)((UINavigationController *)controller).viewControllers.firstObject;
	} else {
		delegate = (MADToolboxPanel *)controller;
	}
	return delegate;
}

#pragma mark -
#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary <NSKeyValueChangeKey, id> *)change
					   context:(void *)context {
	
	if ([keyPath isEqualToString:NSStringFromSelector(@selector(document))]) {
		
		id <MADViewControllerDocumentProtocol> delegate = [self delegateForController:self.childViewControllers.firstObject];
		[delegate setDocument:self.document];
		
	} else if ([keyPath isEqualToString:[MADToolboxViewController keyPathSelectedObjectIds]]) {
		
		id <MADToolboxControllerProtocol> delegate;
		delegate = [self delegateForController:self.childViewControllers.firstObject];
		[delegate setSelectedDocumentObjects:self.selectedElementIDs];
		
	}
}

#pragma mark -
#pragma mark Accessors

- (IBAction)valueChanged:(id)sender {
	
	UIViewController *viewControllerToShow = nil;
	MADToolboxPanel *viewControllerToUpdate = nil;
	
	switch (((UISegmentedControl *)sender).selectedSegmentIndex) {
			
		case 0:
			[self showStyleViewController];   //Handles this case alone...
			self.preferredContentSize = CGSizeMake(320.0000f, 480.0000f);
			return;
			break;
			
		case 1:
			self.preferredContentSize = CGSizeMake(320.0000f, 480.0000f);
			viewControllerToShow = self.layout;
			viewControllerToUpdate = self.layout;
			break;
			
		case 2:
			self.preferredContentSize = CGSizeMake(320.0000f, 480.0000f);
			viewControllerToShow = self.format;
			viewControllerToUpdate = self.format;
			break;
			
		default:
			self.preferredContentSize = CGSizeMake(320.0000f, 480.0000f);
			viewControllerToShow = self.layout;
			viewControllerToUpdate = self.layout;
			break;
	}
	
	self.currentViewController = viewControllerToShow;
	
	UIViewAnimationOptions options = UIViewAnimationOptionTransitionCrossDissolve;
	viewControllerToUpdate.document = self.document;
	[viewControllerToUpdate setSelectedDocumentObjects: self.selectedElementIDs];
	viewControllerToShow.modalPresentationStyle = UIModalPresentationOverCurrentContext;
	viewControllerToShow.modalTransitionStyle = self.segmentedControlActionStyle;
	
	UIViewController *viewControllerToHide = self.childViewControllers.firstObject;
	
	viewControllerToShow.view.frame = self.view.bounds;
	
	MADToolboxViewController * __weak weakself = self;
	[self addChildViewController:viewControllerToShow];
	[viewControllerToHide willMoveToParentViewController:nil];
	[viewControllerToShow beginAppearanceTransition:YES animated:YES];
	
	
	[self transitionFromViewController: viewControllerToHide
					  toViewController: viewControllerToShow
							  duration: 0.23232323f
							   options: options
							animations:^{
		
	} completion:^(BOOL finished) {
		if (finished) {
			[viewControllerToHide removeFromParentViewController];
			[viewControllerToShow didMoveToParentViewController:weakself];
			[viewControllerToShow endAppearanceTransition];
		}
	}];
}

#pragma mark -
#pragma mark Accessibility

- (BOOL)accessibilityPerformEscape {
	return [self.navigationController.presentationController accessibilityPerformEscape];
}

@end
