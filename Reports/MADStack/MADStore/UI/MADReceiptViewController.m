//
//  UIReceiptViewController.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/21/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADReceiptViewController.h"
#import "MADTableViewCellReceiptInAppPurchase.h"
#import "MADTableViewCellReceiptApplication.h"
#import "MADTableViewCellReceiptCharterMember.h"
#import "MTVerificationController.h"
#import "MADSalesReceipt.h"
#import "MADFeatures.h"
#import "MADFeature.h"
#import "NSDateFormatter+RFC_3339.h"
#import "UIColor+PaperPatterns.h"
#import <MADCocoaExtensions/UIAlertController+Constructors.h>
#import <MADFoundation/MADAppDelegate.h>
#import <MADFoundation/MADApplicationProtocol.h>
#import <MADFoundation/UIApplication+MADAppDelegate.h>

@interface MADReceiptViewController ()

    @property (nonatomic, strong) MADFeatures *features;
    @property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation MADReceiptViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    self.tableView.backgroundColor = [UIColor paperHomemade];
}

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
    NSUInteger extraRows;
    extraRows = ([MTVerificationController sharedInstance].receipt.charterMembership ? 1 : 0);
    return (NSInteger)([MTVerificationController sharedInstance].receipt == nil ? 0 :
                       [MTVerificationController sharedInstance].receipt.inAppPurchases.count +
                      ([MTVerificationController sharedInstance].receipt.charterMembership ? 1 : 0));
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    BOOL inAppPurchase = NO;
    NSUInteger inAppPurchaseIndex = 0;
    if ([MTVerificationController sharedInstance].receipt.charterMembership) {
        
        if (indexPath.item == 0) {
            static NSString *reuseID = @"MADIdentifierReceiptApplicationDetails";
            cell = [tableView dequeueReusableCellWithIdentifier:reuseID forIndexPath:indexPath];
            NSString *name    = [[MADApplication AppDelegate] name],
                     *version = [MTVerificationController sharedInstance].receipt.version;
            ((MADTableViewCellReceiptApplication *)cell).product.text = name.copy;
            ((MADTableViewCellReceiptApplication *)cell).version.text = version.copy;
        } else if (indexPath.item == 1) {
            
            static NSString *reuseID = @"MADIdentifierReceiptCharterMember";
            cell = [tableView dequeueReusableCellWithIdentifier:reuseID forIndexPath:indexPath];
            NSString *formatString = NSLocalizedString(@"Charter Member (since version %@)", @"Charter Member (since version %@)");
            NSString *formattted;
            formattted = [[NSString alloc] initWithFormat:formatString,
                                [MTVerificationController sharedInstance].receipt.originalVersion];
            NSMutableAttributedString *cellText;
            cellText = ((MADTableViewCellReceiptCharterMember *)cell).charterMember.attributedText.mutableCopy;
            [cellText replaceCharactersInRange:NSMakeRange(0, cellText.length) withString:formattted];
            ((MADTableViewCellReceiptCharterMember *)cell).charterMember.attributedText = cellText;
            
        } else {
            inAppPurchase = YES;
            inAppPurchaseIndex = (NSUInteger)indexPath.item - 1;
        }
    } else {
        inAppPurchase = YES;
        inAppPurchaseIndex = (NSUInteger)indexPath.item;
    }
    if (inAppPurchase) {
        static NSString *reuseID = @"MADIdentifierReceipt";
        cell = [tableView dequeueReusableCellWithIdentifier:reuseID forIndexPath:indexPath];
        NSDictionary *purchase = [MTVerificationController sharedInstance].receipt.inAppPurchases[inAppPurchaseIndex];
        MADFeature *feature = [self.features featureForProductID:purchase[@"product-id"]];
        ((MADTableViewCellReceiptInAppPurchase *)cell).labelID.text = feature.defaultTitle;
        
        NSString *purchaseDate = [self userVisibleDateTimeStringForRFC3339DateTimeString:purchase[@"purchase-date"]];
        ((MADTableViewCellReceiptInAppPurchase *)cell).labelOriginalPurchaseDate.text = purchaseDate;
        if (((NSString *)purchase[@"cancellation-date"]).length > 0) {
            NSString *cancelDate = [self userVisibleDateTimeStringForRFC3339DateTimeString:purchase[@"cancellation-date"]];
            ((MADTableViewCellReceiptInAppPurchase *)cell).labelCancellationDate.text = cancelDate;
            ((MADTableViewCellReceiptInAppPurchase *)cell).labelCancellationLabel.textColor = [UIColor redColor];
            ((MADTableViewCellReceiptInAppPurchase *)cell).labelCancellationLabel.hidden = NO;
        } else {
            ((MADTableViewCellReceiptInAppPurchase *)cell).labelCancellationDate.text = @"";
            ((MADTableViewCellReceiptInAppPurchase *)cell).labelCancellationLabel.hidden = YES;
        }

    }
    return cell;
}

