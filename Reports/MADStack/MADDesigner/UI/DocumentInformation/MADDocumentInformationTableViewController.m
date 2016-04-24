//
//  MADDocumentInformationTableViewController.m
//  MAD
//
//  Created by Michael Thomason on 3/15/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentInformationTableViewController.h"
#import <MADCocoaExtensions/MTMath.h>
#import <MADCocoaExtensions/NSNumberFormatter+Constructors.h>
#import <MADFileManager/MADMetaData.h>
#import "MADVibrantTableView.h"
#import "MADVibrantTableViewCell.h"

@interface MADDocumentInformationTableViewController ()
    <MADVibrantTableViewCellDelegate>

@property (nonatomic, strong) NSNumberFormatter *numberFormatter;

@end

@implementation MADDocumentInformationTableViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        NSNumberFormatter *numberFormatter = [NSNumberFormatter newNumberFormatterTwoDecimalPlaces];
        self.numberFormatter = numberFormatter;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.allowsSelection = NO;
    self.preferredContentSize = CGSizeMake(280, 200);
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (NSInteger)self.metadataItems.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 24.0000f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * const MADDocumentInformationID = @"MADTableViewCellDocumentInformation";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: MADDocumentInformationID
                                                            forIndexPath: indexPath];
    MADMetaData *metadata = self.metadataItems[(NSUInteger)indexPath.section];
    NSString *systemFileSizeString;
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = metadata.name;
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
            break;
        case 1: {
            NSNumber *n = [[NSNumber alloc] initWithDouble: madSystemFileSizeToMB(metadata.fileSystemFileSize)];
            systemFileSizeString = [self.numberFormatter stringFromNumber: n];
            cell.textLabel.text = [NSString stringWithFormat:@"%@ MB", systemFileSizeString];
            cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            break;
        }
        case 2: {
            NSString *date = [NSDateFormatter localizedStringFromDate: metadata.fileSystemFileCreationDate
                                                            dateStyle: NSDateFormatterShortStyle
                                                            timeStyle: NSDateFormatterShortStyle];
            cell.textLabel.text = [NSString stringWithFormat:@"Created %@", date];
            cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            break;
        }
        case 3: {
            NSString *date = [NSDateFormatter localizedStringFromDate: metadata.fileSystemContentChangeDate
                                                            dateStyle: NSDateFormatterShortStyle
                                                            timeStyle: NSDateFormatterShortStyle];
            cell.textLabel.text = [NSString stringWithFormat:@"Last changed %@", date];
            cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            break;
        }
        default:
            break;
    }
    
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
