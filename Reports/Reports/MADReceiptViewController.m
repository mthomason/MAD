//
//  UIReceiptViewController.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/21/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADReceiptViewController.h"
#import "MTVerificationController.h"
#import "MADSalesReceipt.h"
#import "UIAlertController+Constructors.h"
#import "MADReceiptTableViewCell.h"
#import "MADFeatures.h"
#import "MADFeature.h"
#import "NSDateFormatter+RFC_3339.h"

@interface MADReceiptViewController ()

@property (nonatomic, strong) MADFeatures *features;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation MADReceiptViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    MADFeatures *features = [[MADFeatures alloc] init];
    self.features = features;
    
    NSDateFormatter *dateFormatter = [NSDateFormatter RFC_3339];
    self.dateFormatter = dateFormatter;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [MTVerificationController sharedInstance].receipt == nil ? 0 : [MTVerificationController sharedInstance].receipt.inAppPurchases.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *reuseID = @"MADIdentifierReceipt";
    MADReceiptTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseID forIndexPath:indexPath];
    NSDictionary *purchase = [MTVerificationController sharedInstance].receipt.inAppPurchases[indexPath.item];
    MADFeature *feature = [self.features featureForProductID:purchase[@"product-id"]];
    cell.labelID.text = feature.defaultTitle;
    
    NSString *purchaseDate = [self userVisibleDateTimeStringForRFC3339DateTimeString:purchase[@"purchase-date"]];
    cell.labelOriginalPurchaseDate.text = purchaseDate;
    if (((NSString *)purchase[@"cancellation-date"]).length > 0) {
        NSString *cancelDate = [self userVisibleDateTimeStringForRFC3339DateTimeString:purchase[@"cancellation-date"]];
        cell.labelCancellationDate.text = cancelDate;
        cell.labelCancellationLabel.textColor = [UIColor redColor];
        cell.labelCancellationLabel.hidden = NO;
    } else {
        cell.labelCancellationDate.text = @"";
        cell.labelCancellationLabel.hidden = YES;
    }
    
    return cell;
}

- (NSString *)userVisibleDateTimeStringForRFC3339DateTimeString:(NSString *)rfc3339DateTimeString {
    
    /*
     Returns a user-visible date time string that corresponds to the specified
     RFC 3339 date time string. Note that this does not handle all possible
     RFC 3339 date time strings, just one of the most common styles.
     */

    // Convert the RFC 3339 date time string to an NSDate.
    NSDate *date = [self.dateFormatter dateFromString:rfc3339DateTimeString];
    NSString *userVisibleDateTimeString = nil;

    if (date != nil) {
        
        // Convert the date object to a user-visible date string.
        NSDateFormatter *userVisibleDateFormatter = [[NSDateFormatter alloc] init];
        userVisibleDateFormatter.dateStyle = NSDateFormatterMediumStyle;
        userVisibleDateFormatter.timeStyle = NSDateFormatterNoStyle;
        userVisibleDateTimeString = [userVisibleDateFormatter stringFromDate:date];
    }
    
    return userVisibleDateTimeString != nil ? userVisibleDateTimeString : rfc3339DateTimeString;
}

- (IBAction)actionRefresh:(id)sender {
    [[MTVerificationController sharedInstance] refreshReceipt:^(BOOL success, NSError *error) {
        if (error != nil) {
            UIAlertController *alert = [UIAlertController error:error];
            [self presentViewController:alert animated:YES completion:^{
                
            }];
        }
        [self.tableView reloadData];
    }];
}

- (IBAction)actionDone:(id)sender {
    [self.delegate viewControllerDidFinish:self];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *purchase = [MTVerificationController sharedInstance].receipt.inAppPurchases[indexPath.item];
    NSString *cancelDate = purchase[@"cancellation-date"];
    return cancelDate.length > 0 ? 100.0000f : 74.0000f;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

@end
