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
#import "UIAlertController+Constructors.h"

@interface MADStoreViewController ()
    <MTViewControllerProtocol>

@property (nonatomic, strong) NSNumberFormatter *priceFormatter;

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
        [[MTStoreKitController sharedObject] initalizeProductsWithIdentifiers:products completion:^(BOOL success, NSError *error) {
            [self.collectionView reloadData];
        }];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ((MADReceiptViewController *)((UINavigationController *)segue.destinationViewController).topViewController).delegate = self;
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView { return 1; }

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [MTStoreKitController sharedObject].products.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MADCollectionViewCellProductFeature *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    SKProduct *product =[MTStoreKitController sharedObject].products[indexPath.item];
    cell.labelTitle.text = product.localizedTitle;
    cell.labelDescription.text = product.localizedDescription;
    self.priceFormatter.locale = product.priceLocale;
    BOOL ownIt = [[MTVerificationController sharedInstance] purchasedProductWithID:product.productIdentifier];
    if (!ownIt) {
        cell.labelPrice.text = [self.priceFormatter stringFromNumber:product.price];
    } else {
        cell.labelPrice.text = @"✓";
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
    [[MTStoreKitController sharedObject] purchaseProduct:product completion:^(BOOL success, NSError *error) {
        UIAlertController *alert = success ? [UIAlertController nofityTransactionComplete] : [UIAlertController error:error];
        [self presentViewController: alert animated: YES completion: nil];
        [self.collectionView reloadData];
    }];

}

- (IBAction)actionDone:(id)sender {
    [self.delegate viewControllerDidCancel:self];
}

#pragma mark - UICollectionViewFlowLayout Delegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(collectionView.bounds.size.width >= 480 ? (collectionView.bounds.size.width / 2.0) - (8.0000f * 3) : collectionView.bounds.size.width - 8.0000f * 2,
                      220.0000f);
}

@end
