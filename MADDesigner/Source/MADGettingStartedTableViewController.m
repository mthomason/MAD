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

@interface MADGettingStartedTableViewController ()

@end

@implementation MADGettingStartedTableViewController

- (IBAction)done:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.tableView.dataSource = self;
	self.preferredContentSize = CGSizeMake(320, 200);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return 16; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	MADTableViewCellBase *cell = [tableView dequeueReusableCellWithIdentifier:@"MADIdentiferTableViewCellInformation" forIndexPath:indexPath];
	switch (indexPath.row) {
			
		case 0:
			cell.label.text = NSLocalizedString(@"MAD Designer Details", @"MAD Designer Details");
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
			cell.marginStyle = MADTableViewCellMarginStyleTop;
			break;
			
		case 1:
			cell.label.text = @"MAD is the Mobile Analytics Document from Everyday Apps.  "
							  @"MAD Designer allows one to create and distribute MAD files or "
							  @"mobile analytics documents.";
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
			cell.marginStyle = MADTableViewCellMarginStyleMiddle;
			break;
			
		case 2:
			cell.label.text = @"MAD Designer is for analyst to create and distribute analytics "
							  @"documents that reference their companies data.  To use "
							  @"MAD Designer, you will need to have access to your companies "
							  @"database.  MAD Designer requires the skills of a business analyst "
							  @"and understanding of your companies database.";
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
			cell.marginStyle = MADTableViewCellMarginStyleMiddle;
			break;
			
		case 3:
			cell.label.text = @"MAD Viewer exist for users who do not design documents to view the"
							  @"MAD files with live data.  Get MAD Viewer from the App Store.";
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
			cell.marginStyle = MADTableViewCellMarginStyleMiddle;
			break;
			
		case 4:
			cell.label.text = @"MAD Designer currently supports MySQL and Microsoft SQL Server "
							  @"databases.  It does this using native database drivers.";
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
			cell.marginStyle = MADTableViewCellMarginStyleBottom;
			break;
		
		case 5:
			cell.label.text = @"Stepping in the Right Direction";
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
			cell.marginStyle = MADTableViewCellMarginStyleTop;
			break;
			
		case 6:
			cell.label.text = @"Gettings Started";
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
			cell.marginStyle = MADTableViewCellMarginStyleMiddle;
			break;
			
		case 7:
			cell.label.text = @"You need access to a MySQL or SQL Server database.";
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
			cell.marginStyle = MADTableViewCellMarginStyleMiddle;
			break;
			
		case 8:
			cell.label.text = @"The MAD Datasource";
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
			cell.marginStyle = MADTableViewCellMarginStyleMiddle;
			break;
			
		case 9:
			cell.label.text = @"Attach your datasource as you are creating a new document.  "
							  @"As the document is being created, you will be prompted for the "
							  @"datasource credentials.  If you choose, these credentials are "
							  @"stored in your keychain; they are never stored inside the "
							  @"MAD file.";
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
			cell.marginStyle = MADTableViewCellMarginStyleMiddle;
			break;
			
		case 10:
			cell.label.text = @"The MAD Query";
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
			cell.marginStyle = MADTableViewCellMarginStyleMiddle;
			break;
			
		case 11:
			cell.label.text = @"Once a MAD file is created, you may design a query for it.  "
							  @"The query builder allows you to add tables, link those tables, "
							  @"group the tables, and add predicates.  This feature requires "
							  @"advanced database or data analysis skills.  The user is required "
							  @"to design queries that are sane and efficient.";
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
			cell.marginStyle = MADTableViewCellMarginStyleMiddle;
			break;

		case 12:
			cell.label.text = @"MAD Designer";
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
			cell.marginStyle = MADTableViewCellMarginStyleMiddle;
			break;

		case 13:
			cell.label.text = @"The designer allows the user to layout and format fields from the"
							  @"database query.";
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
			cell.marginStyle = MADTableViewCellMarginStyleMiddle;
			break;
			
		case 14:
			cell.label.text = @"MAD Viewer";
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
			cell.marginStyle = MADTableViewCellMarginStyleMiddle;
			break;

		case 15:
			cell.label.text = @"The viewer allows you to render and refresh your MAD file.  Once "
							  @"rendered, you may print and send to to PDF.";
			cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
			cell.marginStyle = MADTableViewCellMarginStyleBottom;
			break;
			
		default:
			break;
	}
	cell.label.tintColor = [UIColor darkTextColor];
	[cell setNeedsLayout];
	[cell setNeedsUpdateConstraints];
	return cell;
}

@end
