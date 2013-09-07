//
//  UIViewControllerObjectSelector.m
//  Reports
//
//  Created by Michael Thomason on 1/15/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTReportDesignerObjectSelectorViewController.h"

NSString * const MTIdentiferDocumentObjectLabelCollectionViewCell = @"MTIdentiferDocumentObjectLabelCollectionViewCell";
NSString * const MTIdentiferDocumentObjectFormulaCollectionViewCell = @"MTIdentiferDocumentObjectFormulaCollectionViewCell";
NSString * const MTIdentiferDocumentObjectChartCollectionViewCell = @"MTIdentiferDocumentObjectChartCollectionViewCell";
NSString * const MTIdentiferDocumentObjectAggregateCollectionViewCell = @"MTIdentiferDocumentObjectAggregateCollectionViewCell";
NSString * const MTIdentiferDocumentObjectDataCollectionViewCell = @"MTIdentiferDocumentObjectDataCollectionViewCell";
NSString * const MTIdentiferDocumentObjectImageCollectionViewCell = @"MTIdentiferDocumentObjectImageCollectionViewCell";
NSString * const MTIdentiferDocumentObjectGroupKeyCollectionViewCell = @"MTIdentiferDocumentObjectGroupKeyCollectionViewCell";
NSString * const MTIdentiferDocumentObjectWhitespaceCollectionViewCell = @"MTIdentiferDocumentObjectWhitespaceCollectionViewCell";

NSString * const MTFieldOrFormulaViewControllerIdentifier = @"MTFieldOrFormulaViewControllerIdentifier";

NSInteger const MTViewTagAggregateFunctions = 2003;
NSInteger const MTViewTagGroupByOptions = 2011;
NSInteger const MTViewTagDocumentObjectNewAggregate = 2017;
NSInteger const MTViewTagDocumentObjectNewLabelStatic = 2027;
NSInteger const MTViewTagFieldOrFormulaSelector = 2029;

@interface MTReportDesignerObjectSelectorViewController ()

@property (nonatomic, retain) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, retain) IBOutlet UINavigationItem *navigationItemMain;

//@property (nonatomic, retain) IBOutlet UICollectionViewController *documentObjectSelectorViewController;
@property (nonatomic, retain) IBOutlet UICollectionViewController *visibleViewController;
@property (nonatomic, retain) UIViewController *childViewController;
@property (nonatomic, retain) UIViewController *viewControllerToPush;
@property (nonatomic, retain) IBOutlet UIView *containerView;
@property (nonatomic, retain) UIView *childDisplayedView;

@property (nonatomic, retain) MTAggregateFunctionsViewController *aggregateFunctionsViewController;
@property (nonatomic, assign) BOOL showAggregateFunctionsViewController;

@property (nonatomic, retain) MTDocumentObjectNewAggregateViewController *aggregateViewController;
@property (nonatomic, assign) BOOL showNewAggregateViewController;

@property (nonatomic, retain) MTGroupByViewController *groupByViewController;
@property (nonatomic, assign) BOOL showGroupByViewController;

@property (nonatomic, retain) UITableViewController *fieldOrFormulaViewController;
@property (nonatomic, assign) BOOL showFieldOrFormulaViewController;

@property (nonatomic, retain) MTQueryBuilderChooseFieldViewController *fieldOrFormulaFieldPickerViewController;
@property (nonatomic, assign) BOOL showFieldOrFormulaFieldPickerViewController;

@property (nonatomic, retain) UITableViewController *fieldOrFormulaFormulaPickerViewController;
@property (nonatomic, assign) BOOL showFieldOrFormulaFormulaPickerViewerController;

@property (atomic, assign) MTDocumentObjectType typeOfObjectToPush;
@property (atomic, assign) BOOL rootSelectorControllerIsVisable;

@property (atomic, assign) BOOL shouldDismissThis;

@property (nonatomic, retain) NSManagedObjectID *aggregateInputField;
@property (atomic, assign) BOOL fieldSelectionPopPartOneOfTwo;

@property (nonatomic, retain) NSManagedObjectID *aggregateInputFormula;
@property (nonatomic, assign) MTAggregateFunctionType aggregateFunctionType;
@property (nonatomic, assign) MTAggregateFunctionInputType  aggregateFunctionInputType;
@property (nonatomic, assign) MTAggregateGroupByType aggregateGroupByType;
@property (nonatomic, assign) NSUInteger aggregateGroupBySectionNumber;

@property (nonatomic, retain) UIImagePickerController *imagePicker;

@property (nonatomic, retain) UIBarButtonItem *saveButton;

- (IBAction)done:(id)sender;

@end

@implementation MTReportDesignerObjectSelectorViewController

- (void)dealloc {
    [_saveButton release];
    [_viewControllerToPush release];
    [_visibleViewController release];
    [_childDisplayedView release];
    [_containerView release];
    [_navigationBar release];
    [_navigationItemMain release];
    //[_documentObjectSelectorViewController release];
    [_childViewController release];
    [_groupByViewController release];
    [_fieldOrFormulaViewController release];
    [_aggregateFunctionsViewController release];
    [_fieldOrFormulaFieldPickerViewController release];
    [_fieldOrFormulaFormulaPickerViewController release];
    [_aggregateInputFormula release];
    [_aggregateInputField release];
    [_aggregateViewController release];
    [_aggregateInputField release];
    [_imagePicker release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

#pragma mark - View lifecycle

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"MTSegueNewDocumentObjectDynamicLabelIdentifer"]) {
        //id reportDesignerViewController = [self objectSelectorDelegate];
        //[[segue destinationViewController] setDelegate: reportDesignerViewController];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
}
    
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
    [[self objectSelectorDelegate] viewControllerDidFinish: self];
}

