//
//  UIViewControllerObjectSelector.m
//  Reports
//
//  Created by Michael Thomason on 1/15/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDesignerElementPickerViewController.h"
#import "MADAggregateFunctionsViewControllerDelegate.h"
#import "MADGroupByViewControllerDelegate.h"

#import <UIKit/UIAccessibility.h>
#import <UIKit/UIStoryboardSegue.h>
#import <UIKit/UICollectionViewFlowLayout.h>
#import <UIKit/UIImagePickerController.h>
#import <UIKit/UILabel.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/MADLabelTitle.h>

#import <MAD/MADocument.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqDocumentElementAggregate+Extras.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryField+Extras.h>

#import "MADElementPickerProtocol.h"

#import "MADQueryChooseFieldProtocol.h"
#import "MADQueryChooseFieldController.h"
#import "MTDocumentObjectNewAggregateViewController.h"
#import "MTDocumentObjectNewStaticLabelViewController.h"
#import "MTGroupByViewController.h"

#import "MADDesignerViewController.h"

#import "MADDocumentObjectCollectionViewCell.h"

static const NSInteger MADViewTagAggregateFunctions             = 2003;
static const NSInteger MADViewTagGroupByOptions                 = 2011;
static const NSInteger MADViewTagDocumentObjectNewAggregate     = 2017;
static const NSInteger MADViewTagDocumentObjectNewLabelStatic   = 2027;
static const NSInteger MADViewTagFieldOrFormulaSelector         = 2029;

@interface MADDesignerElementPickerViewController () <MADQueryChooseFieldProtocol, MADAggregateFunctionsViewControllerDelegate, MADGroupByViewControllerDelegate, UINavigationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, assign) MTAggregateGroupByType aggregateGroupByType;
@property (nonatomic, assign) int32_t aggregateGroupBySectionNumber;
@property (nonatomic, weak) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, strong) MTDocumentObjectNewAggregateViewController *aggregateViewController;
@property (nonatomic, strong) NSArray *dataSource;

- (IBAction)done:(id)sender;

@end

@implementation MADDesignerElementPickerViewController

#pragma mark -
#pragma mark Storyboard Interactions

- (BOOL)canPerformUnwindSegueAction:(SEL)action
				 fromViewController:(UIViewController *)fromViewController
							 sender:(nullable id)sender {
	return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.destinationViewController respondsToSelector:@selector(setDocument:)]) {
		[segue.destinationViewController setDocument: _document];
	}
	UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, segue.destinationViewController.accessibilityElements.firstObject);
}

- (void)performSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
	[super performSegueWithIdentifier:identifier sender:sender];
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
	
	MADLabelTitle *titleView = [[MADLabelTitle alloc] initWithFrame:CGRectZero];
	titleView.text = NSLocalizedString(@"MAD Objects", @"Title of the document object select");
	titleView.accessibilityLabel = NSLocalizedString(@"Object Selector", @"Object Selector");
	
	self.navigationItem.titleView = titleView;
	self.view.backgroundColor = [UIColor secondarySystemBackgroundColor];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.preferredContentSize = CGSizeMake(320.0, 320.0);
	self.navigationController.preferredContentSize = CGSizeMake(320.0, 320.0);
	NSMutableArray *dataSource = [[NSMutableArray alloc] initWithCapacity:6];
	NSNumber *labelDynamic = [[NSNumber alloc] initWithShort:MADPrintPageElementTypeLabelDynamic];
	NSNumber *labelStatic = [[NSNumber alloc] initWithShort:MADPrintPageElementTypeLabelStatic];
	NSNumber *aggregate = [[NSNumber alloc] initWithShort:MADPrintPageElementTypeAggregate];
	
	// Add additional items following the pattern below.
	NSNumber *image = [[NSNumber alloc] initWithShort:MADPrintPageElementTypeImage];
	NSNumber *whitespace = [[NSNumber alloc] initWithShort:MADPrintPageElementTypeWhtiespace];
	NSNumber *barcode = [[NSNumber alloc] initWithShort:MADPrintPageElementTypeBarcode];

	[dataSource addObjectsFromArray:@[labelDynamic, labelStatic, aggregate, image, whitespace, barcode]];

	self.dataSource = dataSource;
}

#pragma mark -
#pragma mark Actions

- (IBAction)done:(id)sender {
	[self.objectSelectorDelegate viewControllerDidFinish: self];
}

