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

#import "MADDesignerElementPIckerViewController.h"
#import <CoreData/CoreData.h>

#import "MTAggregateFunctionsViewController.h"

#import "UIDevice+Hack.h"

#import "MTQueryBuilderChooseFieldDelegate.h"
#import "MTQueryBuilderChooseFieldViewController.h"
#import "MTDocumentObjectNewAggregateViewController.h"
#import "MTDocumentObjectNewStaticLabelViewController.h"
#import "MTGroupByViewController.h"

#import "RptqDocumentObjectAggregate.h"
#import "RptqDocumentObjectAggregate+Extras.h"

#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"

#import "UIColor+EverydayApps.h"
#import "MADDocumentObjectType.h"

NSString * const MTIdentiferDocumentObjectLabelCollectionViewCell = @"MTIdentiferDocumentObjectLabelCollectionViewCell";
NSString * const MTIdentiferDocumentObjectFormulaCollectionViewCell = @"MTIdentiferDocumentObjectFormulaCollectionViewCell";
NSString * const MTIdentiferDocumentObjectChartCollectionViewCell = @"MTIdentiferDocumentObjectChartCollectionViewCell";
NSString * const MTIdentiferDocumentObjectAggregateCollectionViewCell = @"MTIdentiferDocumentObjectAggregateCollectionViewCell";
NSString * const MTIdentiferDocumentObjectDataCollectionViewCell = @"MTIdentiferDocumentObjectDataCollectionViewCell";
NSString * const MTIdentiferDocumentObjectImageCollectionViewCell = @"MTIdentiferDocumentObjectImageCollectionViewCell";
NSString * const MTIdentiferDocumentObjectGroupKeyCollectionViewCell = @"MTIdentiferDocumentObjectGroupKeyCollectionViewCell";
NSString * const MTIdentiferDocumentObjectWhitespaceCollectionViewCell = @"MTIdentiferDocumentObjectWhitespaceCollectionViewCell";
NSString * const MTIdentiferDocumentObjectBarcodeCollectionViewCell = @"MTIdentiferDocumentObjectBarcodeCollectionViewCell";

NSInteger const MTViewTagAggregateFunctions = 2003;
NSInteger const MTViewTagGroupByOptions = 2011;
NSInteger const MTViewTagDocumentObjectNewAggregate = 2017;
NSInteger const MTViewTagDocumentObjectNewLabelStatic = 2027;
NSInteger const MTViewTagFieldOrFormulaSelector = 2029;

@interface MADDesignerElementPIckerViewController ()
    <MTQueryBuilderChooseFieldDelegate,
        MTAggregateFunctionsViewControllerDelegate,
        MTGroupByViewControllerDelegate,
        UINavigationControllerDelegate,
        UICollectionViewDataSource,
        UICollectionViewDelegateFlowLayout>

@property (nonatomic, weak) IBOutlet UINavigationBar *navigationBar;

@property (nonatomic, strong) MTAggregateFunctionsViewController *aggregateFunctionsViewController;

@property (nonatomic, strong) MTDocumentObjectNewAggregateViewController *aggregateViewController;

@property (nonatomic, strong) MTGroupByViewController *groupByViewController;

@property (nonatomic, strong) UITableViewController *fieldOrFormulaViewController;

@property (nonatomic, strong) MTQueryBuilderChooseFieldViewController *fieldOrFormulaFieldPickerViewController;

@property (nonatomic, strong) UITableViewController *fieldOrFormulaFormulaPickerViewController;
@property (nonatomic, assign) BOOL showFieldOrFormulaFormulaPickerViewerController;

@property (nonatomic, assign) MTAggregateGroupByType aggregateGroupByType;
@property (nonatomic, assign) NSUInteger aggregateGroupBySectionNumber;

- (IBAction)done:(id)sender;

@end

@implementation MADDesignerElementPIckerViewController

#pragma mark - Exit

- (BOOL)canPerformUnwindSegueAction:(SEL)action
                 fromViewController:(UIViewController *)fromViewController
                         withSender:(id)sender {
    return NO;
}

