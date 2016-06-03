//
//  MADStoreViewController.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/18/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADStoreViewController.h"
#import "MTStoreKitController.h"
#import "MTVerificationController.h"
#import "MADCollectionViewCellProductFeature.h"
#import "MADWatermarkView.h"
#import "MADNavigationBarTitleView.h"
#import "MUIViewControllerDelegate.h"
#import "MADReceiptViewController.h"
#import "MADFeatures.h"
#import "MADSalesReceipt.h"
#import <MADCocoaExtensions/UIBarButtonItem+Constructors.h>
#import <MADCocoaExtensions/UIAlertController+Constructors.h>

@interface MADStoreViewController ()
    <MTViewControllerProtocol>

@property (nonatomic, strong) NSNumberFormatter *priceFormatter;
@property (nonatomic, assign) BOOL charterMember;

@end

@implementation MADStoreViewController

static NSString * const reuseIdentifier = @"MADProdcutFeatureDefault";

- (void)viewControllerDidCancel:(id)sender {
    [self viewControllerDidFinish:sender];
}

- (void)viewControllerDidFinish:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [self.collectionView reloadData];
    }];
}

- (IBAction)unwindToStore:(UIStoryboardSegue*)sender { }

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    NSNumberFormatter *priceFormatter = [[NSNumberFormatter alloc] init];
    priceFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
    self.priceFormatter = priceFormatter;
    
    MADNavigationBarTitleView *titleView = [[MADNavigationBarTitleView alloc] initWithFrame: CGRectZero];
    titleView.text = @"MAD Features";
    self.navigationItem.titleView = titleView;
    
    self.charterMember = [MTVerificationController sharedInstance].receipt.charterMembership;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    MADWatermarkView *watermarkView = [[MADWatermarkView alloc] initWithFrame: self.collectionView.bounds];
    self.collectionView.backgroundView = watermarkView;
    
    self.collectionView.scrollEnabled = YES;
    self.collectionView.scrollsToTop = YES;
    self.collectionView.allowsSelection = YES;
    ((UICollectionViewFlowLayout *)self.collectionViewLayout).sectionInset = UIEdgeInsetsMake(10.0000f, 10.0000f, 10.0000f, 10.0000f);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([MTStoreKitController sharedObject].products.count <= 0) {
        MADFeatures *features = [[MADFeatures alloc] init];
        NSArray *products = [features availableFeaturesProductIDs];
        
        UIBarButtonItem *barButtonItem = [UIBarButtonItem newBarButtonItemActivityIndicator];
        [self.navigationItem setLeftBarButtonItem: barButtonItem animated: animated];

        [[MTStoreKitController sharedObject] initializeProductsWithIdentifiers:products completion:^(BOOL success, NSError *error) {
            if (!success && error) {
                UIAlertController *alert = [UIAlertController newAlertControllerError:error];
                [self presentViewController:alert animated:YES completion:NULL];
            }
            [self.navigationItem setLeftBarButtonItem:nil animated:YES];
            [self.collectionView reloadData];
        }];
    } else {
        [self.collectionView reloadData];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ((MADReceiptViewController *)((UINavigationController *)segue.destinationViewController).topViewController).delegate = self;
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView { return 1; }

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return (NSInteger)[MTStoreKitController sharedObject].products.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MADCollectionViewCellProductFeature *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    SKProduct *product =[MTStoreKitController sharedObject].products[(NSUInteger)indexPath.item];
    cell.labelTitle.text = product.localizedTitle;
    cell.labelDescription.text = product.localizedDescription;
    self.priceFormatter.locale = product.priceLocale;
    
    if (self.charterMember && [MTVerificationController charterMemberGiftLookup:product.productIdentifier]) {
        cell.labelPrice.text = @"";
        cell.labelPrice.font = [UIFont fontWithName:@"FontAwesome" size:cell.labelPrice.font.pointSize];
    } else {
        BOOL ownIt = [[MTVerificationController sharedInstance] purchasedProductWithID:product.productIdentifier];
        if (!ownIt) {
            cell.labelPrice.text = [self.priceFormatter stringFromNumber:product.price];
        } else {
            cell.labelPrice.text = @"✓";
        }
    }
    if ([product.productIdentifier containsString:@"barcode"]) {
        UIImage *barcode = [UIImage imageNamed:@"MADBarcode64"];
        cell.image.image = barcode;
        cell.image.highlightedImage = [barcode imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    } else {
        UIImage *infinity = [UIImage imageNamed:@"MADInfinity64"];
        cell.image.image = infinity;
        cell.image.highlightedImage = [infinity imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return cell;
}

#pragma mark <UICollectionViewDelegate>

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath { return NO; }

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    SKProduct *product = [MTStoreKitController sharedObject].products[indexPath.item];
    if (self.charterMember && [MTVerificationController charterMemberGiftLookup:product.productIdentifier]) {
        NSString *title = NSLocalizedString(@"You Got It", @"You Got It");
        NSString *message = NSLocalizedString(@"Access to this feature is a free gift for charter members. That's you! How rare is that?",
                                              @"Access to this feature is a free gift for charter members. That's you! How rare is that?");
        UIAlertController *alert = [UIAlertController newAlertControllerErrorDisplayErrorWithTitle: title
                                                                                           message: message
                                                                                     andCompletion: ^(UIAlertAction *action) { }];
        [self presentViewController:alert animated:YES completion:NULL];
    } else {
        BOOL ownIt = [[MTVerificationController sharedInstance] purchasedProductWithID:product.productIdentifier];
        if (ownIt) {
            NSString *title = NSLocalizedString(@"It's Yours", @"It's Yours");
            NSString *message = NSLocalizedString(@"You already got this feature. Make sure to collect them all.",
                                                  @"You already got this feature. Make sure to collect them all.");
            UIAlertController *alert = [UIAlertController newAlertControllerErrorDisplayErrorWithTitle: title
                                                                                               message: message
                                                                                         andCompletion: ^(UIAlertAction *action) { }];
            [self presentViewController:alert animated:YES completion:NULL];
        } else {
            [[MTVerificationController sharedInstance] freeForCharterMemembers:product.productIdentifier];
            [[MTStoreKitController sharedObject] purchaseProduct:product completion:^(BOOL success, NSError *error) {
                UIAlertController *alert = success ? [UIAlertController newAlertControllerNofityTransactionComplete] : [UIAlertController newAlertControllerError:error];
                [self presentViewController: alert animated: YES completion: nil];
                [self.collectionView reloadData];
            }];
        }
    }
}

#pragma mark - Actions

- (IBAction)actionDone:(id)sender {
    [self.delegate viewControllerDidCancel:self];
}

#pragma mark - UICollectionViewFlowLayout Delegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(collectionView.bounds.size.width >= 480 ?
                      (collectionView.bounds.size.width / 2.0000f) - (8.0000f * 3) :
                      collectionView.bounds.size.width - 8.0000f * 2, 220.0000f);
}

@end
