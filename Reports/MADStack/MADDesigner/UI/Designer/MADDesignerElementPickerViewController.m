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
#import "MADNavigationBarTitleView.h"

#import "MTAggregateFunctionsViewController.h"

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

const NSInteger MTViewTagAggregateFunctions             = 2003;
const NSInteger MTViewTagGroupByOptions                 = 2011;
const NSInteger MTViewTagDocumentObjectNewAggregate     = 2017;
const NSInteger MTViewTagDocumentObjectNewLabelStatic   = 2027;
const NSInteger MTViewTagFieldOrFormulaSelector         = 2029;

@interface MADDesignerElementPickerViewController ()
    <MTQueryBuilderChooseFieldDelegate,
        MTAggregateFunctionsViewControllerDelegate,
        MTGroupByViewControllerDelegate,
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
        [segue.destinationViewController setDocument:self.document];
    }
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, segue.destinationViewController.accessibilityElements.firstObject);
}

- (void)performSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    [super performSegueWithIdentifier:identifier sender:sender];
}



#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    MADNavigationBarTitleView *titleView = [[MADNavigationBarTitleView alloc] initWithFrame:CGRectZero];
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
    NSNumber *labelDynamic = [NSNumber numberWithShort:MTDocumentObjectTypeLabelDynamic];
    NSNumber *labelStatic = [NSNumber numberWithShort:MTDocumentObjectTypeLabelStatic];
    NSNumber *aggregate = [NSNumber numberWithShort:MTDocumentObjectTypeAggregate];
    NSNumber *image = [NSNumber numberWithShort:MTDocumentObjectTypeImage];
    NSNumber *whitespace = [NSNumber numberWithShort:MTDocumentObjectTypeWhtiespace];
    NSArray *defaults = @[labelDynamic, labelStatic, aggregate, image, whitespace];
    [dataSource addObjectsFromArray:defaults];
    
    if ([[MTStoreKitController sharedObject] isBarcodeDesignerEnabled]) {
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

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *MADIdentiferDocumentObjectCell = @"MADIdentiferDocumentObjectCell";
    
    MADDocumentObjectCollectionViewCell *result;
    result = [collectionView dequeueReusableCellWithReuseIdentifier: MADIdentiferDocumentObjectCell
                                                       forIndexPath: indexPath];
    NSNumber * __unsafe_unretained madob = self.dataSource[(NSUInteger)indexPath.row];
    result.type = madob.shortValue;
    
    if (result.selectedBackgroundView == nil) {
    
        UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:result.frame];
        UIColor *bgColor = [UIColor colorWithWhite:0.30000f alpha:0.30000f];
        selectedBackgroundView.backgroundColor = bgColor;
        result.selectedBackgroundView = selectedBackgroundView;
        
    }
    result.contentView.tag = madob.shortValue;
    return result;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
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

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
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
    if ([self aggregateViewController]) {
        NSString *functionName = [RptqDocumentObjectAggregate newStringDisplayForType:functionType];
        NSString *detailText = [NSString stringWithFormat:@"%@(x)", functionName];
        [[[[self aggregateViewController] tableViewCellAggrageFunction] detailTextLabel] setText:detailText];
    }
}


- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [[[viewController navigationController] navigationBar] setHidden:YES];
}

#pragma mark
#pragma mark - UITableViewControllerChooseFieldDelegate

- (void)tableViewControllerChooseFieldDidFinish:(MTQueryBuilderChooseFieldViewController *)controller withField:(RptqQueryField *)field {
    
    switch ([[controller view] tag]) {
            
        case MTDocumentObjectTypeLabelDynamic:
            
            //[self performSegueWithIdentifier:@"MTIdentifierSeguePushSelectField" sender:<#(id)#>];
            //[[self objectSelectorDelegate] viewControllerDidFinish:self];
            
            break;
            
        case MTViewTagFieldOrFormulaSelector: {
            
            NSString *formatString = NSLocalizedString(@"Field: %@", @"Field: %@");
            NSString *detailtext = [NSString stringWithFormat:formatString, [field display]];
            [[[[self aggregateViewController] tableViewCellAggregateInput] detailTextLabel] setText:detailtext];
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
    [self setAggregateGroupByType: MTAggregateGroupByTypePage];
    self.aggregateGroupBySectionNumber = 0;
    [self displaySelectedGroupByType];
    [self.navigationBar popNavigationItemAnimated:YES];
}

- (void)didSelectGroupByReport {
    [self setAggregateGroupByType: MTAggregateGroupByTypeReport];
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
    if ([self aggregateViewController]) {
        switch ([self aggregateGroupByType]) {
            case MTAggregateGroupByTypeSection: {

                NSUInteger group = self.aggregateGroupBySectionNumber;
                NSString *format = [RptqDocumentObjectAggregate newStringDisplayForGroupByType: MTAggregateGroupByTypeSection];
                NSString *detail = [NSString stringWithFormat:format, group];
                [[[[self aggregateViewController] tableViewCellAggregateGroupBy] detailTextLabel] setText:detail];
                break;
                
            }
            case MTAggregateGroupByTypeReport: {

                NSString *detailText = [RptqDocumentObjectAggregate newStringDisplayForGroupByType: MTAggregateGroupByTypeReport];
                [[[[self aggregateViewController] tableViewCellAggregateGroupBy] detailTextLabel] setText:detailText];
                break;
                
            }
            case MTAggregateGroupByTypePage: {

                NSString *detailText = [RptqDocumentObjectAggregate newStringDisplayForGroupByType: MTAggregateGroupByTypePage];
                [[[[self aggregateViewController] tableViewCellAggregateGroupBy] detailTextLabel] setText:detailText];
                break;
                
            }
            default:
                [[[[self aggregateViewController] tableViewCellAggregateGroupBy] detailTextLabel] setText:@""];
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

    switch ([tableView tag]) {
        case MTViewTagFieldOrFormulaSelector:

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
        case MTViewTagAggregateFunctions:
            break;
        case MTViewTagDocumentObjectNewAggregate: {
            
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
        case MTViewTagDocumentObjectNewLabelStatic:
            break;
        case MTViewTagGroupByOptions:
            break;
        default:
            break;
    }
}

#pragma mark - Accessibility

- (BOOL)accessibilityPerformEscape {
    [self.objectSelectorDelegate viewControllerDidFinish: self];
    return self.objectSelectorDelegate != nil;
}

@end