#pragma mark - UICollectionViewDataSource

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *result = nil;
    NSString *cellIdentifier = nil;
    NSUInteger tag = 0;
    switch ([indexPath section]) {
        case 0: {
            switch ([indexPath row]) {
                case 1: {
                    cellIdentifier = MTIdentiferDocumentObjectLabelCollectionViewCell;
                    tag = MTDocumentObjectTypeLabelStatic;
                    break;
                }
                case 5: {
                    cellIdentifier = MTIdentiferDocumentObjectGroupKeyCollectionViewCell;
                    tag = MTDocumentObjectTypeGroupKey;
                    break;
                }
                case 3: {
                    cellIdentifier = MTIdentiferDocumentObjectImageCollectionViewCell;
                    tag = MTDocumentObjectTypeImage;
                    break;
                }
                case 6: {
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
        [selectedBackgroundView setBackgroundColor:[UIColor colorWithWhite:0.30000f alpha:0.50000f]];
        [result setSelectedBackgroundView:selectedBackgroundView];
        [selectedBackgroundView release];
    }
    [[result contentView] setTag: tag];
    return result;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger result = 0;
    switch (section) {
        case 0:
            result = 5;
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

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
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

//- (void)pressedCancelButton:(id)sender {
//    [[self objectSelectorDelegate] viewControllerDidFinish: self];
//}

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

#pragma mark
#pragma mark - Aggregate Functions View Controller Delegate Protocol

- (void)didSelectFunction:(MTAggregateFunctionType)functionType {
    [self setAggregateFunctionType: functionType];

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
#pragma mark - Group By Functions View Controller Delegate Protocol

- (void)didSelectGroupByPage {
    [self setAggregateGroupByType: MTAggregateGroupByTypePage];
    [self setAggregateGroupBySectionNumber: 0];
    [self displaySelectedGroupByType];
    [[self navigationBar] popNavigationItemAnimated:YES];
}

- (void)didSelectGroupByReport {
    [self setAggregateGroupByType: MTAggregateGroupByTypeReport];
    [self setAggregateGroupBySectionNumber: 0];
    [self displaySelectedGroupByType];
    [[self navigationBar] popNavigationItemAnimated:YES];
}

- (void)didSelectGroupBySectionNumber:(NSUInteger)groupNumber {
    [self setAggregateGroupByType: MTAggregateGroupByTypeSection];
    [self setAggregateGroupBySectionNumber: groupNumber];
    [self displaySelectedGroupByType];
    [[self navigationBar] popNavigationItemAnimated:YES];
}

- (void)displaySelectedGroupByType {
    if ([self aggregateViewController]) {
        switch ([self aggregateGroupByType]) {
            case MTAggregateGroupByTypeSection: {

                NSUInteger group = [self aggregateGroupBySectionNumber];
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

            switch ([indexPath row]) {
                
                case 0: {   // Group by a Field
                    
                    NSString *navigationItemTitle = NSLocalizedString(@"Field Selector", @"Field Selector");
                    UINavigationItem *itemToPush = [[UINavigationItem alloc] initWithTitle: navigationItemTitle];
                    [self setShowFieldOrFormulaFieldPickerViewController:YES];
                    [[self navigationBar] pushNavigationItem:itemToPush animated:YES];
                    [itemToPush release];
                    break;

                }
                case 1: {   // Group by a Formula

                    NSString *navigationItemTitle = NSLocalizedString(@"Formula Selector", @"Formula Selector");
                    UINavigationItem *itemToPush = [[UINavigationItem alloc] initWithTitle: navigationItemTitle];
                    [self setShowFieldOrFormulaFormulaPickerViewerController:YES];
                    [[self navigationBar] pushNavigationItem:itemToPush animated:YES];
                    [itemToPush release];
                    break;

                }
                default:
                    break;
            }
            
            break;
        case MTViewTagAggregateFunctions:
            break;
        case MTViewTagDocumentObjectNewAggregate: {
            
            switch ([indexPath row]) {

                case 0: {   // Aggrage Function *f(x)*

                    NSString *navigationItemTitle = NSLocalizedString(@"Function Selector", @"Function Selector");
                    UINavigationItem *itemToPush = [[UINavigationItem alloc] initWithTitle: navigationItemTitle];
                    [self setShowAggregateFunctionsViewController:YES];
                    [[self navigationBar] pushNavigationItem:itemToPush animated:YES];
                    [itemToPush release];
                    break;
                    
                }
                case 1: {   // Input *x*
                    
                    NSString *navigationItemTitle = NSLocalizedString(@"Data Object Selector", @"Data Object Selector");
                    UINavigationItem *itemToPush = [[UINavigationItem alloc] initWithTitle: navigationItemTitle];
                    [self setShowFieldOrFormulaViewController:YES];
                    [[self navigationBar] pushNavigationItem:itemToPush animated:YES];
                    [itemToPush release];
                    
                    break;
                }
                case 2: {   //Group By *For Each*
                    NSString *navigationItemTitle = NSLocalizedString(@"Group By Selector", @"Group By Selector");
                    UINavigationItem *itemToPush = [[UINavigationItem alloc] initWithTitle: navigationItemTitle];
                    [self setShowGroupByViewController:YES];
                    [[self navigationBar] pushNavigationItem:itemToPush animated:YES];
                    [itemToPush release];
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