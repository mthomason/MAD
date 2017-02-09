//
//  UIViewControllerObjectSelector.m
//  Reports
//
//  Created by Michael Thomason on 1/15/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
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

#import <MAD/RptqDocumentElementAggregate+Extras.h>

#import "MADNavigationBarTitleView.h"

#import "MTQueryBuilderChooseFieldDelegate.h"
#import "MTQueryBuilderChooseFieldViewController.h"
#import "MTDocumentObjectNewAggregateViewController.h"
#import "MTDocumentObjectNewStaticLabelViewController.h"
#import "MTGroupByViewController.h"

#import "MADDesignerViewController.h"

#import "MTStoreKitController.h"
#import "MTStoreKitController+Features.h"
#import "MADDocumentObjectCollectionViewCell.h"

#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryField+Extras.h>

#import "MADLabelTitle.h"

static const NSInteger MADViewTagAggregateFunctions             = 2003;
static const NSInteger MADViewTagGroupByOptions                 = 2011;
static const NSInteger MADViewTagDocumentObjectNewAggregate     = 2017;
static const NSInteger MADViewTagDocumentObjectNewLabelStatic   = 2027;
static const NSInteger MADViewTagFieldOrFormulaSelector         = 2029;

@interface MADDesignerElementPickerViewController ()
    <MTQueryBuilderChooseFieldDelegate,
        MADAggregateFunctionsViewControllerDelegate,
        MADGroupByViewControllerDelegate,
        UINavigationControllerDelegate,
        UICollectionViewDataSource,
        UICollectionViewDelegateFlowLayout>

    @property (nonatomic, weak) IBOutlet UINavigationBar *navigationBar;
    @property (nonatomic, strong) MTDocumentObjectNewAggregateViewController *aggregateViewController;
    @property (nonatomic, assign) MTAggregateGroupByType aggregateGroupByType;
    @property (nonatomic, assign) NSUInteger aggregateGroupBySectionNumber;
    @property (nonatomic, strong) NSArray *dataSource;

    - (IBAction)done:(id)sender;

@end

@implementation MADDesignerElementPickerViewController

#pragma mark - Storyboard Interactions

- (BOOL)canPerformUnwindSegueAction:(SEL)action fromViewController:(UIViewController *)fromViewController withSender:(id)sender {
    return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.destinationViewController respondsToSelector:@selector(setDocument:)]) {
        
        MADocument *document = _document;
        [segue.destinationViewController setDocument: document];
        
    }
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification,
                                    segue.destinationViewController.accessibilityElements.firstObject);
    
}

- (void)performSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    [super performSegueWithIdentifier:identifier sender:sender];
}



#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    MADLabelTitle *titleView = [[MADLabelTitle alloc] initWithFrame:CGRectZero];
    titleView.text = NSLocalizedString(@"MAD Objects", @"Title of the document object select");
    titleView.accessibilityLabel = NSLocalizedString(@"Object Selector", @"Object Selector");
    
    self.navigationItem.titleView = titleView;
    self.navigationController.view.backgroundColor = [UIColor clearColor];
    self.navigationController.view.opaque = NO;
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.opaque = NO;
    self.view.backgroundColor = [UIColor clearColor];
    self.view.opaque = NO;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.preferredContentSize = CGSizeMake(320.0000f, 320.0000f);
    self.navigationController.preferredContentSize = CGSizeMake(320.0000f, 320.0000f);
    
    NSMutableArray *dataSource = [[NSMutableArray alloc] initWithCapacity:6];
    NSNumber *labelDynamic =    [[NSNumber alloc] initWithShort:MTDocumentObjectTypeLabelDynamic];
    NSNumber *labelStatic =     [[NSNumber alloc] initWithShort:MTDocumentObjectTypeLabelStatic];
    NSNumber *aggregate =       [[NSNumber alloc] initWithShort:MTDocumentObjectTypeAggregate];
    NSNumber *image =           [[NSNumber alloc] initWithShort:MTDocumentObjectTypeImage];
    NSNumber *whitespace =      [[NSNumber alloc] initWithShort:MTDocumentObjectTypeWhtiespace];
    NSArray *defaults = [[NSArray alloc] initWithObjects: labelDynamic, labelStatic, aggregate,
                                                          image, whitespace, nil];
    [dataSource addObjectsFromArray:defaults];
    
    if ([MTStoreKitController sharedObject].barcodeDesignerEnabled) {
        NSNumber *barcode = [NSNumber numberWithShort: MTDocumentObjectTypeBarcode];
        [dataSource addObject:barcode];
    }
    
    self.dataSource = dataSource;
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
    [self.objectSelectorDelegate viewControllerDidFinish: self];
}