- (NSString *)userVisibleDateTimeStringForRFC3339DateTimeString:(NSString *)rfc3339DateTimeString {
    
    NSDate *date = [self.dateFormatter dateFromString:rfc3339DateTimeString];
    NSString *userVisibleDateTimeString = nil;

    if (date != nil) {
        NSDateFormatter *userVisibleDateFormatter = [[NSDateFormatter alloc] init];
        userVisibleDateFormatter.dateStyle = NSDateFormatterMediumStyle;
        userVisibleDateFormatter.timeStyle = NSDateFormatterNoStyle;
        userVisibleDateTimeString = [userVisibleDateFormatter stringFromDate:date];
    }
    
    return userVisibleDateTimeString != nil ? userVisibleDateTimeString : rfc3339DateTimeString;
}

- (IBAction)actionRefresh:(id)sender {
    MADReceiptViewController __weak *weakself = self;
    [[MTVerificationController sharedInstance] refreshReceipt:^(BOOL success, NSError *error) {
        MADReceiptViewController *strongself = weakself;
        if (error != nil) {
            UIAlertController *alert = [UIAlertController newAlertControllerError:error];
            [strongself presentViewController:alert animated:YES completion:^{
                
            }];
        } else {
            NSString *title = NSLocalizedString(@"Purchases Restored", @"Purchases Restored");
            NSString *messages = NSLocalizedString(@"Restored purchases for your account.",
                                                   @"Restored purchases for your account.");
            UIAlertController *alert;
            alert = [UIAlertController alertControllerWithTitle: title
                                                        message: messages
                                                 preferredStyle: UIAlertControllerStyleAlert];
            NSString *dismiss = NSLocalizedString(@"Dismiss", @"Dismiss");
            UIAlertAction *dismissAction;
            dismissAction = [UIAlertAction actionWithTitle: dismiss
                                                     style: UIAlertActionStyleDefault
                                                   handler: NULL];
            
            [alert addAction:dismissAction];
            [strongself presentViewController:alert animated:YES completion:NULL];
        }
        [strongself.tableView reloadData];
    }];
}

- (IBAction)actionDone:(id)sender {
    [self.delegate viewControllerDidFinish:self];
}

//NSInteger indexGivenItem(NSInteger i, BOOL charterMember) {
//    return charterMember ? (i) : i;
//}

- (CGFloat)inAppPurchaseCellHeight:(NSUInteger)index {
    NSDictionary *purchase;
    purchase = [MTVerificationController sharedInstance].receipt.inAppPurchases[index];
    NSString *cancelDate = purchase[@"cancellation-date"];
    return cancelDate.length > 0 ? 126.0000f : 100.0000f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([MTVerificationController sharedInstance].receipt.charterMembership) {
        if (indexPath.item == 0) {
            return 74.0000f;
        } else if (indexPath.item == 1) {
            return 34.0000f;
        } else {
            return [self inAppPurchaseCellHeight:(NSUInteger)indexPath.item-2];
        }
    } else {
        if (indexPath.item == 0) {
            return 74.0000f;
        } else {
            return [self inAppPurchaseCellHeight:(NSUInteger)indexPath.item-1];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

@end
