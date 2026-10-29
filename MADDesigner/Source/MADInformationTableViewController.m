//
//  MADInformationTableViewController.m
//  MAD
//
//  Created by Michael Thomason on 10/21/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADInformationTableViewController.h"
#import "MADAboutTableViewController.h"
#import "MADTableViewCellAuto.h"
#import "MADOperationPromptError.h"
#import <MADFoundation/madlog.h>

#import <MADCocoaExtensions/MFMailComposeViewController+MADExtensions.h>
#import <MADCocoaExtensions/MADAlertController.h>
#import <MADFoundation/MADOperationQueue.h>
#import <MADFoundation/MADBlockOperation.h>

#import <MessageUI/MFMailComposeViewController.h>

@interface MADInformationTableViewController () <MFMailComposeViewControllerDelegate>

@end

@implementation MADInformationTableViewController

- (void)mailComposeController:(MFMailComposeViewController *)controller
		  didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {

	if (error != nil) {
		MADOperationQueue *operationQueue = [[MADOperationQueue alloc] init];
		MADOperationPromptError *operationErrorDisplay = [[MADOperationPromptError alloc] initWithError:error viewController:self];
		MADBlockOperation *finish = [[MADBlockOperation alloc] initWithBlock:^(OperationCompletionBlock __unused completionBlock) {
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
	self.preferredContentSize = CGSizeMake(480, 220);
	
	if (!UIAccessibilityIsReduceTransparencyEnabled()) {
		self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
		self.tableView.estimatedRowHeight = 44.0000f;
		self.tableView.rowHeight = UITableViewAutomaticDimension;
		self.tableView.backgroundColor = [UIColor clearColor];
		UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];
		UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return 4; }

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	switch (indexPath.row) {
		case 1:
			[self actionWhatIsMad];
			break;

		case 2:
			[self actionOpenGitHub];
			break;

		case 3:
			[self actionShowAcknowledgements];
			break;

		default:
			break;
	}
}

- (void)actionWhatIsMad {
	[self performSegueWithIdentifier:@"MADStoryboardSegueWhatIsMAD" sender:self];
}

- (void)actionOpenGitHub {
	NSURL *repoURL = [NSURL URLWithString:@"https://github.com/mthomason/MAD"];
	[[UIApplication sharedApplication] openURL:repoURL
									   options:@{}
							 completionHandler:^(BOOL __unused success) {
	}];
}

- (void)actionShowAcknowledgements {
	MADAcknowledgementsViewController *ackVC = [[MADAcknowledgementsViewController alloc] init];
	[self.navigationController pushViewController:ackVC animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	MADTableViewCellAuto *cell = [tableView dequeueReusableCellWithIdentifier:@"MADIdentiferTableViewCellInformation"
																 forIndexPath:indexPath];
	cell.accessoryView = nil;
	switch (indexPath.row) {
		case 0:
			cell.label.text = NSLocalizedString(@"MAD Designer is open-source business intelligence software by Michael Thomason.", @"MAD Designer is open-source business intelligence software by Michael Thomason.");
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
			cell.label.textColor = [UIColor secondaryLabelColor];
			cell.userInteractionEnabled = NO;
			break;

		case 1:
			cell.label.text = NSLocalizedString(@"MAD Designer: An Overview", @"MAD Designer: An Overview");
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
			cell.label.textColor = [UIColor labelColor];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.userInteractionEnabled = YES;
			break;

		case 2:
			cell.label.text = NSLocalizedString(@"Source Code on GitHub", @"Source Code on GitHub");
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
			cell.label.textColor = [UIColor labelColor];
			cell.userInteractionEnabled = YES;
			break;

		case 3:
			cell.label.text = NSLocalizedString(@"Acknowledgements", @"Acknowledgements");
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
			cell.label.textColor = [UIColor labelColor];
			cell.userInteractionEnabled = YES;
			break;

		default:
			break;
	}
	[cell setNeedsLayout];
	[cell setNeedsUpdateConstraints];
	return cell;
}

@end
