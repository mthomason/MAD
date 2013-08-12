//
//  MTLicensingViewController.m
//  Reports
//
//  Created by Michael Thomason on 6/26/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTLicensingViewController.h"

@interface MTLicensingViewController ()

@property (nonatomic, retain) IBOutlet UIButton *buttonBuyNow;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *buttonRestore;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *buttonDone;

@property (nonatomic, retain) IBOutlet UILabel *labelDesignerLicenseOneYearTitle;
@property (nonatomic, retain) IBOutlet UILabel *labelDesignerLicenseOneYearDesc1;
@property (nonatomic, retain) IBOutlet UILabel *labelDesignerLicenseOneYearDesc2;
@property (nonatomic, retain) IBOutlet UILabel *labelDesignerLicenseOneYearDesc3;
@property (nonatomic, retain) IBOutlet UILabel *labelDesignerLicenseOneYearDesc4;
@property (nonatomic, retain) IBOutlet UILabel *labelDesignerKeyActivated;
@property (nonatomic, retain) IBOutlet UILabel *labelDesignerKeyExpires;
@property (nonatomic, retain) IBOutlet UILabel *labelDesignerValueActivated;
@property (nonatomic, retain) IBOutlet UILabel *labelDesignerValueExpires;


@property (retain, nonatomic) IBOutletCollection(UILabel) NSArray *labelsShowWhenActivated;

@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicatorDesignerLicenseOneYear;

@property (copy) MTBlockCompletion standardCompletion;
@property (copy) MTStoreKitNonRenewableLicensedUser licenseUserCompletion;

@end

@implementation MTLicensingViewController

