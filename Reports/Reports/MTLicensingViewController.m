//
//  MTLicensingViewController.m
//  Reports
//
//  Created by Michael Thomason on 6/26/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTLicensingViewController.h"

@interface MTLicensingViewController ()

@property (nonatomic, retain) IBOutlet UIButton *buttonBuyNowDesignerOneYear;
@property (nonatomic, retain) IBOutlet UIButton *buttonBuyNowDesignerOneMonth;

@property (nonatomic, retain) IBOutlet UIButton *buttonBuyNowViewerOneYear;
@property (nonatomic, retain) IBOutlet UIButton *buttonBuyNowViewerOneMonth;

@property (nonatomic, retain) IBOutlet UIBarButtonItem *buttonRestore;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *buttonDone;
@property (nonatomic, retain) IBOutlet UISwipeGestureRecognizer *swipeDone;

@property (nonatomic, retain) IBOutlet UIView *viewBuyButtonsBackground;

@property (nonatomic, retain) IBOutlet UILabel *labelDesignerLicenseOneYearTitle;
@property (nonatomic, retain) IBOutlet UILabel *labelDesignerLicenseOneYearDesc1;
@property (nonatomic, retain) IBOutlet UILabel *labelDesignerLicenseOneYearDesc2;
@property (nonatomic, retain) IBOutlet UILabel *labelDesignerLicenseOneYearDesc3;
@property (nonatomic, retain) IBOutlet UILabel *labelDesignerLicenseOneYearDesc4;
@property (nonatomic, retain) IBOutlet UILabel *labelDesignerKeyActivated;
@property (nonatomic, retain) IBOutlet UILabel *labelDesignerKeyExpires;
@property (nonatomic, retain) IBOutlet UILabel *labelDesignerValueActivated;
@property (nonatomic, retain) IBOutlet UILabel *labelDesignerValueExpires;

@property (nonatomic, retain) IBOutletCollection(UILabel) NSArray *labelsShowWhenActivated;
@property (nonatomic, retain) IBOutletCollection(UILabel) NSArray *labelsHideWhenActivated;

@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicatorDesignerLicenseOneYear;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator2;

@property (copy) MTBlockCompletion standardCompletion;
@property (copy) MTStoreKitNonRenewableLicensedUser licenseUserCompletion;

@end

@implementation MTLicensingViewController

