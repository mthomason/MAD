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

@interface MADStoreViewController ()

@property (nonatomic, strong) NSNumberFormatter *priceFormatter;

@end

@implementation MADStoreViewController

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
    
    ((UICollectionViewFlowLayout *)self.collectionViewLayout).sectionInset = UIEdgeInsetsMake(8.0000f, 8.0000f, 8.0000f, 8.0000f);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([MTStoreKitController sharedObject].products.count <= 0) {
        NSArray *products = @[@"com.everydayapps.mad.designer.product.viewer",
                              @"com.everydayapps.mad.designer.product.style.basic",
                              @"com.everydayapps.mad.designer.product.element.barcode",
                              @"com.everydayapps.mad.designer.product.element.images",
                              @"com.everydayapps.mad.designer.product.element.aggregate"];
        [[MTStoreKitController sharedObject] initalizeProductsWithIdentifiers:products completion:^(BOOL success, NSError *error) {
            [self.collectionView reloadData];
        }];
    }
}


- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    if (self.shouldAutorotate) {
        
        //will auto rotate
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [self.collectionView.backgroundView setNeedsLayout];
            [self.collectionView.backgroundView setNeedsDisplay];
        } completion:nil];
        
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];   
}

- (IBAction)actionDone:(id)sender {
    [self.delegate viewControllerDidCancel:self];
}

@end