- (void)dealloc {
    [_standardCompletion release];
    [_licenseUserCompletion release];
    [_buttonBuyNow release];
    [_labelDesignerLicenseOneYearTitle release];
    [_labelDesignerLicenseOneYearDesc1 release];
    [_labelDesignerLicenseOneYearDesc2 release];
    [_labelDesignerLicenseOneYearDesc3 release];
    [_labelDesignerLicenseOneYearDesc4 release];
    [_activityIndicatorDesignerLicenseOneYear release];
    [_buttonRestore release];
    [_buttonDone release];
    [_labelDesignerKeyActivated release];
    [_labelDesignerKeyExpires release];
    [_labelDesignerValueActivated release];
    [_labelDesignerValueActivated release];
    [_labelsShowWhenActivated release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    MTStoreKitNonRenewableLicensedUser licenseUserCompletion = ^(BOOL isLicensedUser, NSDate *experationDate) {
        if (isLicensedUser) {
            [self showLicensingDetailsWithExperationDate:experationDate];
            [[self activityIndicatorDesignerLicenseOneYear] stopAnimating];
            BOOL allowPurchase = [experationDate timeIntervalSinceNow] < MTTimeIntervalDay * 15;
            [[self buttonBuyNow] setEnabled:allowPurchase];
            [[self buttonBuyNow] setHidden:!allowPurchase];
            
        } else {
            [self hideLicensingDetails];
            [[self buttonBuyNow] setHidden:YES];
            [[self activityIndicatorDesignerLicenseOneYear] startAnimating];
            
            NSArray *productIdentifiers = @[MTStoreKitProductIdentifierDesignerSubscriptionYear1,
                                            MTStoreKitProductIdentifierViewerSubscriptionMonth1,
                                            MTStoreKitProductIdentifierViewerSubscriptionYear1];
            
            [self disableUserInterface];
            
            MTBlockCompletion initalizationComplete = ^(BOOL success, NSError *error) {
                
                [[self activityIndicatorDesignerLicenseOneYear] stopAnimating];
                [self enableUserInterface];
                [[self buttonBuyNow] setEnabled:success];
                [[self buttonBuyNow] setHidden:NO];
                NSArray *products = [[MTStoreKitController sharedObject] products];
                
                NSNumberFormatter *priceFormatter = [[NSNumberFormatter alloc] init];
                [priceFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
                
                for (SKProduct *product in products) {
                    
                    //NSLog(@"Product %@", product);
                    if ([[product productIdentifier] isEqualToString:MTStoreKitProductIdentifierDesignerSubscriptionYear1]) {
                        
                        [priceFormatter setLocale:[product priceLocale]];
                        NSString *priceString = [priceFormatter stringFromNumber:[product price]];
                        [[self buttonBuyNow] setTitle:priceString forState:UIControlStateNormal];
                        
                    } else if ([[product productIdentifier] isEqualToString:MTStoreKitProductIdentifierViewerSubscriptionMonth1]) {
                        
                        [priceFormatter setLocale:[product priceLocale]];
                        NSString *priceString = [priceFormatter stringFromNumber:[product price]];
                        [[self buttonBuyNow] setTitle:priceString forState:UIControlStateNormal];
                        
                    } else if ([[product productIdentifier] isEqualToString:MTStoreKitProductIdentifierViewerSubscriptionYear1]) {
                        
                        [priceFormatter setLocale:[product priceLocale]];
                        NSString *priceString = [priceFormatter stringFromNumber:[product price]];
                        [[self buttonBuyNow] setTitle:priceString forState:UIControlStateNormal];
                        
                    }
                }
                [priceFormatter release];
            };
            [[MTStoreKitController sharedObject] initalizeProductsWithIdentifiers: productIdentifiers
                                                                       completion: initalizationComplete];
        }
    };
    [self setLicenseUserCompletion:licenseUserCompletion];
    
    MTBlockCompletion completion = ^(BOOL success, NSError *error){
        [self enableUserInterface];
        [MTStoreKitController licensedUser:[self licenseUserCompletion]];
        if (success == NO) {
            [error presentErrorToUser];
        }
    };
    [self setStandardCompletion:completion];
    
    [[[self buttonBuyNow] layer] setCornerRadius:6.6666f];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    //[[self buttonBuyNow] setTitle:@"" forState:UIControlStateDisabled];
    [[self buttonBuyNow] setHidden:YES];

    [MTStoreKitController licensedUser:[self licenseUserCompletion]];
    
}

- (void)showLicensingDetailsWithExperationDate:(NSDate *)experationDate {
    NSString *dateString = [NSDateFormatter localizedStringFromDate:experationDate
                                                          dateStyle:NSDateFormatterLongStyle
                                                          timeStyle:NSDateFormatterNoStyle];
    [[self labelDesignerValueExpires] setText:dateString];
    [[self labelsShowWhenActivated] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj setHidden: NO];
    }];
}

- (void)hideLicensingDetails {
    [[self labelsShowWhenActivated] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj setHidden: YES];
    }];
}

- (void)disableUserInterface {
    [[self buttonBuyNow] setEnabled:NO];
    [[self buttonDone] setEnabled:NO];
    [[self buttonRestore] setEnabled:NO];
}

- (void)enableUserInterface {
    [[self buttonBuyNow] setEnabled:YES];
    [[self buttonDone] setEnabled:YES];
    [[self buttonRestore] setEnabled:YES];
}

- (IBAction)done:(id)sender {
    [[self delegate] viewControllerDidFinish: self];
}

- (IBAction)licenseDesignerOneYear:(id)sender {
    [self licenseProductWithIdentifier:MTStoreKitProductIdentifierDesignerSubscriptionYear1];
}

- (IBAction)licenseViewerOneYear:(id)sender {
    [self licenseProductWithIdentifier:MTStoreKitProductIdentifierViewerSubscriptionYear1];
}

- (IBAction)licenseViewerOneMonth:(id)sender {
    [self licenseProductWithIdentifier:MTStoreKitProductIdentifierViewerSubscriptionMonth1];
}

- (void)licenseProductWithIdentifier:(NSString *)identifier {
    [[self buttonBuyNow] setHidden:YES];
    [self disableUserInterface];
    [[self activityIndicatorDesignerLicenseOneYear] startAnimating];
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
