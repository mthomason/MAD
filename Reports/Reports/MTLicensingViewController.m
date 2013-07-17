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
@property (nonatomic, retain) IBOutlet UILabel *labelDesignerLicenseOneYearTitle;
@property (nonatomic, retain) IBOutlet UILabel *labelDesignerLicenseOneYearDesc1;
@property (nonatomic, retain) IBOutlet UILabel *labelDesignerLicenseOneYearDesc2;
@property (nonatomic, retain) IBOutlet UILabel *labelDesignerLicenseOneYearDesc3;
@property (nonatomic, retain) IBOutlet UILabel *labelDesignerLicenseOneYearDesc4;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicatorDesignerLicenseOneYear;



@end

@implementation MTLicensingViewController

- (void)dealloc {
    [_buttonBuyNow release];
    [_labelDesignerLicenseOneYearTitle release];
    [_labelDesignerLicenseOneYearDesc1 release];
    [_labelDesignerLicenseOneYearDesc2 release];
    [_labelDesignerLicenseOneYearDesc3 release];
    [_labelDesignerLicenseOneYearDesc4 release];
    [_activityIndicatorDesignerLicenseOneYear release];
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[[self buttonBuyNow] layer] setCornerRadius:6.6666f];
}

- (void)viewWillAppear:(BOOL)animated {
    [[self buttonBuyNow] setTitle:@"" forState:UIControlStateDisabled];
    [[self buttonBuyNow] setEnabled:NO];
    [[self buttonBuyNow] setHidden:YES];
    [[self activityIndicatorDesignerLicenseOneYear] startAnimating];
    NSArray *productIdentifiers = @[MTStoreKitProductIdentifierDesignerSubscriptionYear1,
                                    MTStoreKitProductIdentifierViewerSubscriptionMonth1,
                                    MTStoreKitProductIdentifierViewerSubscriptionYear1];

    [[MTStoreKitController sharedObject] initalizeProductsWithIdentifiers: productIdentifiers completion: ^(BOOL success, NSError *error) {
        
        if ([MTStoreKitController licensedUser]) {
            NSLog(@"Done paid");
        }

        [[self activityIndicatorDesignerLicenseOneYear] stopAnimating];
        [[self buttonBuyNow] setEnabled:success];
        [[self buttonBuyNow] setHidden:!success];
        NSArray *products = [[MTStoreKitController sharedObject] products];
        
        NSNumberFormatter *priceFormatter = [[NSNumberFormatter alloc] init];
        [priceFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        
        for (SKProduct *product in products) {

            NSLog(@"Product %@", product);
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
                                                         
    }];
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)done:(id)sender {
    [[self delegate] viewControllerDidFinish: self];
}

- (IBAction)licenseDesignerOneYear:(id)sender {
    MTStoreKitController *storeKit = [MTStoreKitController sharedObject];
    NSArray *products = [storeKit products];
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [[(SKProduct *)evaluatedObject productIdentifier] isEqualToString:MTStoreKitProductIdentifierDesignerSubscriptionYear1];
    }];
    NSArray *productArray = [products filteredArrayUsingPredicate:predicate];
    if ([productArray count] > 0) {
        SKProduct *product = [productArray objectAtIndex:0];
        [[MTStoreKitController sharedObject] purchaseProductWithIdentifier:product
                                                      completion:^(BOOL success, NSError *error) {
                                                          if (success == NO) {
                                                              [error presentErrorToUser];
                                                          }
                                                      }];
    }
}

@end