- (void)dealloc {
    [_swipeDone release];
    [_standardCompletion release];
    [_licenseUserCompletion release];
    [_buttonBuyNowDesignerOneYear release];
    [_buttonBuyNowDesignerOneMonth release];
    [_buttonBuyNowViewerOneMonth release];
    [_buttonBuyNowViewerOneYear release];
    [_labelDesignerLicenseOneYearTitle release];
    [_labelDesignerLicenseOneYearDesc1 release];
    [_labelDesignerLicenseOneYearDesc2 release];
    [_labelDesignerLicenseOneYearDesc3 release];
    [_labelDesignerLicenseOneYearDesc4 release];
    [_activityIndicator2 release];
    [_activityIndicatorDesignerLicenseOneYear release];
    [_buttonRestore release];
    [_buttonDone release];
    [_labelDesignerKeyActivated release];
    [_labelDesignerKeyExpires release];
    [_labelDesignerValueActivated release];
    [_labelDesignerValueExpires release];
    [_labelsShowWhenActivated release];
    [_labelsHideWhenActivated release];
    [_viewBuyButtonsBackground release];
    [_swipeDone release];
    [super dealloc];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    if ([UIDevice isPad]) {
        [self setPreferredContentSize:CGSizeMake(380.0000f, 480.0000f)];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[MTVerificationController sharedInstance] iOS7VerifyReceipt];
     
    __block __weak MTLicensingViewController *weakViewController = self;

    MTStoreKitNonRenewableLicensedUser licenseUserCompletion = ^(BOOL isLicensedUser, NSDate *experationDate) {

        if (isLicensedUser) {
            
            [weakViewController showLicensingDetailsWithExperationDate:experationDate];
            [[weakViewController activityIndicatorDesignerLicenseOneYear] stopAnimating];
            [[weakViewController activityIndicator2] stopAnimating];
            
            BOOL allowPurchase = [experationDate timeIntervalSinceNow] < MTTimeIntervalDay * 15;
            if ([AppDelegate isMadDesigner]) {
                [[weakViewController viewBuyButtonsBackground] setBackgroundColor:!allowPurchase ? [UIColor lightGrayColor] : [UIColor lightGrayColor]];
                [[weakViewController buttonBuyNowDesignerOneYear] setEnabled:allowPurchase];
                [[weakViewController buttonBuyNowDesignerOneYear] setHidden:!allowPurchase];
                [[weakViewController buttonBuyNowDesignerOneMonth] setEnabled:allowPurchase];
                [[weakViewController buttonBuyNowDesignerOneMonth] setHidden:!allowPurchase];
            } else if ([AppDelegate isMadViewer]) {
                [[weakViewController viewBuyButtonsBackground] setBackgroundColor:!allowPurchase ? [UIColor lightGrayColor] : [UIColor lightGrayColor]];
                [[weakViewController buttonBuyNowViewerOneMonth] setEnabled:allowPurchase];
                [[weakViewController buttonBuyNowViewerOneMonth] setHidden:!allowPurchase];
                [[weakViewController buttonBuyNowViewerOneYear] setEnabled:allowPurchase];
                [[weakViewController buttonBuyNowViewerOneYear] setHidden:!allowPurchase];
            }
        } else {
            [weakViewController hideLicensingDetails];
            if ([AppDelegate isMadDesigner]) {
                [[weakViewController viewBuyButtonsBackground] setBackgroundColor:NO ? [UIColor lightGrayColor] : [UIColor lightGrayColor]];
                [[weakViewController buttonBuyNowDesignerOneYear] setEnabled:NO];
                [[weakViewController buttonBuyNowDesignerOneMonth] setEnabled:NO];
                //[[self buttonBuyNowDesignerOneYear] setHidden:YES];
                //[[self buttonBuyNowDesignerOneMonth] setHidden:YES];
            } else if ([AppDelegate isMadViewer]) {
                [[weakViewController viewBuyButtonsBackground] setBackgroundColor:NO ? [UIColor lightGrayColor] : [UIColor lightGrayColor]];
                [[weakViewController buttonBuyNowViewerOneYear] setEnabled:NO];
                [[weakViewController buttonBuyNowViewerOneMonth] setEnabled:NO];
                //[[self buttonBuyNowViewerOneYear] setHidden:YES];
                //[[self buttonBuyNowViewerOneMonth] setHidden:YES];
            }
            
            [[weakViewController activityIndicatorDesignerLicenseOneYear] startAnimating];
            [[weakViewController activityIndicator2] startAnimating];
            
            NSArray *productIds;
            if ([AppDelegate isMadDesigner]) {
                productIds = @[MTStoreKitProductIdentifierDesignerSubscriptionMonth1,
                               MTStoreKitProductIdentifierDesignerSubscriptionYear1];
            } else if ([AppDelegate isMadViewer]) {
                productIds = @[MTStoreKitProductIdentifierViewerSubscriptionMonth1,
                               MTStoreKitProductIdentifierViewerSubscriptionYear1];
            } else {
                productIds = @[];
            }
            [weakViewController disableUserInterface];
            
            MTBlockCompletion initalizationComplete = ^(BOOL success, NSError *error) {
                
                [[weakViewController activityIndicatorDesignerLicenseOneYear] stopAnimating];
                [[weakViewController activityIndicator2] stopAnimating];
                
                [weakViewController enableUserInterface];
                if ([AppDelegate isMadDesigner]) {
                    [[weakViewController viewBuyButtonsBackground] setBackgroundColor:NO ? [UIColor lightGrayColor] : [UIColor lightGrayColor]];
                    [[weakViewController buttonBuyNowDesignerOneYear] setEnabled:success];
                    [[weakViewController buttonBuyNowDesignerOneYear] setHidden:NO];
                    [[weakViewController buttonBuyNowDesignerOneMonth] setEnabled:success];
                    [[weakViewController buttonBuyNowDesignerOneMonth] setHidden:NO];
                } else if ([AppDelegate isMadViewer]) {
                    [[weakViewController viewBuyButtonsBackground] setBackgroundColor:NO ? [UIColor lightGrayColor] : [UIColor lightGrayColor]];
                    [[weakViewController buttonBuyNowViewerOneYear] setEnabled:success];
                    [[weakViewController buttonBuyNowViewerOneYear] setHidden:NO];
                    [[weakViewController buttonBuyNowViewerOneMonth] setEnabled:success];
                    [[weakViewController buttonBuyNowViewerOneMonth] setHidden:NO];
                }
                NSArray *products = [[MTStoreKitController sharedObject] products];
                
                NSNumberFormatter *priceFormatter = [[NSNumberFormatter alloc] init];
                [priceFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
                
                for (SKProduct *product in products) {
                    
                    //NSLog(@"Product %@", product);
                    if ([[product productIdentifier] isEqualToString:MTStoreKitProductIdentifierDesignerSubscriptionYear1]) {
                        
                        [priceFormatter setLocale:[product priceLocale]];
                        NSString *priceString = [priceFormatter stringFromNumber:[product price]];
                        [[weakViewController buttonBuyNowDesignerOneYear] setTitle:priceString forState:UIControlStateNormal];
                        
                    } else if ([[product productIdentifier] isEqualToString:MTStoreKitProductIdentifierDesignerSubscriptionMonth1]) {

                        [priceFormatter setLocale:[product priceLocale]];
                        NSString *priceString = [priceFormatter stringFromNumber:[product price]];
                        [[weakViewController buttonBuyNowDesignerOneMonth] setTitle:priceString forState:UIControlStateNormal];
                        
                    } else if ([[product productIdentifier] isEqualToString:MTStoreKitProductIdentifierViewerSubscriptionMonth1]) {
                        
                        [priceFormatter setLocale:[product priceLocale]];
                        NSString *priceString = [priceFormatter stringFromNumber:[product price]];
                        [[weakViewController buttonBuyNowViewerOneMonth] setTitle:priceString forState:UIControlStateNormal];
                        
                    } else if ([[product productIdentifier] isEqualToString:MTStoreKitProductIdentifierViewerSubscriptionYear1]) {
                        
                        [priceFormatter setLocale:[product priceLocale]];
                        NSString *priceString = [priceFormatter stringFromNumber:[product price]];
                        [[weakViewController buttonBuyNowViewerOneYear] setTitle:priceString forState:UIControlStateNormal];
                        
                    }
                }
                [priceFormatter release];
            };
            [[MTStoreKitController sharedObject] initalizeProductsWithIdentifiers: productIds
                                                                       completion: initalizationComplete];
        }
    };
    
    [self setLicenseUserCompletion:licenseUserCompletion];
    
   //__block __weak MTLicensingViewController *weakViewController = self;
    MTBlockCompletion completion = ^(BOOL success, NSError *error){
        [weakViewController enableUserInterface];
        [[MTStoreKitController sharedObject] licensedUser:[self licenseUserCompletion]];
        if (success == NO) {
            [error presentErrorToUser];
        }
    };
    [self setStandardCompletion:completion];
    if ([UIDevice isLagacyOS]) {
        [[[self viewBuyButtonsBackground] layer] setCornerRadius:6.6666f];
    }
    if ([AppDelegate isMadDesigner]) {
        [[[self buttonBuyNowDesignerOneYear] layer] setCornerRadius:6.6666f];
        [[[self buttonBuyNowDesignerOneMonth] layer] setCornerRadius:6.6666f];
    } else if ([AppDelegate isMadViewer]) {
        [[[self buttonBuyNowViewerOneYear] layer] setCornerRadius:6.6666f];
        [[[self buttonBuyNowViewerOneMonth] layer] setCornerRadius:6.6666f];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if ([AppDelegate isMadDesigner]) {
        //[[self viewBuyButtonsBackground] setBackgroundColor:YES ? [UIColor whiteColor] : [UIColor lightGrayColor]];
        [[self buttonBuyNowDesignerOneYear] setEnabled:NO];
        [[self buttonBuyNowDesignerOneMonth] setEnabled:NO];
    } else if ([AppDelegate isMadViewer]) {
        //[[self viewBuyButtonsBackground] setBackgroundColor:YES ? [UIColor whiteColor] : [UIColor lightGrayColor]];
        [[self buttonBuyNowViewerOneYear] setEnabled:NO];
        [[self buttonBuyNowViewerOneMonth] setEnabled:NO];
    }

    [[MTStoreKitController sharedObject] licensedUser:[self licenseUserCompletion]];
    
}

- (void)showLicensingDetailsWithExperationDate:(NSDate *)experationDate {
    NSString *dateString = [NSDateFormatter localizedStringFromDate:experationDate
                                                          dateStyle:NSDateFormatterLongStyle
                                                          timeStyle:NSDateFormatterNoStyle];
    [[self labelDesignerValueExpires] setText:dateString];
    [[self labelsShowWhenActivated] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj setHidden: NO];
    }];
    [[self labelsHideWhenActivated] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj setHidden: YES];
    }];
}

