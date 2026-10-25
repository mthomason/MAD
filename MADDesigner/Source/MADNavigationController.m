//
//  UINavigationControllerModelControllers.m
//  Reports
//
//  Created by Michael Thomason on 2/10/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADNavigationController.h"
#import "MADNavigationControllerViewer.h"
#import "MADNavigationControllerDesigner.h"
#import "MADDesignerNavigationBar.h"
#import "MADViewerNavigationBar.h"
#import "MADNavigationControllerToolbox.h"
#import "MADTransparentPresentationController.h"
#import "MADThemeManager.h"
// Deliberately the system header, not <MADFoundation/madlog.h>: this file logs
// with OS_LOG_DEFAULT and is compiled by the stand-alone MAD Viewer target,
// which links no MAD frameworks.
#import <os/log.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import <UIKit/UIStoryboard.h>
#import <UIKit/UIViewController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UITabBarController.h>
#import <UIKit/UIToolbar.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/UIViewController.h>

@interface MADNavigationController ()
	@property (readwrite, nonatomic, assign) MADNavigationControllerType controllerType;
	@property (nonatomic, copy) void (^popCompletionBlock)(void);
@end

@implementation MADNavigationController

@dynamic document;

- (void)viewDidLoad {
	[super viewDidLoad];
	self.delegate = self;
	[MADThemeManager applyAppearanceToNavigationController:self traitCollection:self.traitCollection];
}


#pragma mark -
#pragma mark IBActions

- (IBAction)done:(id)sender {
	[self done:sender completion:nil];
}

- (void)done:(id)sender completion:(void(^)(void))completion {
	self.popCompletionBlock = completion;
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

#pragma mark -
#pragma mark UINavigationControllerDelegate

// This delegate method is called after a view controller is popped and the transition is complete.
- (void)navigationController:(UINavigationController *)navigationController
	   didShowViewController:(UIViewController *)viewController
					animated:(BOOL)animated {
	// If a completion block is pending, execute it now and then clear it.
	if (self.popCompletionBlock) {
		self.popCompletionBlock();
		self.popCompletionBlock = nil;
	}
}

@end

@implementation UINavigationController (Constructors)

+ (UINavigationController *)navigationControllerWithType:(MADNavigationControllerType)type {
	switch (type) {
		case MADNavigationControllerTypeInformation:
			return [[UIStoryboard storyboardWithName: @"MADAboutApp" bundle: [NSBundle mainBundle]] instantiateViewControllerWithIdentifier: @"MADIdentifierNavControllerInfo"];
		case MADNavigationControllerTypeLicensing:
			return [[UIStoryboard storyboardWithName: @"MADStore" bundle: [NSBundle mainBundle]] instantiateViewControllerWithIdentifier: @"MADIdentifierNavControllerStore"];
		case MADNavigationControllerTypeNewDocument:
			return [[UIStoryboard storyboardWithName: @"MADCreateDocument" bundle: [NSBundle mainBundle]] instantiateViewControllerWithIdentifier: @"MADIdentifierNavControllerCreateDoc"];
		case MADNavigationControllerTypeFontPicker:
			return [[UIStoryboard storyboardWithName: @"MADDesignerToolbox" bundle: [NSBundle mainBundle]] instantiateViewControllerWithIdentifier: @"MADIdentifierNavControllerFontPicker"];
		case MADNavigationControllerTypeAggregateAdd:
			return [[UIStoryboard storyboardWithName: @"MADDesignerObjectSelector" bundle: [NSBundle mainBundle]] instantiateViewControllerWithIdentifier: @"MADIdentifierNavControllerAggregate"];
		case MADNavigationControllerTypeElementPicker:
			return [[UIStoryboard storyboardWithName: @"MADDesignerObjectSelector" bundle: [NSBundle mainBundle]] instantiateViewControllerWithIdentifier: @"MADIdentifierNavControllerObjectSelector"];
		case MADNavigationControllerTypeToolbox:
			return [[UIStoryboard storyboardWithName: @"MADDesignerToolbox" bundle: [NSBundle mainBundle]] instantiateInitialViewController];
		default:
			os_log_error(OS_LOG_DEFAULT, "Error: Unknown Navigation Controller Type");
			@throw [NSException exceptionWithName: NSInternalInconsistencyException
										   reason: @"MADNavigationController: newNavigationControllerWithType: called with unsupported type."
										 userInfo: nil];
	}
}

+ (UINavigationController <MADViewControllerDocumentProtocol> *)documentNavigationControllerWithType:(MADNavigationControllerType)type
																							document:(MADocument *)document {
	switch (type) {
		case MADNavigationControllerTypeViewer: {
			UINavigationController <MADViewControllerDocumentProtocol, MADNavigationProtocol> *controller = [[MADNavigationControllerViewer alloc] initWithNavigationBarClass: [MADViewerNavigationBar class]
																																								 toolbarClass: nil];
			controller.document = document;
			return controller;
		}
		case MADNavigationControllerTypeDesigner: {
			UINavigationController <MADViewControllerDocumentProtocol, MADNavigationProtocol> * controller = [[MADNavigationControllerDesigner alloc] initWithNavigationBarClass: [MADDesignerNavigationBar class]
																																									toolbarClass: nil];
			controller.document = document;
			return controller;
		}
		default:
			os_log_error(OS_LOG_DEFAULT, "Error: Unknown Navigation Controller Type");
			@throw [NSException exceptionWithName: NSInternalInconsistencyException
										   reason: @"MADNavigationController: newNavigationControllerWithType:document: called with unsupported type."
										 userInfo: nil];
	}
}

@end
