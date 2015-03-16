//
//  MADDocumentInformationTableViewController.m
//  MAD
//
//  Created by Michael Thomason on 3/15/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentInformationTableViewController.h"
#import "MADMetaData.h"
#import "MADVibrantTableView.h"
#import "MADVibrantTableViewCell.h"

@interface MADDocumentInformationTableViewController ()
    <MADVibrantTableViewCellDelegate>

@end

@implementation MADDocumentInformationTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.allowsSelection = NO;
    self.preferredContentSize = CGSizeMake(280, 200);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.metadataItems.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MADVibrantTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: @"MADTableViewCellDocumentInformation"
                                                                    forIndexPath: indexPath];
    cell.vibrantTableViewCellDelegate = self;
    MADMetaData *metadata = self.metadataItems[indexPath.section];
    switch (indexPath.row) {
        case 0:
            cell.label.text = metadata.displayName;
            cell.label.textAlignment = NSTextAlignmentCenter;
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
            break;
        case 1:
            cell.label.text = metadata.fileSystemSizeMB;
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            break;
        case 2: {
            NSString *date = [NSDateFormatter localizedStringFromDate: metadata.fileSystemFileCreationDate
                                                            dateStyle: NSDateFormatterShortStyle
                                                            timeStyle: NSDateFormatterShortStyle];
            cell.label.text = [NSString stringWithFormat:@"Created %@", date];
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            break;
        }
        case 3: {
            NSString *date = [NSDateFormatter localizedStringFromDate: metadata.fileSystemContentChangeDate
                                                            dateStyle: NSDateFormatterShortStyle
                                                            timeStyle: NSDateFormatterShortStyle];
            cell.label.text = [NSString stringWithFormat:@"Last changed %@", date];
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            break;
        }
        default:
            break;
    }
    
    cell.textLabel.text = @"";
    cell.detailTextLabel.text = @"";
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (UIBlurEffect *)blurEffectForCell:(UITableViewCell *)cell {
    return (UIBlurEffect *)((MADVibrantTableView *)self.tableView).visualEffectsView.effect;
}

@end
