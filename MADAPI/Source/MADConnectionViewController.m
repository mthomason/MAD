//
//  MADConnectionViewController.m
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADConnectionViewController.h"
#import "MADViewControllerStandardProtocol.h"
#import "MADDatabaseConnection.h"
#import "MADErrorContainer.h"

#import <MADFoundation/MADProgress.h>
#import <MADFoundation/MADNotificationProgress.h>
#import <MADFoundation/MADKeyChain.h>

#import <UIKit/UIAccessibility.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UIActivityIndicatorView.h>
#import <UIKit/UIViewControllerTransitioning.h>
#import <UIKit/UIProgressView.h>


typedef void (^MADBlockAlertDidFinish)(UIAlertAction *);
typedef void (^MADBlockCompletionStatus)(BOOL);

@interface MADConnectionViewController () <UITableViewDelegate, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning, UITextFieldDelegate>

@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, assign) SEL actionSave;
@property (nonatomic, weak) id actionSaveTarget;

- (IBAction)save:(id)sender;

@end

@implementation MADConnectionViewController

#pragma mark -
#pragma mark NSObject

+ (void)viewController:(id)viewController
		 displayErrors:(NSArray <__kindof NSError *> *)errors
			completion:(void (^)(BOOL))completion {

	NSError *error = [errors lastObject];
	NSRange range = NSMakeRange(0, errors.count > 0 ? errors.count - 1 : 0);
	NSArray <__kindof NSError *> *remaningErrors = [errors subarrayWithRange:range];

	MADBlockAlertDidFinish handleAlertDidFinish = ^(UIAlertAction *__unused action) {

		if (remaningErrors.count > 0) {
			
			MADBlockCompletionStatus alertCompleted = ^(BOOL __unused success) { completion(YES); };
			[MADConnectionViewController viewController:viewController
										  displayErrors:remaningErrors
											 completion:alertCompleted];
		} else {
			if (completion != nil) completion(YES);
		}
		
	};
	
	NSString *localizedDescription = [error.localizedDescription copy];
	NSString *localizedFailureReason = [error.localizedFailureReason copy];

	UIAlertController *alert = [MADAlertController newAlertControllerErrorDisplayErrorWithTitle: localizedDescription
																						message: localizedFailureReason
																				  andCompletion: handleAlertDidFinish];

	[viewController presentViewController:alert animated:YES completion:nil];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
		progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		progressView.progressTintColor = [MADColorEverydayApps newColorAnalogous4];
		progressView.trackTintColor = [UIColor grayColor];
		self.progressView = progressView;
	}
	return self;
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.actionSave = self.navigationItem.rightBarButtonItem.action;
	self.actionSaveTarget = self.navigationItem.rightBarButtonItem.target;
	
	self.navigationItem.prompt = NSLocalizedString(@"Each report requires a database connection.", @"Each report requires a database connection.");
	self.title = NSLocalizedString(@"Database Settings", @"Database Settings");
	self.clearsSelectionOnViewWillAppear = YES;
	self.navigationItem.hidesBackButton = NO;
	self.navigationItem.leftItemsSupplementBackButton = YES;
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

	self.textFieldReportName.clearButtonMode = UITextFieldViewModeAlways;
	
	MADLabelTitle *titleView = [[MADLabelTitle alloc] initWithFrame:CGRectZero];
	titleView.text = NSLocalizedString(@"Database Settings", @"Database Settings");
	self.navigationItem.titleView = titleView;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	CGRect frameProgress = self.progressView.frame;
	CGRect frameTable = self.tableView.frame;;
	
	self.progressView.frame = CGRectMake(frameProgress.origin.x, frameProgress.origin.y, frameTable.size.width, frameProgress.size.height);
	[self.tableView addSubview:self.progressView];
	
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];
}

#pragma mark -
#pragma mark Post Report Notifications

- (void)addObserverToObjectForProgress {
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(objectDidUpdateProgress:)
												 name: MADNotificationProgressIdentifier
											   object: nil];
}

- (void)removeObserverFromObjectForProgress {
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: MADNotificationProgressIdentifier
												  object: nil];
}

#pragma mark -
#pragma mark Progress Notifications

- (void)objectDidUpdateProgress:(NSNotification *)sender {
	MADProgress *progress = sender.userInfo[MADNotificationProgressKey];
	[[NSOperationQueue mainQueue] addOperationWithBlock:^ {
		self.progressView.progress = progress.progress;
		self.navigationItem.prompt = progress.message.copy;
	}];
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath: indexPath animated: NO];
}

