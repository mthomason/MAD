//
//  MTLicensingViewController.m
//  Reports
//
//  Created by Michael Thomason on 6/26/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTLicensingViewController.h"
#import "MTVerificationController.h"
#import "MTStoreKitController.h"
#import "MTStoreKitController+NonRenewableLicensing.h"
#import <MADCocoaExtensions/NSError+Constructors.h>
#import <MADFoundation/MADAppDelegate.h>
#import <MADFoundation/MADApplication.h>

@interface MTLicensingViewController ()

@property (nonatomic, weak) IBOutlet UIButton *buttonBuyNowDesignerOneYear;
@property (nonatomic, weak) IBOutlet UIButton *buttonBuyNowDesignerOneMonth;

@property (nonatomic, weak) IBOutlet UIButton *buttonBuyNowViewerOneYear;
@property (nonatomic, weak) IBOutlet UIButton *buttonBuyNowViewerOneMonth;

@property (nonatomic, weak) IBOutlet UIBarButtonItem *buttonRestore;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *buttonDone;
@property (nonatomic, weak) IBOutlet UISwipeGestureRecognizer *swipeDone;

@property (nonatomic, weak) IBOutlet UIView *viewBuyButtonsBackground;

@property (nonatomic, weak) IBOutlet UILabel *labelDesignerLicenseOneYearTitle;
@property (nonatomic, weak) IBOutlet UILabel *labelDesignerLicenseOneYearDesc1;
@property (nonatomic, weak) IBOutlet UILabel *labelDesignerLicenseOneYearDesc2;
@property (nonatomic, weak) IBOutlet UILabel *labelDesignerLicenseOneYearDesc3;
@property (nonatomic, weak) IBOutlet UILabel *labelDesignerLicenseOneYearDesc4;
@property (nonatomic, weak) IBOutlet UILabel *labelDesignerKeyActivated;
@property (nonatomic, weak) IBOutlet UILabel *labelDesignerKeyExpires;
@property (nonatomic, weak) IBOutlet UILabel *labelDesignerValueActivated;
@property (nonatomic, weak) IBOutlet UILabel *labelDesignerValueExpires;

@property (nonatomic, weak) IBOutletCollection(UILabel) NSArray *labelsShowWhenActivated;
@property (nonatomic, weak) IBOutletCollection(UILabel) NSArray *labelsHideWhenActivated;

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicatorDesignerLicenseOneYear;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator2;

@property (nonatomic, copy) MTBlockCompletion standardCompletion;
@property (nonatomic, copy) MTStoreKitNonRenewableLicensedUser licenseUserCompletion;

@end

@implementation MTLicensingViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.preferredContentSize = CGSizeMake(380.0000f, 480.0000f);
    }
}

- (void)initalizationComplete:(BOOL)success error:(NSError *)error {
    [self.activityIndicatorDesignerLicenseOneYear stopAnimating];
    [self.activityIndicator2 stopAnimating];
    
    [self enableUserInterface];
    if ([MADApplication isMADDesigner]) {
        self.viewBuyButtonsBackground.backgroundColor = [MADColorEverydayApps newColorBlue];
        (self.buttonBuyNowDesignerOneYear).enabled = success;
        [self.buttonBuyNowDesignerOneYear setHidden:NO];
        (self.buttonBuyNowDesignerOneMonth).enabled = success;
        [self.buttonBuyNowDesignerOneMonth setHidden:NO];
    } else if ([MADApplication isMADViewer]) {
        self.viewBuyButtonsBackground.backgroundColor = [MADColorEverydayApps newColorBlue];
        (self.buttonBuyNowViewerOneYear).enabled = success;
        [self.buttonBuyNowViewerOneYear setHidden:NO];
        (self.buttonBuyNowViewerOneMonth).enabled = success;
        [self.buttonBuyNowViewerOneMonth setHidden:NO];
    }
    
    NSArray *products = [MTStoreKitController sharedObject].products;
    
    NSNumberFormatter *priceFormatter = [[NSNumberFormatter alloc] init];
    priceFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
    
    for (SKProduct *product in products) {
        
        if ([product.productIdentifier isEqualToString:MTStoreKitProductIdentifierDesignerSubscriptionYear1]) {
            
            priceFormatter.locale = product.priceLocale;
            NSString *priceString = [priceFormatter stringFromNumber:product.price];
            [self.buttonBuyNowDesignerOneYear setTitle:priceString forState:UIControlStateNormal];
            
        } else if ([product.productIdentifier isEqualToString:MTStoreKitProductIdentifierDesignerSubscriptionMonth1]) {
            
            priceFormatter.locale = product.priceLocale;
            NSString *priceString = [priceFormatter stringFromNumber:product.price];
            [self.buttonBuyNowDesignerOneMonth setTitle:priceString forState:UIControlStateNormal];
            
        } else if ([product.productIdentifier isEqualToString:MTStoreKitProductIdentifierViewerSubscriptionMonth1]) {
            
            priceFormatter.locale = product.priceLocale;
            NSString *priceString = [priceFormatter stringFromNumber:product.price];
            [self.buttonBuyNowViewerOneMonth setTitle:priceString forState:UIControlStateNormal];
            
        } else if ([product.productIdentifier isEqualToString:MTStoreKitProductIdentifierViewerSubscriptionYear1]) {
            
            priceFormatter.locale = product.priceLocale;
            NSString *priceString = [priceFormatter stringFromNumber:product.price];
            [self.buttonBuyNowViewerOneYear setTitle:priceString forState:UIControlStateNormal];
            
        }
    }
}

