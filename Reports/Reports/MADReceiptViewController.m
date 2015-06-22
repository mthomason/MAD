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
#import "UIAlertController+Constructors.h"
#import "MADFeatures.h"
#import "MADFeature.h"
#import "NSDateFormatter+RFC_3339.h"
#import "MTApplicationInstance.h"
#import "UIColor+PaperPatterns.h"

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
    int extraRows = [MTVerificationController sharedInstance].receipt.charterMembership ? 1 : 0;
    return [MTVerificationController sharedInstance].receipt == nil ? 0 : [MTVerificationController sharedInstance].receipt.inAppPurchases.count + extraRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    BOOL inAppPurchase = NO;
    NSInteger inAppPurchaseIndex = 0;
    if ([MTVerificationController sharedInstance].receipt.charterMembership) {
        if (indexPath.item == 0) {
            static NSString *reuseID = @"MADIdentifierReceiptApplicationDetails";
            cell = [tableView dequeueReusableCellWithIdentifier:reuseID forIndexPath:indexPath];
            ((MADTableViewCellReceiptApplication *)cell).product.text = [MTApplicationInstance applicationName];
            ((MADTableViewCellReceiptApplication *)cell).version.text = [MTVerificationController sharedInstance].receipt.version;
        } else if (indexPath.item == 1) {
            static NSString *reuseID = @"MADIdentifierReceiptCharterMember";
            cell = [tableView dequeueReusableCellWithIdentifier:reuseID forIndexPath:indexPath];
            NSString *formatString = NSLocalizedString(@"Charter Member (since version %@)", @"Charter Member (since version %@)");
            NSString *formattted = [NSString stringWithFormat:formatString, [MTVerificationController sharedInstance].receipt.originalVersion];
            NSMutableAttributedString *at = ((MADTableViewCellReceiptCharterMember *)cell).charterMember.attributedText.mutableCopy;
            [at replaceCharactersInRange:NSMakeRange(0, at.length) withString:formattted];
            ((MADTableViewCellReceiptCharterMember *)cell).charterMember.attributedText = at;
        } else {
            inAppPurchase = YES;
            inAppPurchaseIndex = indexPath.item - 1;
        }
    } else {
        inAppPurchase = YES;
        inAppPurchaseIndex = indexPath.item;
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
    [[MTVerificationController sharedInstance] refreshReceipt:^(BOOL success, NSError *error) {
        if (error != nil) {
            UIAlertController *alert = [UIAlertController error:error];
            [self presentViewController:alert animated:YES completion:^{
                
            }];
        } else {
            NSString *title = NSLocalizedString(@"Purchases Restored", @"Purchases Restored");
            NSString *messages = NSLocalizedString(@"Restored purchases for your account.", @"Restored purchases for your account.");
            UIAlertController *alert = [UIAlertController alertControllerWithTitle: title
                                                                           message: messages
                                                                    preferredStyle: UIAlertControllerStyleAlert];
            NSString *dismiss = NSLocalizedString(@"Dismiss", @"Dismiss");
            UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:dismiss style:UIAlertActionStyleDefault handler:NULL];;;
            
            [alert addAction:dismissAction];
            [self presentViewController:alert animated:YES completion:NULL];
        }
        [self.tableView reloadData];
    }];
}

- (IBAction)actionDone:(id)sender {
    [self.delegate viewControllerDidFinish:self];
}

//NSInteger indexGivenItem(NSInteger i, bool charterMember) {
//    return charterMember ? (i) : i;
//}

- (CGFloat)inAppPurchaseCellHeight:(NSInteger)index {
    NSDictionary *purchase = [MTVerificationController sharedInstance].receipt.inAppPurchases[index];
    NSString *cancelDate = purchase[@"cancellation-date"];
    return cancelDate.length > 0 ? 126.0000f : 100.0000f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([MTVerificationController sharedInstance].receipt.charterMembership) {
        if (indexPath.item == 0 || indexPath.item == 1) {
            return 34.0000f;
        } else {
            return [self inAppPurchaseCellHeight:indexPath.item-2];
        }
    } else {
        if (indexPath.item == 0) {
            return 34.0000f;
        } else {
            return [self inAppPurchaseCellHeight:indexPath.item-1];
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
