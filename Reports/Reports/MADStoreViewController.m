//
//  MADStoreViewController.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/18/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADStoreViewController.h"
#import "MTStoreKitController.h"
#import "MADCollectionViewCellProductFeature.h"
#import <StoreKit/StoreKit.h>
#import "MADWatermarkView.h"
#import "MADNavigationBarTitleView.h"
#import "MUIViewControllerDelegate.h"
#import "MADReceiptViewController.h"
#import "MADFeatures.h"

@interface MADStoreViewController ()
    <MTViewControllerProtocol>

@property (nonatomic, strong) NSNumberFormatter *priceFormatter;

@end

@implementation MADStoreViewController

- (void)viewControllerDidCancel:(id)sender {
    [self viewControllerDidFinish:sender];
}

- (void)viewControllerDidFinish:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [self.collectionView reloadData];
    }];
}

- (IBAction)unwindToStore:(UIStoryboardSegue*)sender {
    
    //UIViewController *sourceViewController = sender.sourceViewController;
    
    // Pull any data from the view controller which initiated the unwind segue.
    
}

static NSString * const reuseIdentifier = @"MADProdcutFeatureDefault";

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
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    //[self.collectionView registerClass:[MADCollectionViewCellProductFeature class] forCellWithReuseIdentifier:reuseIdentifier];
    
    // Do any additional setup after loading the view.
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


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ((MADReceiptViewController *)((UINavigationController *)segue.destinationViewController).topViewController).delegate = self;
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [MTStoreKitController sharedObject].products.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MADCollectionViewCellProductFeature *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    SKProduct *product =[MTStoreKitController sharedObject].products[indexPath.item];
    cell.labelTitle.text = product.localizedTitle;
    cell.labelDescription.text = product.localizedDescription;
    self.priceFormatter.locale = product.priceLocale;
    cell.labelPrice.text = [self.priceFormatter stringFromNumber:product.price];
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

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item


- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

*/

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    //MADCollectionViewCellProductFeature *cell = ((MADCollectionViewCellProductFeature *)[collectionView cellForItemAtIndexPath:indexPath]);
    //cell.labelDescription.textColor = cell.labelTitle.highlightedTextColor;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    SKProduct *product = [MTStoreKitController sharedObject].products[indexPath.item];
    [[MTStoreKitController sharedObject] purchaseProduct:product completion:^(BOOL success, NSError *error) {
        [self.collectionView reloadData];
    }];

}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    //MADCollectionViewCellProductFeature *cell = ((MADCollectionViewCellProductFeature *)[collectionView cellForItemAtIndexPath:indexPath]);
    //cell.image.highlightedImage = [UIImage imageNamed:@"MADInfinity64"] im
}

- (IBAction)actionDone:(id)sender {
    [self.delegate viewControllerDidCancel:self];
}

@end