- (void)licenseUserCompletion:(BOOL)isLicensedUser andExperationDate:(NSDate *)experationDate {
    if (isLicensedUser) {
        
        [self showLicensingDetailsWithExperationDate:experationDate];
        [self.activityIndicatorDesignerLicenseOneYear stopAnimating];
        [self.activityIndicator2 stopAnimating];
        
        BOOL allowPurchase = experationDate.timeIntervalSinceNow < MTTimeIntervalDay * 15;
        if ([MADApplication isMADDesigner]) {
            self.viewBuyButtonsBackground.backgroundColor = !allowPurchase ? [MADColorEverydayApps newColorBlue] : [MADColorEverydayApps newColorBlue];
            (self.buttonBuyNowDesignerOneYear).enabled = allowPurchase;
            (self.buttonBuyNowDesignerOneYear).hidden = !allowPurchase;
            (self.buttonBuyNowDesignerOneMonth).enabled = allowPurchase;
            (self.buttonBuyNowDesignerOneMonth).hidden = !allowPurchase;
        } else if ([MADApplication isMADViewer]) {
            self.viewBuyButtonsBackground.backgroundColor = !allowPurchase ? [MADColorEverydayApps newColorBlue] : [MADColorEverydayApps newColorBlue];
            (self.buttonBuyNowViewerOneMonth).enabled = allowPurchase;
            (self.buttonBuyNowViewerOneMonth).hidden = !allowPurchase;
            (self.buttonBuyNowViewerOneYear).enabled = allowPurchase;
            (self.buttonBuyNowViewerOneYear).hidden = !allowPurchase;
        }
        
    } else {
        
        [self.labelsShowWhenActivated enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [obj setHidden: YES];
        }];
        [self.labelsHideWhenActivated enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [obj setHidden: NO];
        }];
        
        if ([MADApplication isMADDesigner]) {
            self.viewBuyButtonsBackground.backgroundColor = [MADColorEverydayApps newColorBlue];
            [self.buttonBuyNowDesignerOneYear setEnabled:NO];
            [self.buttonBuyNowDesignerOneMonth setEnabled:NO];
        } else if ([MADApplication isMADViewer]) {
            self.viewBuyButtonsBackground.backgroundColor = [MADColorEverydayApps newColorBlue];
            [self.buttonBuyNowViewerOneYear setEnabled:NO];
            [self.buttonBuyNowViewerOneMonth setEnabled:NO];
        }
        
        [self.activityIndicatorDesignerLicenseOneYear startAnimating];
        [self.activityIndicator2 startAnimating];
        
        NSArray *productIds;
        if ([MADApplication isMADDesigner]) {
            productIds = @[MTStoreKitProductIdentifierDesignerSubscriptionMonth1,
                           MTStoreKitProductIdentifierDesignerSubscriptionYear1];
        } else if ([MADApplication isMADViewer]) {
            productIds = @[MTStoreKitProductIdentifierViewerSubscriptionMonth1,
                           MTStoreKitProductIdentifierViewerSubscriptionYear1];
        } else {
            productIds = @[];
        }
        [self disableUserInterface];
        
        MTLicensingViewController * __weak weakself = self;
        MTBlockCompletion initalizationComplete = ^(BOOL success, NSError *error) {
            [weakself initalizationComplete:success error:error];
        };
        [[MTStoreKitController sharedObject] initializeProductsWithIdentifiers: productIds
                                                                   completion: initalizationComplete];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [[MTVerificationController sharedInstance] iOS7VerifyReceipt];
    
    MTLicensingViewController * __block __weak weakViewController = self;

    MTStoreKitNonRenewableLicensedUser licenseUserCompletion = ^(BOOL isLicensedUser, NSDate *experationDate) {
        [weakViewController licenseUserCompletion:isLicensedUser andExperationDate:experationDate];
    };
    
    self.licenseUserCompletion = licenseUserCompletion;
    
    MTBlockCompletion completion = ^(BOOL success, NSError *error){
        [self enableUserInterface];
        [[MTStoreKitController sharedObject] licensedUser:self.licenseUserCompletion];
        if (success == NO) {
            [NSError presentError: error onViewController: self completion: NULL];
        }
    };
    self.standardCompletion = completion;

    if ([MADApplication isMADDesigner]) {
        self.buttonBuyNowDesignerOneYear.layer.cornerRadius = 6.6666f;
        self.buttonBuyNowDesignerOneMonth.layer.cornerRadius = 6.6666f;
    } else if ([MADApplication isMADViewer]) {
        self.buttonBuyNowViewerOneYear.layer.cornerRadius = 6.6666f;
        self.buttonBuyNowViewerOneMonth.layer.cornerRadius = 6.6666f;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if ([MADApplication isMADDesigner]) {
        //[self viewBuyButtonsBackground].backgroundColor = YES ? [UIColor whiteColor] : [UIColor lightGrayColor];
        self.buttonBuyNowDesignerOneYear.enabled = NO;
        self.buttonBuyNowDesignerOneMonth.enabled = NO;
    } else if ([MADApplication isMADViewer]) {
        //[self viewBuyButtonsBackground].backgroundColor = YES ? [UIColor whiteColor] : [UIColor lightGrayColor];
        self.buttonBuyNowViewerOneYear.enabled = NO;
        self.buttonBuyNowViewerOneMonth.enabled = NO;
    }

    [[MTStoreKitController sharedObject] licensedUser:self.licenseUserCompletion];
    
}