#pragma mark -
#pragma mark UICollectionViewDataSource

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	
	[collectionView deselectItemAtIndexPath:indexPath animated:YES];
	NSNumber *madob = self.dataSource[(NSUInteger)indexPath.row];
	
	switch (madob.shortValue) {
			
		case MADPrintPageElementTypeWhtiespace: {
			id <MADElementPickerProtocol> delegate = self.objectSelectorDelegate;
			[delegate insertDocumentObjectWhitespace];
			[delegate viewControllerDidFinish:self];
			break;
		}
		case MADPrintPageElementTypeAggregate:
			[self performSegueWithIdentifier:@"MTIdentifierSeguePushAggregateLabelNew" sender:self];
			break;
			
		case MADPrintPageElementTypeBarcode:
			[self performSegueWithIdentifier:@"MTIdentifierSeguePushBarcodeLabelNew" sender:self];
			break;
			
		case  MADPrintPageElementTypeLabelDynamic:
			[self performSegueWithIdentifier:@"MTIdentifierSeguePushSelectField" sender:self];
			break;
			
		case MADPrintPageElementTypeLabelStatic:
			[self performSegueWithIdentifier:@"MTIdentifierSeguePushStaticLabelNew" sender:self];
			break;
			
		case MADPrintPageElementTypeImage:
			[self presentImagePicker];
			break;
			
		default:
			break;
	}
}

- (void)presentImagePicker {
	UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
	imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	imagePicker.delegate = (id <UINavigationControllerDelegate, UIImagePickerControllerDelegate>)self.objectSelectorDelegate;
	imagePicker.navigationBar.barTintColor = [MADColorEverydayApps newColorAnalogous4];
	[self presentViewController:imagePicker animated:YES completion:nil];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *MADIdentiferDocumentObjectCell = @"MADIdentiferDocumentObjectCell";
	
	MADDocumentObjectCollectionViewCell *result = [collectionView dequeueReusableCellWithReuseIdentifier: MADIdentiferDocumentObjectCell
																							forIndexPath: indexPath];
	NSNumber *madob = [self.dataSource[(NSUInteger)indexPath.row] copy];
	short madobValue = madob.shortValue;
	result.type = madobValue;
	result.contentView.tag = madobValue;
	result.detail.textColor = [UIColor labelColor];
	if (result.selectedBackgroundView == nil) {
		UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:result.frame];
		UIColor *bgColor = [[UIColor alloc] initWithWhite:0.30000f alpha:0.30000f];
		selectedBackgroundView.backgroundColor = bgColor;
		result.selectedBackgroundView = selectedBackgroundView;
	}
	
	return result;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	switch (section) {
		case 0:
			return (NSInteger)self.dataSource.count;
		default:
			return 0;
	}
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView { return 1; }

#pragma mark -
#pragma mark UICollectionViewFlowLayoutDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView
				  layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	return CGSizeMake(150.0, 100.0);
}

#pragma mark -
#pragma mark Actions

#pragma mark -
#pragma mark Aggregate Functions View Controller Delegate Protocol

- (void)didSelectFunction:(MTAggregateFunctionType)functionType {
	[self displaySelectedFunction:functionType];
	[self.navigationBar popNavigationItemAnimated:YES];
}

- (void)displaySelectedFunction:(MTAggregateFunctionType)functionType {
	if (self.aggregateViewController) {
		(self.aggregateViewController.tableViewCellAggrageFunction.detailTextLabel).text = [[RptqDocumentElementAggregate newStringDisplayForType:functionType] stringByAppendingString:@"(x)"];
	}
}

- (void)navigationController:(UINavigationController *)navigationController
	  willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
	[viewController.navigationController.navigationBar setHidden:YES];
}

- (void)navigationController:(UINavigationController *)navigationController
	   didShowViewController:(UIViewController *)viewController
					animated:(BOOL)animated {
	
}


#pragma mark
#pragma mark - UITableViewControllerChooseFieldDelegate

- (void)tableViewControllerChooseFieldDidFinish: (MADQueryChooseFieldController *)controller
									withFieldID: (int64_t)fieldID {
	
	switch (controller.view.tag) {
			
		case MADPrintPageElementTypeLabelDynamic:
			
			//[self performSegueWithIdentifier:@"MTIdentifierSeguePushSelectField" sender:(id)];
			//[[self objectSelectorDelegate] viewControllerDidFinish:self];
			
			break;
			
		case MADViewTagFieldOrFormulaSelector: {
			
			RptqQueryField *field = (RptqQueryField *)[self.document.storeContext objectForEntity:NSStringFromClass([RptqQueryField class]) identifier:fieldID];
			NSString *formatString = NSLocalizedString(@"Field: %@", @"Field: %@");
			id display = [field display];
			id detailtext = [[NSString alloc] initWithFormat:formatString, display];
			(self.aggregateViewController.tableViewCellAggregateInput.detailTextLabel).text = detailtext;
			[self.navigationBar popNavigationItemAnimated:YES];
			
			break;
			
		}
		default:
			break;
			
	}
}