- (void)hideLicensingDetails {
    [[self labelsShowWhenActivated] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj setHidden: YES];
    }];
    [[self labelsHideWhenActivated] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj setHidden: NO];
    }];
}

- (void)disableUserInterface {
    if ([AppDelegate isMadDesigner]) {
        [[self buttonBuyNowDesignerOneYear] setEnabled:NO];
        [[self buttonBuyNowDesignerOneMonth] setEnabled:NO];
        [[self buttonBuyNowDesignerOneYear] setHidden:YES];
        [[self buttonBuyNowDesignerOneMonth] setHidden:YES];
    } else if ([AppDelegate isMadViewer]) {
        [[self buttonBuyNowViewerOneYear] setEnabled:NO];
        [[self buttonBuyNowViewerOneMonth] setEnabled:NO];
        [[self buttonBuyNowViewerOneYear] setHidden:YES];
        [[self buttonBuyNowViewerOneMonth] setHidden:YES];
    }
    [[self buttonDone] setEnabled:NO];
    [[self swipeDone] setEnabled:NO];
    [[self buttonRestore] setEnabled:NO];
}

- (void)enableUserInterface {
    if ([AppDelegate isMadDesigner]) {
        [[self buttonBuyNowDesignerOneYear] setEnabled:YES];
        [[self buttonBuyNowDesignerOneMonth] setEnabled:YES];
        [[self buttonBuyNowDesignerOneYear] setHidden:NO];
        [[self buttonBuyNowDesignerOneMonth] setHidden:NO];
    } else if ([AppDelegate isMadViewer]) {
        [[self buttonBuyNowViewerOneYear] setEnabled:YES];
        [[self buttonBuyNowViewerOneMonth] setEnabled:YES];
        [[self buttonBuyNowViewerOneYear] setHidden:NO];
        [[self buttonBuyNowViewerOneMonth] setHidden:NO];
    }
    [[self buttonDone] setEnabled:YES];
    [[self swipeDone] setEnabled:YES];
    [[self buttonRestore] setEnabled:YES];
}