- (void)showLicensingDetailsWithExperationDate:(NSDate *)experationDate {
    NSString *dateString = [NSDateFormatter localizedStringFromDate:experationDate
                                                          dateStyle:NSDateFormatterLongStyle
                                                          timeStyle:NSDateFormatterNoStyle];
    self.labelDesignerValueExpires.text = dateString;
    [self.labelsShowWhenActivated enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj setHidden: NO];
    }];
    [self.labelsHideWhenActivated enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj setHidden: YES];
    }];
}

- (void)hideLicensingDetails {
    [self.labelsShowWhenActivated enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj setHidden: YES];
    }];
    [self.labelsHideWhenActivated enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj setHidden: NO];
    }];
}

- (void)disableUserInterface {
    if ([MADApplication isMADDesigner]) {
        [self.buttonBuyNowDesignerOneYear setEnabled:NO];
        [self.buttonBuyNowDesignerOneMonth setEnabled:NO];
        [self.buttonBuyNowDesignerOneYear setHidden:YES];
        [self.buttonBuyNowDesignerOneMonth setHidden:YES];
    } else if ([MADApplication isMADViewer]) {
        [self.buttonBuyNowViewerOneYear setEnabled:NO];
        [self.buttonBuyNowViewerOneMonth setEnabled:NO];
        [self.buttonBuyNowViewerOneYear setHidden:YES];
        [self.buttonBuyNowViewerOneMonth setHidden:YES];
    }
    [self.buttonDone setEnabled:NO];
    [self.swipeDone setEnabled:NO];
    [self.buttonRestore setEnabled:NO];
}

- (void)enableUserInterface {
    if ([MADApplication isMADDesigner]) {
        [self.buttonBuyNowDesignerOneYear setEnabled:YES];
        [self.buttonBuyNowDesignerOneMonth setEnabled:YES];
        [self.buttonBuyNowDesignerOneYear setHidden:NO];
        [self.buttonBuyNowDesignerOneMonth setHidden:NO];
    } else if ([MADApplication isMADViewer]) {
        [self.buttonBuyNowViewerOneYear setEnabled:YES];
        [self.buttonBuyNowViewerOneMonth setEnabled:YES];
        [self.buttonBuyNowViewerOneYear setHidden:NO];
        [self.buttonBuyNowViewerOneMonth setHidden:NO];
    }
    [self.buttonDone setEnabled:YES];
    [self.swipeDone setEnabled:YES];
    [self.buttonRestore setEnabled:YES];
}

- (IBAction)done:(id)sender {
    [self.delegate viewControllerDidFinish: self];
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

- (void)indicateStartUpdating {
    self.viewBuyButtonsBackground.backgroundColor = [UIColor lightGrayColor];
    [self disableUserInterface];
    [self.activityIndicatorDesignerLicenseOneYear startAnimating];
    [self.activityIndicator2 startAnimating];
}

- (void)licenseProductWithIdentifier:(NSString *)identifier {
    [self indicateStartUpdating];
    
    NSArray *products = [MTStoreKitController sharedObject].products;
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(SKProduct * evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject.productIdentifier isEqualToString:identifier];
    }];
    NSArray *productArray = [products filteredArrayUsingPredicate:predicate];
    if (productArray.count > 0) {
        [[MTStoreKitController sharedObject] purchaseProduct: productArray[0]
                                                  completion: self.standardCompletion];
    } else {
        [self enableUserInterface];
    }
}

@end
