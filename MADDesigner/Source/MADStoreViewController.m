//
//  MADStoreViewController.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/18/15.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "MADStoreViewController.h"
#import "MADStoreKitController.h"
#import "MADVerificationController.h"
#import "MADCollectionViewCellProductFeature.h"
#import "MADWatermarkView.h"
#import "MADReceiptViewController.h"
#import "MADFeatures.h"
#import "MADSalesReceipt.h"

#import <MADAPI/MADViewControllerStandardProtocol.h>
#import <MADCocoaExtensions/MADAlertController.h>
#import <MADCocoaExtensions/MADViewHelpers.h>
#import <MADCocoaExtensions/MADLabelTitle.h>

#import <UIKit/UIView.h>

static NSString * const MADTextYouGotIt     = @"You Got It";
static NSString * const MADTextYouItsYours  = @"It's Yours";
static NSString * const MADTextFreeGift     = @"Access to this feature is a free gift for charter "
                                              @"members. That's you! How rare is that?";
static NSString * const MADTextAlready      = @"You already got this feature. Make sure to collect them all.";

@interface MADStoreViewController () <MADViewControllerStandardProtocol>

@property (nonatomic, strong) NSNumberFormatter *priceFormatter;
@property (nonatomic, assign) BOOL charterMember;

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

- (IBAction)unwindToStore:(UIStoryboardSegue*)sender { }

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		
		NSNumberFormatter *priceFormatter = [[NSNumberFormatter alloc] init];
		priceFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
		self.priceFormatter = priceFormatter;
		self.charterMember = [MADVerificationController sharedInstance].receipt.charterMembership;
		
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];

	MADWatermarkView *watermarkView = [[MADWatermarkView alloc] initWithFrame: self.collectionView.bounds];
	self.collectionView.backgroundView = watermarkView;
	self.collectionView.scrollEnabled = YES;
	self.collectionView.scrollsToTop = YES;
	self.collectionView.allowsSelection = YES;
	
	self.collectionView.backgroundColor = /*[UIColor clearColor];*/             [[UIColor redColor] colorWithAlphaComponent:.90];
	self.navigationController.view.backgroundColor = /*[UIColor clearColor];*/  [[UIColor greenColor] colorWithAlphaComponent:.70];
	self.view.backgroundColor = /*[UIColor clearColor];*/                       [[UIColor purpleColor] colorWithAlphaComponent:.30];
	self.collectionView.backgroundView = nil;
	((UICollectionViewFlowLayout *)self.collectionViewLayout).sectionInset = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);
	
	self.collectionView.backgroundColor = [UIColor clearColor];
	
	UIVisualEffectView *visualEffectsView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleProminent]];
	visualEffectsView.tintColor = [UIColor redColor];
	visualEffectsView.frame = self.collectionView.frame;
	visualEffectsView.autoresizingMask = MADViewAutoresizingFlexable();
	self.collectionView.backgroundView = visualEffectsView;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	if ([MADStoreKitController sharedObject].products.count <= 0) {
		MADFeatures *features = [[MADFeatures alloc] init];
		[features loadFeaturesFromPlist];

		NSArray <NSString *> *products = [features availableFeaturesProductIDs];
		
		UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleMedium];
		[activityIndicator startAnimating];
		activityIndicator.hidden = NO;
		activityIndicator.hidesWhenStopped = NO;
		UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
		[self.navigationItem setLeftBarButtonItem: barButtonItem animated: animated];
		
		__weak MADStoreViewController *weakSelf = self;
		[[MADStoreKitController sharedObject] initializeProductsWithIdentifiers: products
																	completion: ^(BOOL success, NSError *error) {
			dispatch_async(dispatch_get_main_queue(), ^{
				__strong MADStoreViewController *strongSelf = weakSelf;
				if (!success && error) {
					id alert = [MADAlertController newAlertControllerError:error];
					[strongSelf presentViewController:alert animated:YES completion:nil];
				}
				[strongSelf.navigationItem setLeftBarButtonItem:nil animated:YES];
				[strongSelf.collectionView reloadData];
			});
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
	return (NSInteger)[MADStoreKitController sharedObject].products.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
				  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *MADStoreCellReuseIdentifier = @"MADProdcutFeatureDefault";
	MADCollectionViewCellProductFeature *cell = [collectionView dequeueReusableCellWithReuseIdentifier: MADStoreCellReuseIdentifier
																						  forIndexPath: indexPath];
	SKProduct *product =[MADStoreKitController sharedObject].products[(NSUInteger)indexPath.item];
	cell.labelTitle.text = product.localizedTitle;
	cell.labelDescription.text = product.localizedDescription;
	self.priceFormatter.locale = product.priceLocale;

	if (self.charterMember && [MADVerificationController charterMemberGiftLookup:product.productIdentifier]) {
		cell.labelPrice.text = @"";
		cell.labelPrice.font = [UIFont fontWithName: @"FontAwesome"
											   size: cell.labelPrice.font.pointSize];
	} else {
		BOOL ownIt = [[MADVerificationController sharedInstance] purchasedProductWithID:product.productIdentifier];
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

- (UIContextMenuConfiguration *) collectionView:(UICollectionView *) collectionView
   contextMenuConfigurationForItemsAtIndexPaths:(NSArray<NSIndexPath *> *) indexPaths
										  point:(CGPoint) point {
	return nil;
}

/*
 - (UIContextMenuConfiguration *) collectionView:(UICollectionView *) collectionView
 contextMenuConfigurationForItemsAtIndexPaths:(NSArray<NSIndexPath *> *) indexPaths
 point:(CGPoint) point {
 return nil;
 }

 */

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	[collectionView deselectItemAtIndexPath:indexPath animated:YES];
	SKProduct *product = [MADStoreKitController sharedObject].products[(NSUInteger)indexPath.item];
	if (self.charterMember && [MADVerificationController charterMemberGiftLookup:product.productIdentifier]) {
		UIAlertController *alert = [MADAlertController newAlertControllerErrorDisplayErrorWithTitle: NSLocalizedString(MADTextYouGotIt, MADTextYouGotIt)
																							message: NSLocalizedString(MADTextFreeGift, MADTextFreeGift)
																					  andCompletion: nil];
		[self presentViewController:alert animated:YES completion:nil];
	} else {
		BOOL ownIt = [[MADVerificationController sharedInstance] purchasedProductWithID:product.productIdentifier];
		if (ownIt) {
			UIAlertController *alert = [MADAlertController newAlertControllerErrorDisplayErrorWithTitle: NSLocalizedString(MADTextYouItsYours, MADTextYouItsYours)
																								message: NSLocalizedString(MADTextAlready, MADTextAlready)
																						  andCompletion: nil];
			[self presentViewController:alert animated:YES completion:nil];
		} else {
			[[MADVerificationController sharedInstance] freeForCharterMemembers:product.productIdentifier];
			[[MADStoreKitController sharedObject] purchaseProduct: product
													  completion: ^(BOOL success, NSError *error) {
				UIAlertController *alert = success ? [MADAlertController newAlertControllerNofityTransactionComplete] :
				[MADAlertController newAlertControllerError:error];
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

- (CGSize)collectionView:(UICollectionView *)collectionView
				  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	return CGSizeMake(collectionView.bounds.size.width >= 480.0 ?
					  (collectionView.bounds.size.width / 2.0) - (8.0 * 3.0) :
					  collectionView.bounds.size.width - 8.0 * 2.0, 220.0);
	
}

@end
