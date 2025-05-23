//
//  UINavigationControllerModelControllers.m
//  Reports
//
//  Created by Michael Thomason on 2/10/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADNavigationController.h"

#import <UIKit/UIStoryboard.h>
#import <UIKit/UIViewController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UITabBarController.h>
#import <UIKit/UIToolbar.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/UIViewController.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import "MADNavigationControllerViewer.h"
#import "MADNavigationControllerDesigner.h"
#import "MADNavigationControllerQuery.h"

#import "MADDesignerNavigationBar.h"
#import "MADViewerNavigationBar.h"

#import "MADTransparentPresentationController.h"

@interface MADNavigationController ()
	@property (readwrite, nonatomic, assign) MADNavigationControllerType controllerType;
@end

@implementation MADNavigationController

@dynamic document;

+ (void)initialize {
	[super initialize];
	if (self == [MADNavigationController self]) {
		@autoreleasepool {
			NSArray<Class <UIAppearanceContainer>> * classes;
			UIToolbar *toolbar;
			
			classes = [[NSArray alloc] initWithObjects: self, nil];

			toolbar = [UIToolbar appearanceWhenContainedInInstancesOfClasses:classes];
			UIColor *white, *blue;
			white = [MADColorEverydayApps newColorWhite];
			blue = [MADColorEverydayApps newColorBlue];
			toolbar.tintColor = white;
			toolbar.barTintColor = blue;
			toolbar.barStyle = UIBarStyleBlack;
			toolbar.translucent = YES;
		}
	}
}

+ (instancetype)newNavigationController:(MADNavigationControllerType)type {

	id controller = nil, controllerID = nil,
		storyboardID = nil, bundle = nil, storyboard = nil;
	
	switch (type) {

		case MADNavigationControllerTypeInformation:
			storyboardID = @"MADAboutApp";
			controllerID = @"MADIdentifierNavControllerInfo";
			bundle = [NSBundle mainBundle];
			break;
			
		case MADNavigationControllerTypeLicensing:
			storyboardID = @"MADStore";
			controllerID = @"MADIdentifierNavControllerStore";
			bundle = [NSBundle mainBundle];
			break;
			
		case MADNavigationControllerTypeNewDocument:
			storyboardID = @"MADCreateDocument";
			controllerID = @"MADIdentifierNavControllerCreateDoc";
			bundle = [NSBundle mainBundle];
			break;
			
		case MADNavigationControllerTypeToolbox:
			storyboardID = @"MADDesignerToolbox";
			bundle = [NSBundle mainBundle];
			break;
			
		case MADNavigationControllerTypeFontPicker:
			storyboardID = @"MADDesignerToolbox";
			controllerID = @"MADIdentifierNavControllerFontPicker";
			bundle = [NSBundle mainBundle];
			break;

		case MADNavigationControllerTypeAggregateAdd:
			storyboardID = @"MADDesignerObjectSelector";
			controllerID = @"MADIdentifierNavControllerAggregate";
			bundle = [NSBundle mainBundle];
			break;
			
		case MADNavigationControllerTypeElementPicker:
			storyboardID = @"MADDesignerObjectSelector";
			controllerID = @"MADIdentifierNavControllerObjectSelector";
			bundle = [NSBundle mainBundle];
			break;
			
		case MADNavigationControllerTypeViewer:
			controller = [[MADNavigationControllerViewer alloc] initWithNavigationBarClass: [MADViewerNavigationBar class]
																			  toolbarClass: nil];
			break;
			
		case MADNavigationControllerTypeDesigner:
			controller = [[MADNavigationControllerDesigner alloc] initWithNavigationBarClass: [MADDesignerNavigationBar class]
																				toolbarClass: nil];
			break;

		case MADNavigationControllerTypeQuery:
			controller = [[MADNavigationControllerQuery alloc] init];
			break;

		default:
			break;
	}
	
	if (controller == nil) {
		if (storyboardID != nil) {
			
			storyboard = [UIStoryboard storyboardWithName: storyboardID bundle: bundle];
			controller = controllerID != nil ?
				[storyboard instantiateViewControllerWithIdentifier: controllerID] :
				[storyboard instantiateInitialViewController];
			
		} else {
			controller = [[self alloc] initWithNavigationBarClass: nil
													 toolbarClass: nil];
		}
	}

	if ([controller respondsToSelector:@selector(setControllerType:)]) {
		[controller setControllerType: type];
	}
	
	return controller;
}

#pragma mark -
#pragma mark IBActions

- (IBAction)done:(id)sender {
	for (UIViewController *viewController in self.childViewControllers) {
		if ([viewController respondsToSelector:@selector(done:)]) {
			[viewController performSelectorOnMainThread: @selector(done:)
											 withObject: self
										  waitUntilDone: NO];
		}
	}
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

@end