#pragma mark - UICollectionViewDataSource

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    NSNumber *madob = self.dataSource[(NSUInteger)indexPath.row];
 
    switch (madob.shortValue) {

        case MTDocumentObjectTypeAggregate:
            [self performSegueWithIdentifier:@"MTIdentifierSeguePushAggregateLabelNew" sender:self];
            break;

        case MTDocumentObjectTypeBarcode:
            [self performSegueWithIdentifier:@"MTIdentifierSeguePushBarcodeLabelNew" sender:self];
            break;

        case  MTDocumentObjectTypeLabelDynamic:
            [self performSegueWithIdentifier:@"MTIdentifierSeguePushSelectField" sender:self];
            break;

        case MTDocumentObjectTypeLabelStatic:
            [self performSegueWithIdentifier:@"MTIdentifierSeguePushStaticLabelNew" sender:self];
            break;
            
        case MTDocumentObjectTypeImage:
            [self presentImagePicker];
            break;

        default:
            break;
    }
}

- (void)presentImagePicker {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.delegate = (id <UINavigationControllerDelegate ,UIImagePickerControllerDelegate>)self.objectSelectorDelegate;
    imagePicker.navigationBar.barTintColor = [MADColorEverydayApps newColorAnalogous4];
    [self presentViewController:imagePicker animated:YES completion:NULL];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *MADIdentiferDocumentObjectCell = @"MADIdentiferDocumentObjectCell";
    
    MADDocumentObjectCollectionViewCell *result;
    result = [collectionView dequeueReusableCellWithReuseIdentifier: MADIdentiferDocumentObjectCell
                                                       forIndexPath: indexPath];
    NSNumber * __weak  madob = self.dataSource[(NSUInteger)indexPath.row];
    short madobValue = madob.shortValue;
    
    result.type = madobValue;
    result.contentView.tag = madobValue;
    
    if (result.selectedBackgroundView == nil) {
    
        UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:result.frame];
        UIColor *bgColor = [[UIColor alloc] initWithWhite:0.30000f alpha:0.30000f];
        selectedBackgroundView.backgroundColor = bgColor;
        result.selectedBackgroundView = selectedBackgroundView;
        
    }
    return result;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {

    switch (section) {

        case 0:
            return (NSInteger)self.dataSource.count;
            break;

        default:
            return 0;
            break;
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

#pragma mark - UICollectionViewFlowLayoutDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return CGSizeMake(150.0000f, 100.0000f);

}

#pragma mark - Actions

#pragma mark
#pragma mark - Aggregate Functions View Controller Delegate Protocol

- (void)didSelectFunction:(MTAggregateFunctionType)functionType {
    [self displaySelectedFunction:functionType];
    [self.navigationBar popNavigationItemAnimated:YES];
}

- (void)displaySelectedFunction:(MTAggregateFunctionType)functionType {
    if (self.aggregateViewController) {
        NSString *functionName = [RptqDocumentElementAggregate newStringDisplayForType:functionType];
        NSString *detailText = [[NSString alloc] initWithFormat:@"%@(x)", functionName];
        (self.aggregateViewController.tableViewCellAggrageFunction.detailTextLabel).text = detailText;
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

- (void)tableViewControllerChooseFieldDidFinish:(MTQueryBuilderChooseFieldViewController *)controller
                                      withField:(RptqQueryField *)field {
    
    switch (controller.view.tag) {
            
        case MTDocumentObjectTypeLabelDynamic:
            
            //[self performSegueWithIdentifier:@"MTIdentifierSeguePushSelectField" sender:(id)];
            //[[self objectSelectorDelegate] viewControllerDidFinish:self];
            
            break;
            
        case MADViewTagFieldOrFormulaSelector: {
            
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

- (void)didSelectGroupBySectionNumber:(NSUInteger)groupNumber {
    self.aggregateGroupByType = MTAggregateGroupByTypeSection;
    self.aggregateGroupBySectionNumber = groupNumber;
    [self displaySelectedGroupByType];
    [self.navigationBar popNavigationItemAnimated:YES];
}

- (void)displaySelectedGroupByType {

    if (_aggregateViewController) {
        
        UITableViewCell *cell;
        cell = _aggregateViewController.tableViewCellAggregateGroupBy;
        
        switch (_aggregateGroupByType) {
        
            case MTAggregateGroupByTypeSection: {

                NSUInteger group = self.aggregateGroupBySectionNumber;
                NSString *format = [RptqDocumentElementAggregate newStringDisplayForGroupByType: MTAggregateGroupByTypeSection];
                NSString *detail = [[NSString alloc] initWithFormat:format, group];
                cell.detailTextLabel.text = detail;
                break;
                
            }
            
            case MTAggregateGroupByTypeReport: {

                NSString *detailText = [RptqDocumentElementAggregate newStringDisplayForGroupByType: MTAggregateGroupByTypeReport];
                cell.detailTextLabel.text = detailText;
                break;
                
            }
            case MTAggregateGroupByTypePage: {

                NSString *detailText = [RptqDocumentElementAggregate newStringDisplayForGroupByType: MTAggregateGroupByTypePage];
                cell.detailTextLabel.text = detailText;
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

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch (tableView.tag) {
        case MADViewTagFieldOrFormulaSelector:

            switch (indexPath.row) {
                
                case 0: {   // Group by a Field
                    
                    NSString *navigationItemTitle = NSLocalizedString(@"Field Selector", @"Field Selector");
                    UINavigationItem *itemToPush = [[UINavigationItem alloc] initWithTitle: navigationItemTitle];
                    [self.navigationBar pushNavigationItem:itemToPush animated:YES];
                    break;

                }
                case 1: {   // Group by a Formula

                    NSString *navigationItemTitle = NSLocalizedString(@"Formula Selector", @"Formula Selector");
                    UINavigationItem *itemToPush = [[UINavigationItem alloc] initWithTitle: navigationItemTitle];
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

                    NSString *navigationItemTitle = NSLocalizedString(@"Function Selector", @"Function Selector");
                    UINavigationItem *itemToPush = [[UINavigationItem alloc] initWithTitle: navigationItemTitle];
                    [self.navigationBar pushNavigationItem:itemToPush animated:YES];
                    break;
                    
                }
                case 1: {   // Input *x*
                    
                    NSString *navigationItemTitle = NSLocalizedString(@"Data Object Selector", @"Data Object Selector");
                    UINavigationItem *itemToPush = [[UINavigationItem alloc] initWithTitle: navigationItemTitle];
                    [self.navigationBar pushNavigationItem:itemToPush animated:YES];
                    break;
                }
                case 2: {   //Group By *For Each*
                    NSString *navigationItemTitle = NSLocalizedString(@"Group By Selector", @"Group By Selector");
                    UINavigationItem *itemToPush = [[UINavigationItem alloc] initWithTitle: navigationItemTitle];
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
    id <MADDesignerElementPickerDelegate> objectSelectorDelegate = self.objectSelectorDelegate;
    [objectSelectorDelegate viewControllerDidFinish: self];
    return objectSelectorDelegate != nil;
}

@end