- (IBAction)done:(id)sender {
    [[self delegate] viewControllerDidFinish: self];
}

- (IBAction)licenseDesignerOneYear:(id)sender {
    [self licenseProductWithIdentifier:MTStoreKitProductIdentifierDesignerSubscriptionYear1];
}

- (IBAction)licenseDesignerOneMonth:(id)sender {
    [self licenseProductWithIdentifier:MTStoreKitProductIdentifierDesignerSubscriptionMonth1];
}

- (IBAction)licenseViewerOneYear:(id)sender {
    [self licenseProductWithIdentifier:MTStoreKitProductIdentifierViewerSubscriptionYear1];
}

- (IBAction)licenseViewerOneMonth:(id)sender {
    [self licenseProductWithIdentifier:MTStoreKitProductIdentifierViewerSubscriptionMonth1];
}

- (void)licenseProductWithIdentifier:(NSString *)identifier {
    [[self viewBuyButtonsBackground] setBackgroundColor:NO ? [UIColor whiteColor] : [UIColor lightGrayColor]];
    [self disableUserInterface];
    [[self activityIndicatorDesignerLicenseOneYear] startAnimating];
    [[self activityIndicator2] startAnimating];
    MTStoreKitController *storeKit = [MTStoreKitController sharedObject];
    NSArray *products = [storeKit products];
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [[(SKProduct *)evaluatedObject productIdentifier] isEqualToString:identifier];
    }];
    NSArray *productArray = [products filteredArrayUsingPredicate:predicate];
    if ([productArray count] > 0) {
        SKProduct *product = [productArray objectAtIndex:0];
        [[MTStoreKitController sharedObject] purchaseProductWithIdentifier:product
                                                                completion:[self standardCompletion]];
    } else {
        [self enableUserInterface];
    }
}

- (IBAction)restoreAllTransactions:(id)sender {
    
    MTAlertView *alertView = [[MTAlertView alloc] initWithTitle: NSLocalizedString(@"Note", @"Title to message to customer.")
                                                        message: NSLocalizedString(@"Transactions are tied to your iCloud account.", @"Transactions are tied to your iCloud account.")
                                              cancelButtonTitle: NSLocalizedString(@"Continue", @"Continue") otherButtonTitle:nil onDismiss:^(NSInteger buttonIndex) {
                                                  
                                              } onCancel:^{
                                                  
                                              }];
    [alertView show];
    [alertView autorelease];
    
/*    [self disableUserInterface];
    MTStoreKitController *storeKit = [MTStoreKitController sharedObject];
    [storeKit restorePurchases:[self standardCompletion]];*/
}

@end
