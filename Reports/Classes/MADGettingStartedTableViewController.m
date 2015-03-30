//
//  MADGettingStartedTableViewController.m
//  MAD
//
//  Created by Michael Thomason on 10/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADGettingStartedTableViewController.h"
#import "MADVibrantTableView.h"
#import "MADVibrantTableViewCell.h"

@interface MADGettingStartedTableViewController ()
    <MADVibrantTableViewCellDelegate>

@end

@implementation MADGettingStartedTableViewController

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - MADVibrantTableViewCellDelegate

- (UIBlurEffect *)blurEffectForCell:(UITableViewCell *)cell {
    return (UIBlurEffect *)((MADVibrantTableView *)self.tableView).visualEffectsView.effect;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.dataSource = self;
    self.preferredContentSize = CGSizeMake(280, 200);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 11;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MADVibrantTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MADIdentiferVibrantTableViewCellGettingStarted" forIndexPath:indexPath];
    cell.vibrantTableViewCellDelegate = self;
    switch (indexPath.row) {
            
        case 0:
            cell.label.text = @"Stepping in the Right Direction";
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
            cell.marginStyle = MADTableViewCellMarginStyleTop;
            break;
            
        case 1:
            cell.label.text = @"Gettings Started";
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            cell.marginStyle = MADTableViewCellMarginStyleMiddle;
            break;
            
        case 2:
            cell.label.text = @"You need access to a MySQL or SQL Server database.";
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            cell.marginStyle = MADTableViewCellMarginStyleMiddle;
            break;
            
        case 3:
            cell.label.text = @"The MAD Datasource";
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            cell.marginStyle = MADTableViewCellMarginStyleMiddle;
            break;
            
        case 4:
            cell.label.text = @"Attach your datasource as you are creating a new document.  As the document is being created, you will be prompted for the datasource credentials.  If you choose, these credentials are stored in your keychain; they are never stored inside the MAD file.";
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            cell.marginStyle = MADTableViewCellMarginStyleMiddle;
            break;
            
        case 5:
            cell.label.text = @"The MAD Query";
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            cell.marginStyle = MADTableViewCellMarginStyleMiddle;
            break;
            
        case 6:
            cell.label.text = @"Once a MAD file is created, you may design a query for it.  The query builder allows you to add tables, link those tables, group the tables, and add predicates.  This feature requires advanced database or data analysis skills.  The user is required to design queries that are sane and efficient.";
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            cell.marginStyle = MADTableViewCellMarginStyleMiddle;
            break;

        case 7:
            cell.label.text = @"MAD Designer";
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            cell.marginStyle = MADTableViewCellMarginStyleMiddle;
            break;

        case 8:
            cell.label.text = @"The designer allows the user to layout and format fields from the database query.";
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            cell.marginStyle = MADTableViewCellMarginStyleMiddle;
            break;
            
        case 9:
            cell.label.text = @"MAD Viewer";
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            cell.marginStyle = MADTableViewCellMarginStyleMiddle;
            break;

        case 10:
            cell.label.text = @"The viewer allows you to render and refresh your MAD file.  Once rendered, you may print and send to to PDF.";
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            cell.marginStyle = MADTableViewCellMarginStyleBottom;
            break;
            
        default:
            break;
    }
    cell.label.tintColor = [UIColor darkTextColor];
    [cell layoutIfNeeded];
    return cell;
}

@end
