//
//  MADGettingStartedTableViewController.m
//  MAD
//
//  Created by Michael Thomason on 10/21/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADGettingStartedTableViewController.h"
#import "MADTableViewCellBase.h"
#import <UIKit/UILabel.h>
#import <UIKit/UINavigationController.h>

@interface MADGettingStartedTableViewController ()

@end

@implementation MADGettingStartedTableViewController

- (IBAction)cancel:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)done:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = NSLocalizedString(@"Overview", @"Overview");
	self.tableView.dataSource = self;
	self.tableView.delegate = self;
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.tableView.estimatedRowHeight = 44.0;
	self.tableView.rowHeight = UITableViewAutomaticDimension;
	self.tableView.backgroundColor = [UIColor systemBackgroundColor];
	self.tableView.contentInset = UIEdgeInsetsMake(10.0, 0.0, 10.0, 0.0);
	[self.tableView registerClass:[MADTableViewCellBase class] forCellReuseIdentifier:@"MADIdentiferTableViewCellInformation"];
	self.preferredContentSize = CGSizeMake(360.0, 440.0);
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.navigationController setNavigationBarHidden:NO animated:animated];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return 12; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	MADTableViewCellBase *cell = [tableView dequeueReusableCellWithIdentifier:@"MADIdentiferTableViewCellInformation" forIndexPath:indexPath];
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.userInteractionEnabled = NO;

	switch (indexPath.row) {
		case 0:
			cell.label.text = NSLocalizedString(@"Mobile Analytics Document", @"Mobile Analytics Document");
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
			cell.label.textColor = [UIColor labelColor];
			cell.marginStyle = MADTableViewCellMarginStyleTop;
			break;

		case 1:
			cell.label.text = NSLocalizedString(@"MAD is an open-source mobile business intelligence and report-design system. A .mad file stores a report's schema snapshot, query definition, and visual layout in one compact, portable document.", @"Overview paragraph 1");
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
			cell.label.textColor = [UIColor secondaryLabelColor];
			cell.marginStyle = MADTableViewCellMarginStyleMiddle;
			break;

		case 2:
			cell.label.text = NSLocalizedString(@"MAD Designer connects natively to MySQL / MariaDB, Microsoft SQL Server, and PostgreSQL databases, and uses SQLite for portable sample documents and local row caching.", @"Overview paragraph 2");
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
			cell.label.textColor = [UIColor secondaryLabelColor];
			cell.marginStyle = MADTableViewCellMarginStyleBottom;
			break;

		case 3:
			cell.label.text = NSLocalizedString(@"Workflow", @"Workflow");
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
			cell.label.textColor = [UIColor labelColor];
			cell.marginStyle = MADTableViewCellMarginStyleTop;
			break;

		case 4:
			cell.label.text = NSLocalizedString(@"1. Connect a Data Source", @"Step 1 heading");
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
			cell.label.textColor = [UIColor labelColor];
			cell.marginStyle = MADTableViewCellMarginStyleMiddle;
			break;

		case 5:
			cell.label.text = NSLocalizedString(@"Tap + in the file explorer and choose a database driver. MAD reads the database schema and creates a new .mad document. Database credentials can be saved in your Keychain and are never stored inside the .mad file.", @"Step 1 body");
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
			cell.label.textColor = [UIColor secondaryLabelColor];
			cell.marginStyle = MADTableViewCellMarginStyleMiddle;
			break;

		case 6:
			cell.label.text = NSLocalizedString(@"2. Build the Query (MAD Query)", @"Step 2 heading");
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
			cell.label.textColor = [UIColor labelColor];
			cell.marginStyle = MADTableViewCellMarginStyleMiddle;
			break;

		case 7:
			cell.label.text = NSLocalizedString(@"Add tables, joins, filter predicates, groupings, and sort order visually, or paste a SQL SELECT statement directly. MAD generates the database-specific SQL automatically.", @"Step 2 body");
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
			cell.label.textColor = [UIColor secondaryLabelColor];
			cell.marginStyle = MADTableViewCellMarginStyleMiddle;
			break;

		case 8:
			cell.label.text = NSLocalizedString(@"3. Lay Out the Report (MAD Designer)", @"Step 3 heading");
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
			cell.label.textColor = [UIColor labelColor];
			cell.marginStyle = MADTableViewCellMarginStyleMiddle;
			break;

		case 9:
			cell.label.text = NSLocalizedString(@"Place data fields, static labels, aggregate functions, barcodes, and shapes across Report Header, Page Header, Group Headers and Footers, Detail, Page Footer, and Report Footer sections.", @"Step 3 body");
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
			cell.label.textColor = [UIColor secondaryLabelColor];
			cell.marginStyle = MADTableViewCellMarginStyleMiddle;
			break;

		case 10:
			cell.label.text = NSLocalizedString(@"4. View & Export (MAD Viewer)", @"Step 4 heading");
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
			cell.label.textColor = [UIColor labelColor];
			cell.marginStyle = MADTableViewCellMarginStyleMiddle;
			break;

		case 11:
			cell.label.text = NSLocalizedString(@"Refresh the report against live data, browse paginated output, print, or export to PDF, HTML, CSV, JSON, or plain text.", @"Step 4 body");
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
			cell.label.textColor = [UIColor secondaryLabelColor];
			cell.marginStyle = MADTableViewCellMarginStyleBottom;
			break;

		default:
			break;
	}
	[cell setNeedsLayout];
	[cell setNeedsUpdateConstraints];
	return cell;
}

@end
