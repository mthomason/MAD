//
//  MADNavigationControllerQuery.m
//  MAD Designer
//
//  Created by Michael on 2/18/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADNavigationControllerQuery.h"
#import "MADQueryBuilderSplitViewController.h"

@interface MADNavigationControllerQuery ()
	@property (nonatomic, strong) MADQueryBuilderSplitViewController *queryController;
@end

@implementation MADNavigationControllerQuery

@synthesize title = _title;
@synthesize document = _document;

- (void)viewDidLoad {
	[super viewDidLoad];
	id rootViewController = [MADQueryBuilderSplitViewController newQueryBuilderSplitViewController: _document];
	self.queryController = rootViewController;
}

- (UIViewController *)topViewController {
	return self.queryController;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	if (self.isBeingDismissed) {
		NSArray *viewControllers = [[NSArray alloc] init];
		[self setViewControllers:viewControllers animated:animated];
	}
}

+ (UIImage *)TabBarImage {
	return [MADQueryBuilderSplitViewController TabBarImage];
}

- (NSString *)title {
	if (_title == nil) {
		_title = self.queryController == nil ?
					[MADQueryBuilderSplitViewController Title] : self.queryController.title;
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