- (UIViewController *)viewControllerForUnwindSegueAction:(SEL)action
                                      fromViewController:(UIViewController *)fromViewController
                                              withSender:(id)sender {
    
    return action == @selector(unwindToDesigner:) ?
            (UIViewController *)self.objectSelectorDelegate :
            [super viewControllerForUnwindSegueAction: action
                                   fromViewController: fromViewController
                                           withSender: sender];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([UIDevice isModernOS]) {
        UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        UIVisualEffectView *visualEffectsView = [[UIVisualEffectView alloc] initWithEffect:effect];
        [self.view addSubview: visualEffectsView];
        self.navigationController.view.backgroundColor = [UIColor clearColor];
        self.navigationController.view.opaque = NO;
        self.collectionView.backgroundColor = [UIColor clearColor];
        self.collectionView.opaque = NO;
        self.view.backgroundColor = [UIColor clearColor];
        self.view.opaque = NO;
    }
    if ([UIDevice isPad]) {
        self.preferredContentSize = CGSizeMake(320.0000f, 420.0000f);
    };
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

#pragma mark - View lifecycle

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"MTIdentifierSeguePushSelectField"]) {
        
        ((MTQueryBuilderChooseFieldViewController *)segue.destinationViewController).delegate =  self;
        [(id <MTUnwindProtocol>)segue.destinationViewController setUnwindViewController:(UIViewController *)self.objectSelectorDelegate];
        
    } else if ([segue.identifier isEqualToString:@"MTIdentifierSeguePushStaticLabelNew"]) {

        [(id <MTUnwindProtocol>)segue.destinationViewController setUnwindViewController:(UIViewController *)self.objectSelectorDelegate];
        
    } else if ([segue.identifier isEqualToString:@"MTIdentifierSeguePushAggregateLabelNew"]) {
        
        [(id <MTUnwindProtocol>)segue.destinationViewController setUnwindViewController:(UIViewController *)self.objectSelectorDelegate];
        
    } else if ([segue.identifier isEqualToString:@"MTIdentifierSeguePushBarcodeLabelNew"]) {
        
        [(id <MTUnwindProtocol>)segue.destinationViewController setUnwindViewController:(UIViewController *)self.objectSelectorDelegate];
        
    }
    if ([segue.destinationViewController respondsToSelector:@selector(setDocument:)]) {
        [segue.destinationViewController setDocument:self.document];
    }
}

- (void)performSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    [super performSegueWithIdentifier:identifier sender:sender];
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
    [self.objectSelectorDelegate viewControllerDidFinish: self];
}

#pragma mark - UICollectionViewDataSource

- (void)collectionView:(UICollectionView *)collectionView
        didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];

    switch (cell.tag) {

        case MTDocumentObjectTypeImage: {
            UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
            imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            imagePicker.delegate = (id <UINavigationControllerDelegate ,UIImagePickerControllerDelegate>)self.objectSelectorDelegate;
            imagePicker.navigationBar.barTintColor = [UIColor tintColorAnalogous4];
            
            [self presentViewController:imagePicker animated:YES completion:NULL];
            break;
        }
            
        default:
            break;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *result = nil;
    NSString *cellIdentifier = nil;
    NSUInteger tag = 0;
    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 1: {
                    cellIdentifier = MTIdentiferDocumentObjectLabelCollectionViewCell;
                    tag = MTDocumentObjectTypeLabelStatic;
                    break;
                }
                case 6: {
                    cellIdentifier = MTIdentiferDocumentObjectGroupKeyCollectionViewCell;
                    tag = MTDocumentObjectTypeGroupKey;
                    break;
                }
                case 3: {
                    cellIdentifier = MTIdentiferDocumentObjectImageCollectionViewCell;
                    tag = MTDocumentObjectTypeImage;
                    break;
                }
                case 7: {
                    cellIdentifier = MTIdentiferDocumentObjectChartCollectionViewCell;
                    tag = MTDocumentObjectTypeChart;
                    break;
                }
                case 2: {
                    cellIdentifier = MTIdentiferDocumentObjectAggregateCollectionViewCell;
                    tag = MTDocumentObjectTypeAggregate;
                    break;
                }
                case 0: {
                    cellIdentifier = MTIdentiferDocumentObjectDataCollectionViewCell;
                    tag = MTDocumentObjectTypeLabelDynamic;
                    break;
                }
                case 9: {
                    cellIdentifier = MTIdentiferDocumentObjectFormulaCollectionViewCell;
                    tag = MTDocumentObjectTypeFormula;
                    break;
                }
                case 4: {
                    cellIdentifier = MTIdentiferDocumentObjectWhitespaceCollectionViewCell;
                    tag = MTDocumentObjectTypeWhtiespace;
                    break;
                }
                case 5: {
                    cellIdentifier = MTIdentiferDocumentObjectBarcodeCollectionViewCell;
                    tag = MTDocumentObjectTypeBarcode;
                    break;
                }
                default: {
                    break;
                }
            }
            break;
        }
        default: {
            break;
        }
    }

    result = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    if ([result selectedBackgroundView] == nil) {
        UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:result.frame];
        UIColor *bgColor = [UIColor colorWithWhite:0.30000f alpha:0.30000f];
        selectedBackgroundView.backgroundColor = bgColor;
        [result setSelectedBackgroundView:selectedBackgroundView];
    }
    [[result contentView] setTag: tag];
    return result;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger result = 0;
    switch (section) {
        case 0:
            result = 6;
            break;
        default:
            break;
    }
    return result;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

