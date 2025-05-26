//
//  MADInformationTableViewController.m
//  MAD
//
//  Created by Michael Thomason on 10/21/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADInformationTableViewController.h"
#import "MADTableViewCellAuto.h"
#import "MADButtonTwitter.h"
#import "MADAttributedStringCommon.h"
#import "MADOperationPromptError.h"
#import "madlog.h"

#import <MADCocoaExtensions/MADMailComposeViewController.h>
#import <MADCocoaExtensions/MADAlertController.h>
#import <MADFoundation/MADOperationQueue.h>
#import <MADFoundation/MADBlockOperation.h>

#import <MessageUI/MFMailComposeViewController.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>

@interface MADInformationTableViewController () <MFMailComposeViewControllerDelegate>

@end

@implementation MADInformationTableViewController

- (void)mailComposeController:(MFMailComposeViewController *)controller
		  didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {

	if (error != nil) {
		MADOperationQueue *operationQueue = [[MADOperationQueue alloc] init];
		MADOperationPromptError *operationErrorDisplay = [[MADOperationPromptError alloc] initWithError:error viewController:self];
		MADBlockOperation *finish = [[MADBlockOperation alloc] initWithBlock:^(OperationCompletionBlock completionBlock) {
			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
				[self dismissViewControllerAnimated:YES completion:nil];
			}];
		}];
		[finish addDependency:operationErrorDisplay];
		[operationQueue addOperation:operationErrorDisplay];
		[operationQueue addOperation:finish];
	}

}

- (IBAction)cancel:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)done:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.tableView.dataSource = self;
	self.preferredContentSize = CGSizeMake(480, 200);
	
	if (!UIAccessibilityIsReduceTransparencyEnabled()) {
		self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
		self.tableView.estimatedRowHeight = 44.0000f;
		self.tableView.rowHeight = UITableViewAutomaticDimension;
		self.tableView.backgroundColor = [UIColor clearColor];
		id blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
		id blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
		self.tableView.backgroundView = blurEffectView;
		
		UIPopoverPresentationController *popover;
		if ((popover = [self.navigationController popoverPresentationController])) {
			popover.backgroundColor = [UIColor clearColor];
		}
		self.tableView.separatorEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return 5; }

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	switch (indexPath.item) {
			
		case 1:
			[self actionWhatIsMad];
			break;
			
		case 2:
			[self actionGoToEverydayAppsCom];
			break;
			
		case 3:
			[self actionEmailUs];
			break;
			
		case 4:
			[self actionTwitterVisitEverydayApps];
			break;
			
		default:
			break;
	}
}

- (void)actionWhatIsMad {
	[self performSegueWithIdentifier:@"MADStoryboardSegueWhatIsMAD" sender:self];
}

- (void)actionGoToEverydayAppsCom {
	NSURL *eda = [NSURL URLWithString: @"https://everydayapps.com"];
	[[UIApplication sharedApplication] openURL:eda
									   options:@{}
							 completionHandler:^(BOOL success) {
	}];
}

- (void)actionTwitterVisitEverydayApps {
	NSURL *eda = [NSURL URLWithString: @"https://twitter.com/EverydayApps"];
	[[UIApplication sharedApplication] openURL:eda
									   options:@{}
							 completionHandler:^(BOOL success) { }];
}

- (void)actionEmailUs {
	MFMailComposeViewController *controller;
	UITraitCollection *traitCollection = self.traitCollection;
	UIUserInterfaceIdiom userInterfaceIdiom = traitCollection.userInterfaceIdiom;
	controller = [MADMailComposeViewController newMailComposeViewControllerWithTitle: @""
																				body: @""
																  userInterfaceIdiom: userInterfaceIdiom];
	controller.toRecipients = @[@"admin@everydayapps.com"];
	controller.subject = @"MAD Designer";
	if (self.popoverPresentationController != nil) {
		[self dismissViewControllerAnimated:YES completion:^{
			
		}];
	}
	controller.mailComposeDelegate = self;
	[self showViewController:controller sender:self];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	MADTableViewCellAuto *cell = [tableView dequeueReusableCellWithIdentifier: @"MADIdentiferTableViewCellInformation"
																 forIndexPath: indexPath];
	switch (indexPath.row) {
			
		case 0:
			cell.label.text = @"MAD Designer is software by Michael Thomason";
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
			cell.userInteractionEnabled = NO;
			break;
			
		case 1:
			cell.label.text = @"MAD Designer: An Overview";
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.userInteractionEnabled = YES;
			break;
			
		case 2:
			cell.label.text = @"Visit our website.";
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
			cell.userInteractionEnabled = YES;
			break;
			
		case 3:
			cell.label.text = @"Email Us";
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
			cell.userInteractionEnabled = YES;
			break;
			
		case 4: {
			cell.label.text = @"Twitter";
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			UIButton *b = [MADButtonTwitter newButtonTwitterFolllowTwitterWithTarget:self
																			  action:@selector(followEverydayApps)];
			cell.accessoryView = b;
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
			cell.userInteractionEnabled = YES;
			break;
		}
		default:
			break;
	}
	cell.label.tintColor = [UIColor darkTextColor];
	[cell setNeedsLayout];
	[cell setNeedsUpdateConstraints];
	return cell;
}

- (void)followEverydayApps {
	os_log_error(GetDesignerLog(), "%s Not implemented", __PRETTY_FUNCTION__);
	if (self.popoverPresentationController != nil) {
		[self dismissViewControllerAnimated:YES completion:^{
			
		}];
	}
}

@end