#pragma mark
#pragma mark - Group By Functions View Controller Delegate Protocol

- (void)didSelectGroupByPage {
	self.aggregateGroupByType = MTAggregateGroupByTypePage;
	self.aggregateGroupBySectionNumber = 0;
	[self displaySelectedGroupByType];
	[self.navigationBar popNavigationItemAnimated:YES];
}

- (void)didSelectGroupByReport {
	self.aggregateGroupByType = MTAggregateGroupByTypeReport;
	self.aggregateGroupBySectionNumber = 0;
	[self displaySelectedGroupByType];
	[self.navigationBar popNavigationItemAnimated:YES];
}

- (void)didSelectGroupBySectionNumber:(int32_t)groupNumber {
	self.aggregateGroupByType = MTAggregateGroupByTypeSection;
	self.aggregateGroupBySectionNumber = groupNumber;
	[self displaySelectedGroupByType];
	[self.navigationBar popNavigationItemAnimated:YES];
}

- (void)displaySelectedGroupByType {
	
	if (_aggregateViewController) {
		
		UITableViewCell *cell = _aggregateViewController.tableViewCellAggregateGroupBy;
		switch (_aggregateGroupByType) {
				
			case MTAggregateGroupByTypeSection: {
				NSString *format = [RptqDocumentElementAggregate newStringDisplayForGroupByType: MTAggregateGroupByTypeSection];
				cell.detailTextLabel.text = [NSString stringWithFormat:format, self.aggregateGroupBySectionNumber];
				break;
			}
				
			case MTAggregateGroupByTypeReport: {
				cell.detailTextLabel.text = [RptqDocumentElementAggregate newStringDisplayForGroupByType: MTAggregateGroupByTypeReport];
				break;
			}
				
			case MTAggregateGroupByTypePage: {
				cell.detailTextLabel.text = [RptqDocumentElementAggregate newStringDisplayForGroupByType: MTAggregateGroupByTypePage];
				break;
			}
				
			default:
				cell.detailTextLabel.text = @"";
				break;
		}
	}
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath { }
- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath { }
- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath { }

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	switch (tableView.tag) {
		case MADViewTagFieldOrFormulaSelector:
			
			switch (indexPath.row) {
					
				case 0: {   // Group by a Field
					
					UINavigationItem *itemToPush = [[UINavigationItem alloc] initWithTitle: NSLocalizedString(@"Field Selector", @"Field Selector")];
					[self.navigationBar pushNavigationItem:itemToPush animated:YES];
					break;
					
				}
				case 1: {   // Group by a Formula
					
					UINavigationItem *itemToPush = [[UINavigationItem alloc] initWithTitle: NSLocalizedString(@"Formula Selector", @"Formula Selector")];
					[self.navigationBar pushNavigationItem:itemToPush animated:YES];
					break;
					
				}
				default:
					break;
			}
			
			break;
			
		case MADViewTagAggregateFunctions:
			break;
			
		case MADViewTagDocumentObjectNewAggregate: {
			
			switch (indexPath.row) {
					
				case 0: {   // Aggrage Function *f(x)*
					
					UINavigationItem *itemToPush = [[UINavigationItem alloc] initWithTitle: NSLocalizedString(@"Function Selector", @"Function Selector")];
					[self.navigationBar pushNavigationItem:itemToPush animated:YES];
					break;
					
				}
				case 1: {   // Input *x*
					
					UINavigationItem *itemToPush = [[UINavigationItem alloc] initWithTitle: NSLocalizedString(@"Data Object Selector", @"Data Object Selector")];
					[self.navigationBar pushNavigationItem:itemToPush animated:YES];
					break;
				}
				case 2: {   //Group By *For Each*
					
					UINavigationItem *itemToPush = [[UINavigationItem alloc] initWithTitle: NSLocalizedString(@"Group By Selector", @"Group By Selector")];
					[self.navigationBar pushNavigationItem:itemToPush animated:YES];
					break;
					
				}
				default:
					break;
			}
			
			break;
		}
			
		case MADViewTagDocumentObjectNewLabelStatic:
			break;
			
		case MADViewTagGroupByOptions:
			break;
			
		default:
			break;
			
	}
}

#pragma mark - Accessibility

- (BOOL)accessibilityPerformEscape {
	id <MADElementPickerProtocol> objectSelectorDelegate = self.objectSelectorDelegate;
	[objectSelectorDelegate viewControllerDidFinish: self];
	return objectSelectorDelegate != nil;
}

@end
