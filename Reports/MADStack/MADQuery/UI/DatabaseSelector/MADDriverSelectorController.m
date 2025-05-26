//
//  UITableViewControllerDataSourceTypes.m
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDriverSelectorController.h"
#import "MADDocumentCreationManager.h"
#import "MADDocumentCreationManagerProtocol.h"
#import "madlog.h"

#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADConnectionViewController.h>
#import <MADAPI/MADViewControllerStandardProtocol.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/MADLabelTitle.h>

#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIImageView.h>
#import <UIKit/UIVisualEffectView.h>
#import <UIKit/UIStoryboardSegue.h>
#import <UIKit/UIStoryboard.h>
#import <UIKit/UILabel.h>

@interface MADDriverSelectorController () <MADViewControllerStandardProtocol, MADDocumentCreationManagerProtocol, UITableViewDelegate>
	@property (nonatomic, strong) MADDocumentCreationManager *documentCreationManager;
	@property (nonatomic, weak) __kindof MADConnectionViewController *connectionViewController;
@end

@implementation MADDriverSelectorController

- (NSURL *)documentDirectory {
	return [self.saveFileDelegate documentDirectory];
}

#pragma mark - MADVibrantTableViewCellDelegate

- (void)viewDidLoad {
	[super viewDidLoad];
	self.tableView.dataSource = self;
	self.tableView.delegate = self;
	self.tableView.estimatedRowHeight = 44.0;
	self.tableView.rowHeight = UITableViewAutomaticDimension;
	self.tableView.allowsSelection = YES;
	self.tableView.backgroundColor = [UIColor systemGroupedBackgroundColor];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return 2; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *cellID = @"MADTableViewCellConnectionType";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];

	switch (indexPath.row) {
		case 0:
			cell.imageView.image = [UIImage imageNamed:@"UIImageExportTypeMySQL"];
			cell.textLabel.text = NSLocalizedString(@"MySQL Native Driver", @"Selection Label 'MySQL Native Driver'");
			break;

		case 1:
			cell.imageView.image = [UIImage imageNamed:@"UIImageExportTypeSqlServer"];
			cell.textLabel.text = NSLocalizedString(@"Sql Server / TDS Driver", @"Selection Label 'Sql Server / TDS Driver'");
			break;
			
		default:
			os_log_error(GetDesignerLog(), "%s: Unknown row in driver selector: %ld", __PRETTY_FUNCTION__, (long)indexPath.row);
			break;
	}
	cell.textLabel.textColor = [UIColor labelColor];
	[UITableViewCell appearance].textLabel.highlightedTextColor = [MADColorEverydayApps newColorBlue];
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 104.0;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	[cell.contentView setNeedsLayout];
	[cell.contentView layoutIfNeeded];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	[cell.contentView setNeedsLayout];
	[cell.contentView layoutIfNeeded];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self showViewControllerConnection:indexPath.row];
}

- (void)showViewControllerConnection:(NSInteger)type {
	MADConnectionViewController *connectionViewController = [[UIStoryboard storyboardWithName: @"MADCreateDocument"
																					   bundle: [NSBundle bundleWithIdentifier:type == 0 ? @"com.everydayapps.mysql" : @"com.everydayapps.tdsclient"]] instantiateViewControllerWithIdentifier:@"MADConnectionViewControllerSQLGeneric"];
	connectionViewController.delegate = self;
	connectionViewController.saveFileDelegate = self;
	connectionViewController.databaseType = type == 0 ? MADDatabaseTypeMySQL :
														MADDatabaseTypeTDS;
	[self.navigationController pushViewController:connectionViewController
										 animated:YES];
	self.connectionViewController = connectionViewController;
}

- (void)viewControllerDidFinish:(id)sender {
	if ([sender isKindOfClass:[MADConnectionViewController class]]) {
		MADDatabaseConnection *databaseConnection = [((MADConnectionViewController *)sender) databaseConnection];
		MADDocumentCreationManager *documentCreationManager = [[MADDocumentCreationManager alloc] initWithFilename: ((MADConnectionViewController *)sender).textFieldReportName.text
																										  delegate: self
																								documentsDirectory: self.documentDirectory
																								databaseConnection: databaseConnection
																									viewController: ((MADConnectionViewController *)sender)];
		[documentCreationManager start];
		self.documentCreationManager = documentCreationManager;


	}
}

- (void)viewControllerDidCancel:(id)sender {
	[self.delegate viewControllerDidCancel:self];
}
- (IBAction)cancel:(id)sender {
	[self viewControllerDidCancel:sender];
}

#pragma mark -
#pragma mark MADDocumentCreationManagerProtocol

- (void)documentCreationManager:(id <MADDocumentCreationManagerInterface>)manager didFinish:(BOOL)success {
	MADConnectionViewController *connectionViewController = self.connectionViewController;
	[connectionViewController resetInterface];
	if (success) {
		[self.delegate viewControllerDidFinish: self];
	} else {
		[connectionViewController enableUserInteraction];
	}
}

@end
