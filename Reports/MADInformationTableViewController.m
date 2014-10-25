//
//  MADInformationTableViewController.m
//  MAD
//
//  Created by Michael Thomason on 10/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADInformationTableViewController.h"
#import "MADVibrantTableViewCell.h"
#import "MADVibrantTableView.h"

@interface MADInformationTableViewController ()
    <MADVibrantTableViewCellDelegate>

@end

@implementation MADInformationTableViewController
- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - MADVibrantTableViewCellDelegate

- (UIBlurEffect *)blurEffectForCell:(UITableViewCell *)cell {
    return (UIBlurEffect *)((MADVibrantTableView *)self.tableView).visualEffectsView.effect;
}

- (IBAction)unwindToInformation:(UIStoryboardSegue *)action { }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.preferredContentSize = CGSizeMake(280, 200);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MADVibrantTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MADIdentiferVibrantTableViewCellInformation" forIndexPath:indexPath];
    cell.vibrantTableViewCellDelegate = self;

    switch (indexPath.row) {

        case 0:
            cell.label.text = @"MAD Designer Details";
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
            cell.marginStyle = MADTableViewCellMarginStyleTop;
            break;
            
        case 1:
            cell.label.text = @"MAD is the Mobile Analytics Document from Everyday Apps.  MAD Designer allows one to create and distribute MAD files or mobile analytics documents.";
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            cell.marginStyle = MADTableViewCellMarginStyleMiddle;
            break;
            
        case 2:
            cell.label.text = @"MAD Designer is for analyst to create and distribute analytics documents that reference their companies data.  To use MAD Designer, you will need to have access to your companies database.  MAD Designer requires the skills of a business analyst and understanding of your companies database.";
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            cell.marginStyle = MADTableViewCellMarginStyleMiddle;
            break;
            
        case 3:
            cell.label.text = @"MAD Viewer exist for users who do not design documents to view the MAD files with live data.  Get MAD Viewer from the App Store.";
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            cell.marginStyle = MADTableViewCellMarginStyleMiddle;
            break;
            
        case 4:
            cell.label.text = @"MAD Designer currently supports MySQL and Microsoft SQL Server databases.  It does this using native database drivers.";
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