#pragma mark - UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    return NO;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (IBAction)saveDocumentObjectAggregate:(id)sender {
    
}

- (IBAction)saveDocumentObjectImage:(id)sender {
    
}

- (IBAction)saveDocumentObjectLabelDynamic:(id)sender {
    
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
    
    [[self navigationBar] popNavigationItemAnimated:YES];
}

- (void)displaySelectedFunction:(MTAggregateFunctionType)functionType {
    if ([self aggregateViewController]) {
        NSString *functionName = [RptqDocumentObjectAggregate displayStringForType:functionType];
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
            [[self navigationBar] popNavigationItemAnimated:YES];
            
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
    [[self navigationBar] popNavigationItemAnimated:YES];
}

- (void)didSelectGroupByReport {
    [self setAggregateGroupByType: MTAggregateGroupByTypeReport];
    self.aggregateGroupBySectionNumber = 0;
    [self displaySelectedGroupByType];
    [[self navigationBar] popNavigationItemAnimated:YES];
}

- (void)didSelectGroupBySectionNumber:(NSUInteger)groupNumber {
    self.aggregateGroupByType = MTAggregateGroupByTypeSection;
    self.aggregateGroupBySectionNumber = groupNumber;
    [self displaySelectedGroupByType];
    [[self navigationBar] popNavigationItemAnimated:YES];
}

- (void)displaySelectedGroupByType {
    if ([self aggregateViewController]) {
        switch ([self aggregateGroupByType]) {
            case MTAggregateGroupByTypeSection: {

                NSUInteger group = self.aggregateGroupBySectionNumber;
                NSString *format = [RptqDocumentObjectAggregate displayStringForGroupByType: MTAggregateGroupByTypeSection];
                NSString *detail = [NSString stringWithFormat:format, group];
                [[[[self aggregateViewController] tableViewCellAggregateGroupBy] detailTextLabel] setText:detail];
                break;
                
            }
            case MTAggregateGroupByTypeReport: {

                NSString *detailText = [RptqDocumentObjectAggregate displayStringForGroupByType: MTAggregateGroupByTypeReport];
                [[[[self aggregateViewController] tableViewCellAggregateGroupBy] detailTextLabel] setText:detailText];
                break;
                
            }
            case MTAggregateGroupByTypePage: {

                NSString *detailText = [RptqDocumentObjectAggregate displayStringForGroupByType: MTAggregateGroupByTypePage];
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
                    [[self navigationBar] pushNavigationItem:itemToPush animated:YES];
                    break;

                }
                case 1: {   // Group by a Formula

                    NSString *navigationItemTitle = NSLocalizedString(@"Formula Selector", @"Formula Selector");
                    UINavigationItem *itemToPush = [[UINavigationItem alloc] initWithTitle: navigationItemTitle];
                    [self setShowFieldOrFormulaFormulaPickerViewerController:YES];
                    [[self navigationBar] pushNavigationItem:itemToPush animated:YES];
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
                    [[self navigationBar] pushNavigationItem:itemToPush animated:YES];
                    break;
                    
                }
                case 1: {   // Input *x*
                    
                    NSString *navigationItemTitle = NSLocalizedString(@"Data Object Selector", @"Data Object Selector");
                    UINavigationItem *itemToPush = [[UINavigationItem alloc] initWithTitle: navigationItemTitle];
                    [[self navigationBar] pushNavigationItem:itemToPush animated:YES];
                    break;
                }
                case 2: {   //Group By *For Each*
                    NSString *navigationItemTitle = NSLocalizedString(@"Group By Selector", @"Group By Selector");
                    UINavigationItem *itemToPush = [[UINavigationItem alloc] initWithTitle: navigationItemTitle];
                    [[self navigationBar] pushNavigationItem:itemToPush animated:YES];
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

@end