#pragma mark -
#pragma mark UIViewControllerAnimatedTransitioning

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
	
	UIViewController *viewControllerFrom = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
	UIViewController *viewControllerTo = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
	transitionContext.containerView.backgroundColor = [UIColor clearColor];
	[transitionContext.containerView setOpaque:NO];
	viewControllerTo.view.bounds = viewControllerFrom.view.bounds;
	viewControllerTo.view.backgroundColor = [UIColor clearColor];
	[transitionContext.containerView addSubview:viewControllerTo.view];
	viewControllerTo.view.bounds = transitionContext.containerView.bounds;
	viewControllerTo.view.center = transitionContext.containerView.center;
	viewControllerTo.view.alpha = 0.0000f;
	
	[UIView animateWithDuration:0.4000f animations:^{
		viewControllerTo.view.alpha = 1.0000f;
		[transitionContext.containerView addSubview:viewControllerTo.view];
	} completion:^(BOOL __unused finished) {
		[transitionContext completeTransition:![transitionContext transitionWasCancelled]];
	}];
}

- (void)animationEnded:(BOOL)transitionCompleted { }

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
	return 0.4;
}

#pragma mark -
#pragma mark UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
	return nil;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
																  presentingController:(UIViewController *)presenting
																	  sourceController:(UIViewController *)source {
	return self;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator {
	return nil;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning>)animator {
	return nil;
}

#pragma mark -
#pragma mark MADDatabaseResultsProtocol

- (void)resetAfterConnectionString:(NSString *)connectionString failedTest:(NSArray *)errors {
	[self enableUserInteraction];
	[self displayErrors:errors forConnectionString:connectionString];
}

- (void)displayErrors:(NSArray <__kindof NSError *> *)errors
  forConnectionString:(NSString *)connectionString {
	[MADConnectionViewController viewController: self displayErrors: errors completion: ^(BOOL __unused success) {
		[MADKeyChain deleteKey:connectionString];
	}];
}

- (void)showErrorLog:(MADErrorContainer *)errorContainer {
	if (errorContainer && [errorContainer count] > 0) {
		NSString *errorText = [errorContainer errorLogCompact];
		
		NSString *alertTitle = NSLocalizedString(@"Issues Encounterd", @"Alert Title 'Issues Encounterd'.");
		NSString *alertButton = NSLocalizedString(@"Continue", @"Button 'Continue'");
		
		UIAlertController *alert = [UIAlertController alertControllerWithTitle: alertTitle
																	   message: errorText
																preferredStyle: UIAlertControllerStyleAlert];

		[alert addAction:[UIAlertAction actionWithTitle: alertButton
												  style: UIAlertActionStyleDefault
												handler: nil]];
		[self presentViewController:alert animated:YES completion:nil];
	}

}

- (void)disableNavigation {
	self.navigationItem.leftBarButtonItem.enabled = NO;
	self.navigationItem.backBarButtonItem.enabled = NO;
	[self.navigationItem setHidesBackButton:YES animated:YES];
}

- (void)enableNavigation {
	self.navigationItem.leftBarButtonItem.enabled = YES;
	self.navigationItem.leftBarButtonItem.enabled = YES;
	[self.navigationItem setHidesBackButton:NO animated:YES];
}

#pragma mark -
#pragma mark Actions

- (IBAction)save:(id)sender {
	NSAssert(sender != nil, @"%s Sender is nil.", __PRETTY_FUNCTION__);
	[self disableUserInteractionWithMessage:NSLocalizedString(@"Importing schema.", @"Importing schema.")];
	[self addObserverToObjectForProgress];
	[self.delegate viewControllerDidFinish:self];
}

- (IBAction)documentNameDidEndOnExit:(id)sender { }

- (IBAction)canceled:(id)sender {
	[self.delegate viewControllerDidCancel:self];
}

#pragma mark Override Points

- (MADDatabaseConnection *)databaseConnection {
	@throw NSInternalInconsistencyException;
}

- (void)resetInterface {
	[self removeObserverFromObjectForProgress];
	self.navigationItem.prompt = NSLocalizedString(@"Each report requires a database connection.", @"Each report requires a database connection.");
}

#pragma mark Helpers

- (void)removeKeyboard {
	[self.textFieldReportName resignFirstResponder];
}

- (void)disableTextFields {
	self.textFieldReportName.enabled = NO;
}

- (void)enableTextFields {
	self.textFieldReportName.enabled = YES;
}

- (void)disableUserInteractionWithMessage:(NSString *)message {
	[self removeKeyboard];
	[self disableTextFields];
	
	self.navigationItem.prompt = message.copy;
	self.navigationItem.rightBarButtonItem.enabled = NO;
	
	[self disableNavigation];
	
	UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
	[activityIndicator startAnimating];
	activityIndicator.hidden = NO;
	activityIndicator.hidesWhenStopped = NO;
	
	UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
	barButtonItem.isAccessibilityElement = NO;
	[self.navigationItem setRightBarButtonItem:barButtonItem animated:YES];
}

- (void)enableUserInteraction {
	[self enableNavigation];
	[self enableTextFields];
	UIBarButtonItem *buttonSave = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemSave
																				target: self.actionSaveTarget
																				action: self.actionSave];
	[self.navigationItem setRightBarButtonItem:buttonSave animated:YES];
	self.navigationItem.rightBarButtonItem.enabled = YES;
	self.progressView.progress = 0.0;
}

@end
