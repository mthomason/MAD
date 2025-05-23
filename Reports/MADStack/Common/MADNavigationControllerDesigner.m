//
//  MADNavigationControllerDesigner.m
//  MAD Designer
//
//  Created by Michael on 2/18/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADNavigationControllerDesigner.h"
#import "MADDesignerViewController.h"

@interface MADNavigationControllerDesigner ()
	@property (nonatomic, strong) MADDesignerViewController *designerController;
@end

@implementation MADNavigationControllerDesigner

@synthesize title = _title;
@synthesize document = _document;

- (void)viewDidLoad {
	[super viewDidLoad];
	id rootViewController = [MADDesignerViewController newDesignerViewController: _document];
	self.designerController = rootViewController;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (self.viewControllers.count == 0) {
		[self pushViewController:self.designerController animated:animated];
	}
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	if (self.isBeingDismissed) {
		NSArray *viewControllers = [[NSArray alloc] init];
		[self setViewControllers:viewControllers animated:animated];
	}
}

+ (UIImage *)TabBarImage {
	return [MADDesignerViewController TabBarImage];
}

- (NSString *)title {
	if (_title == nil) {
		_title = self.designerController == nil ? [MADDesignerViewController Title] : self.designerController.title;
	}
	return _title;
}

- (void)setDocument:(MADocument *)document {
	if (_document != document) {
		_document = document;
	}
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

@end
