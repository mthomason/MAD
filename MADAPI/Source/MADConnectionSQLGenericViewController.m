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

#import "MADConnectionSQLGenericViewController.h"

#import <MADFoundation/MADProgress.h>
#import <MADFoundation/MADNotificationProgress.h>
#import <MADFoundation/MADKeyChain.h>

#import <MADCocoaExtensions/MADLabelTitle.h>

#import <MADCocoaExtensions/MADAlertController.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import <MADAPI/MADViewControllerStandardProtocol.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADErrorContainer.h>

#import <UIKit/UIAccessibility.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UIActivityIndicatorView.h>
#import <UIKit/UILocalNotification.h>
#import <UIKit/UIViewControllerTransitioning.h>
#import <UIKit/UITableViewHeaderFooterView.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIProgressView.h>

#import <os/log.h>

typedef void (^MADBlockAlertDidFinish)(UIAlertAction *);
typedef void (^MADBlockCompletionStatus)(BOOL);

@interface MADConnectionSQLGenericViewController ()
	<UITableViewDelegate, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning, UITextFieldDelegate>

	@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellDocumentName;
	@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellHost;
	@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellPort;
	@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellDatabase;

	@property (nonatomic, strong) IBOutletCollection(UITableViewCell) NSArray *tableViewCells;
	@property (nonatomic, strong) IBOutletCollection(UITextField) NSArray *textFields;

	@property (nonatomic, strong) UIProgressView *progressView;

	@property (nonatomic, assign) SEL actionSave;
	@property (nonatomic, weak) id actionSaveTarget;

	- (IBAction)save:(id)sender;
	- (IBAction)usernameDidEndOnExit:(id)sender;
	- (IBAction)hostDidEndOnExit:(id)sender;
	- (IBAction)portDidEndOnExit:(id)sender;

@end

@implementation MADConnectionSQLGenericViewController

#pragma mark -
#pragma mark NSObject

+ (void)initialize {
	[super initialize];
	
	if (self != [MADConnectionViewController self]) {
		@autoreleasepool {
			UIProgressView <UIAppearance> *appearanceProxyProgressView;
			NSArray <Class <UIAppearanceContainer>> *classes;
			classes = [[NSArray alloc] initWithObjects: self, nil];
			appearanceProxyProgressView = [UIProgressView appearanceWhenContainedInInstancesOfClasses:classes];
			appearanceProxyProgressView.tintColor = [UIColor whiteColor];
			appearanceProxyProgressView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
			appearanceProxyProgressView.progressTintColor = [MADColorEverydayApps newColorAnalogous4];
			appearanceProxyProgressView.trackTintColor = [UIColor grayColor];
		}
	}
}

+ (void)viewController:(id)viewController
		 displayErrors:(NSArray <__kindof NSError *> *)errors
			completion:(void (^)(BOOL))completion {

	MADBlockAlertDidFinish handleAlertDidFinish;
	UIAlertController *alert;
	NSRange range;
	NSError *error = errors.lastObject;
	NSString *localizedDescription, *localizedFailureReason;
	NSArray <__kindof NSError *> *remaningErrors;
		
	range = NSMakeRange(0, errors.count > 0 ? errors.count - 1 : 0);
	remaningErrors = [errors subarrayWithRange:range];

	handleAlertDidFinish = ^(UIAlertAction *action) {

		if (remaningErrors.count > 0) {
			
			MADBlockCompletionStatus alertCompleted = ^(BOOL success) { completion(YES); };
			[self viewController:viewController
				   displayErrors:remaningErrors
					  completion:alertCompleted];
		} else {
			completion(YES);
		}
		
	};
	
	localizedDescription = error.localizedDescription.copy;
	localizedFailureReason = error.localizedFailureReason.copy;

	alert = [MADAlertController newAlertControllerErrorDisplayErrorWithTitle: localizedDescription
																	 message: localizedFailureReason
															   andCompletion: handleAlertDidFinish];

	[viewController presentViewController:alert animated:YES completion:nil];
}

- (void)dealloc { }

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
	NSString *databaseSettings = @"Database Settings";
	titleView.text = NSLocalizedString(databaseSettings, databaseSettings);
	self.navigationItem.titleView = titleView;
	
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	CGRect frameProgress = self.progressView.frame;
	CGRect frameTable = self.tableView.frame;;
	
	self.progressView.frame = CGRectMake(frameProgress.origin.x, frameProgress.origin.y,
										 frameTable.size.width, frameProgress.size.height);
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

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
	if (section == 1 && [view isKindOfClass:[UITableViewHeaderFooterView class]]) {
		NSString *displayName = [self displayName];
		if (displayName.length > 0) {
			((UITableViewHeaderFooterView *)view).textLabel.text = [[NSString alloc] initWithFormat:@"%@ %@", displayName, NSLocalizedString(@"Database Settings", @"Database Settings")];
		}
	}
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(nonnull UITableViewCell *)cell forRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
	cell.textLabel.textColor = [UIColor labelColor];
	cell.backgroundColor = [UIColor systemBackgroundColor];
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
	viewControllerTo.view.alpha = 0.0;
	
	[UIView animateWithDuration:0.4 animations:^{
		viewControllerTo.view.alpha = 1.0;
		[transitionContext.containerView addSubview:viewControllerTo.view];
	} completion:^(BOOL finished) {
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
	[[self class] viewController: self displayErrors: errors completion: ^(BOOL success) {
		[MADKeyChain deleteKey:connectionString];
	}];
}

- (void)showErrorLog:(MADErrorContainer *)errorContainer {
	if (errorContainer && [errorContainer count] > 0) {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Issues Encounterd", @"Alert Title 'Issues Encounterd'.")
																	   message: [errorContainer errorLogCompact]
																preferredStyle: UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle: NSLocalizedString(@"Continue", @"Button 'Continue'")
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

- (IBAction)schemaDidEndOnExit:(id)sender { }

- (IBAction)usernameDidEndOnExit:(id)sender { }

- (IBAction)hostDidEndOnExit:(id)sender {
	if ([self.textFieldPort canBecomeFirstResponder]) {
		[self.textFieldPort becomeFirstResponder];
	}
}

- (IBAction)portDidEndOnExit:(id)sender {
	[self.textFieldPort resignFirstResponder];
}

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
	[super removeKeyboard];
	for (UITextField *textField in self.textFields) {
		[textField resignFirstResponder];
	}
}

- (void)disableTextFields {
	[super disableTextFields];
	for (UITextField *textField in self.textFields) {
		textField.enabled = NO;
	}
}

- (void)enableTextFields {
	[super enableTextFields];
	for (UITextField *textField in self.textFields) {
		textField.enabled = YES;
	}
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
