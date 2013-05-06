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

NSString * const MTFieldOrFormulaViewControllerIdentifier = @"MTFieldOrFormulaViewControllerIdentifier";

NSInteger const MTViewTagAggregateFunctions = 2003;
NSInteger const MTViewTagGroupByOptions = 2011;
NSInteger const MTViewTagDocumentObjectNewAggregate = 2017;
NSInteger const MTViewTagDocumentObjectNewLabelStatic = 2027;
NSInteger const MTViewTagFieldOrFormulaSelector = 2029;

@interface MTReportDesignerObjectSelectorViewController ()

@property (nonatomic, retain) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, retain) IBOutlet UINavigationItem *navigationItemMain;

@property (nonatomic, retain) UICollectionViewController *documentObjectSelectorViewController;
@property (nonatomic, retain) UIViewController *visibleViewController;
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
@property (atomic, assign) BOOL pressedSaveButton;

@property (nonatomic, retain) NSManagedObjectID *aggregateInputField;
@property (atomic, assign) BOOL fieldSelectionPopPartOneOfTwo;

@property (nonatomic, retain) NSManagedObjectID *aggregateInputFormula;
@property (nonatomic, assign) MTAggregateFunctionType aggregateFunctionType;
@property (nonatomic, assign) MTAggregateFunctionInputType  aggregateFunctionInputType;
@property (nonatomic, assign) MTGroupByType aggregateGroupByType;
@property (nonatomic, assign) NSUInteger aggregateGroupBySectionNumber;

@property (nonatomic, retain) UIImagePickerController *imagePicker;

@property (nonatomic, retain) UIBarButtonItem *saveButton;

- (BOOL)childViewControllerIsVisable;
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
    [_documentObjectSelectorViewController release];
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

- (void)viewDidLoad {
    [super viewDidLoad];

    // MARK: Add collection view contorller.
    [[self navigationItemMain] setTitle:NSLocalizedString(@"Add a Document Object", @"Add a Document Object")];
    [[self navigationItemMain] setPrompt:NSLocalizedString(@"Choose the type of object you would like to add to the report.", @"Prompt to choose an object.")];
    UIStoryboard *storyboard = [[UIStoryboard storyboardWithName:[AppDelegate storyboardName] bundle:nil] retain];
    UICollectionViewController *documentObjectSelectorViewController = [[storyboard instantiateViewControllerWithIdentifier:@"MTDocumentObjectSelectorViewControllerIdentifier"] retain];
    [[documentObjectSelectorViewController collectionView] setDelegate:self];
    [[documentObjectSelectorViewController collectionView] setDataSource:self];
    [self setVisibleViewController: documentObjectSelectorViewController];
    [documentObjectSelectorViewController release];
    [storyboard release];
    [[[self visibleViewController] view] setFrame:[[self containerView] bounds]];
    if ([self visibleViewController]) {
        [[self containerView] addSubview:[[self visibleViewController] view]];
    }
    
    [[self navigationBar] setDelegate:self];
    
    UIViewController *childViewController = [[UIViewController alloc] init];
    [[childViewController view] setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [self setChildViewController:childViewController];
    [childViewController release];
    [self setShouldDismissThis:NO];
    [self setRootSelectorControllerIsVisable:YES];
    [self setShowGroupByViewController:NO];
    [self setShowAggregateFunctionsViewController:NO];
    [self setShowFieldOrFormulaViewController:NO];
    [self setShowFieldOrFormulaFieldPickerViewController:NO];
    [self setShowFieldOrFormulaFormulaPickerViewerController:NO];

    [self setAggregateFunctionType:MTAggregateFunctionTypeSum];
    [self displaySelectedFunction:[self aggregateFunctionType]];
    
    [self setAggregateFunctionInputType:MTAggregateFunctionInputTypeField];
    [self setAggregateInputField:nil];
    [self setFieldSelectionPopPartOneOfTwo:NO];
    //[self displaySelectedFunctionInputType:[self aggregateFunctionInputType]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    CGRect rect = CGRectMake(CGPointZero.x,
                             CGPointZero.y + [[self navigationBar] frame].size.height,
                             [[self view] frame].size.width,
                             [[self view] frame].size.height - [[self navigationBar] frame].size.height);
    [[[self childViewController] view] setFrame: rect];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
    [[self objectSelectorDelegate] viewControllerDidFinish: self];
}

- (BOOL)childViewControllerIsVisable {
    return ![self rootSelectorControllerIsVisable];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *selectedImage = [info objectForKey:UIImagePickerControllerEditedImage];

    if (selectedImage == nil) {
        selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    if (selectedImage) {
        [selectedImage retain];
        [[self objectSelectorDelegate] insertDocumentObjectNewImage:selectedImage];
        [selectedImage release];
    }

    [[self objectSelectorDelegate] viewControllerDidFinish:self];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker { }

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
                    cellIdentifier = MTIdentiferDocumentObjectFormulaCollectionViewCell;
                    tag = MTDocumentObjectTypeFormula;
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
                case 4: {
                    cellIdentifier = MTIdentiferDocumentObjectGroupKeyCollectionViewCell;
                    tag = MTDocumentObjectTypeGroupKey;
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
            result = 4;
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

    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    UIBarButtonItem *rightBarButtonItem = nil;

    NSString *navigationItemTitle = nil;
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    MTDocumentObjectType objectType = [[cell contentView] tag];
    [self setTypeOfObjectToPush: objectType];

    switch ([indexPath section]) {

        case 0: {
        
            switch (objectType) {

                case MTDocumentObjectTypeLabelStatic:
                    navigationItemTitle = NSLocalizedString(@"Label", @"Label");
                    rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemSave
                                                                                                target: self
                                                                                                action: @selector(pressedSaveButton:)];
                    [rightBarButtonItem setEnabled:NO];
                    break;
                
                case MTDocumentObjectTypeLabelDynamic:
                    navigationItemTitle = NSLocalizedString(@"Data", @"Data");
                    rightBarButtonItem = nil;
                    break;
                
                case MTDocumentObjectTypeChart:
                    navigationItemTitle = NSLocalizedString(@"Chart", @"Chart");
                    [[self objectSelectorDelegate] insertDocumentObjectNewChart];
                    rightBarButtonItem = nil;
                    break;
                
                case MTDocumentObjectTypeImage:
                    navigationItemTitle = NSLocalizedString(@"Image", @"Image");
                    rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
                                                                                       target: self
                                                                                       action: @selector(pressedCancelButton:)];
                    [rightBarButtonItem setEnabled:NO];
                    break;
                
                case MTDocumentObjectTypeAggregate:
                    navigationItemTitle = NSLocalizedString(@"Aggregate", @"Aggregate");
                    rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemSave
                                                                                       target: self
                                                                                       action: @selector(pressedSaveButton:)];
                    [rightBarButtonItem setEnabled:NO];
                    break;
                
                case MTDocumentObjectTypeGroupKey:
                    navigationItemTitle = NSLocalizedString(@"Group Key", @"Group Key");
                    rightBarButtonItem = nil;
                    break;
                    
                default:
                    break;
            }
            break;
        }
        default: {
            break;
        }
    }

    UINavigationItem *itemToPush = [[UINavigationItem alloc] initWithTitle: navigationItemTitle];
    [itemToPush setRightBarButtonItem: rightBarButtonItem];

    [self setSaveButton:rightBarButtonItem];
    [rightBarButtonItem release];
    
    
    [[self navigationBar] pushNavigationItem:itemToPush animated:YES];
    
    [itemToPush release];
    
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

- (void)pressedCancelButton:(id)sender {
    [[self objectSelectorDelegate] viewControllerDidFinish: self];
}

- (void)pressedSaveButton:(id)sender {
    
    switch ([self typeOfObjectToPush]) {
        case MTDocumentObjectTypeAggregate: {
            
            NSManagedObjectID *aggregateDataObjectID = nil;

            if ([self aggregateFunctionInputType] == MTAggregateFunctionInputTypeField) {
                aggregateDataObjectID = [self aggregateInputField];
            } else if ([self aggregateFunctionInputType] == MTAggregateFunctionInputTypeFormula) {
                aggregateDataObjectID = [self aggregateInputFormula];
            }

            [[self objectSelectorDelegate] insertDocumentObjectNewAggregateFunctionWithType: [self aggregateFunctionType]
                                                                                  inputType: [self aggregateFunctionInputType]
                                                                                inputObject: aggregateDataObjectID
                                                                                  groupType: [self aggregateGroupByType]
                                                                                groupNumber: @([self aggregateGroupBySectionNumber])];
            [[self objectSelectorDelegate] viewControllerDidFinish:self];

            break;
        }
        case MTDocumentObjectTypeLabelStatic: {
            
            MTDocumentObjectNewStaticLabelViewController *childViewController = [(MTDocumentObjectNewStaticLabelViewController *)[self viewControllerToPush] retain];
            NSString *userInputtedText = [childViewController userInputedText];
            [[self objectSelectorDelegate] insertDocumentObjectNewLabel:userInputtedText];
            [childViewController release];
            
            [[self objectSelectorDelegate] viewControllerDidFinish:self];
            
            break;
        }
        case MTDocumentObjectTypeImage: {
            break;
        }
        case MTDocumentObjectTypeLabelDynamic: {

            break;
        }
        case MTDocumentObjectTypeChart:
            break;
        case MTDocumentObjectTypeFormula:
            break;
        case MTDocumentObjectTypeGroupKey:
            break;
        default:
            break;
    }
}

#pragma mark - UICollectionViewFlowLayoutDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(150.0000f, 100.0000f);
}

#pragma mark - UINavigationBarDelegate

- (void)navigationBar:(UINavigationBar *)navigationBar didPopItem:(UINavigationItem *)item {
    
    if ([self fieldSelectionPopPartOneOfTwo]) {

        dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        dispatch_async(queuePriorityBackground, ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self setFieldSelectionPopPartOneOfTwo:NO];
                [[self navigationBar] popNavigationItemAnimated:YES];
                
            });
        });
        
    }

    if ([self shouldDismissThis]) {
        [self setShouldDismissThis: NO];
        [[self objectSelectorDelegate] viewControllerDidFinish:self];
    }
    [self setShouldDismissThis: NO];
}

- (void)navigationBar:(UINavigationBar *)navigationBar didPushItem:(UINavigationItem *)item {

}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {
    
    BOOL popIt = YES;
    
    if ([self showAggregateFunctionsViewController]) {
        
        CGRect offScreen = CGRectMake([[[self aggregateFunctionsViewController] view] frame].origin.x + [[[self aggregateFunctionsViewController] view] frame].size.width,
                                      [[[self aggregateFunctionsViewController] view] frame].origin.y,
                                      [[[self aggregateFunctionsViewController] view] frame].size.width,
                                      [[[self aggregateFunctionsViewController] view] frame].size.height);
        
        [UIView animateWithDuration:0.3000f animations:^{
            [[[self aggregateFunctionsViewController] view] setFrame: offScreen];
        } completion:^(BOOL finished) {
            [[[self aggregateFunctionsViewController] view] removeFromSuperview];
            [self setAggregateFunctionsViewController: nil];
        }];
        
        [self setShowAggregateFunctionsViewController:NO];

    } else if ([self showGroupByViewController]) {
        
        CGRect offScreen = CGRectMake([[[self groupByViewController] view] frame].origin.x + [[[self groupByViewController] view] frame].size.width,
                                      [[[self groupByViewController] view] frame].origin.y,
                                      [[[self groupByViewController] view] frame].size.width,
                                      [[[self groupByViewController] view] frame].size.height);
        
        [UIView animateWithDuration:0.3000f animations:^{
            [[[self groupByViewController] view] setFrame: offScreen];
        } completion:^(BOOL finished) {
            [[[self groupByViewController] view] removeFromSuperview];
            [self setGroupByViewController: nil];
        }];
        
        [self setShowGroupByViewController:NO];
        
    } else if ([self showFieldOrFormulaViewController]) {
        
        if ([self showFieldOrFormulaFieldPickerViewController] == NO &&
            [self showFieldOrFormulaFormulaPickerViewerController] == NO) {
            
            CGRect offScreen = CGRectMake([[[self fieldOrFormulaViewController] view] frame].origin.x + [[[self fieldOrFormulaViewController] view] frame].size.width,
                                          [[[self fieldOrFormulaViewController] view] frame].origin.y,
                                          [[[self fieldOrFormulaViewController] view] frame].size.width,
                                          [[[self fieldOrFormulaViewController] view] frame].size.height);
            
            [UIView animateWithDuration:0.3000f animations:^{
                [[[self fieldOrFormulaViewController] view] setFrame: offScreen];
            } completion:^(BOOL finished) {
                [[[self fieldOrFormulaViewController] view] removeFromSuperview];
                [self setFieldOrFormulaViewController: nil];
            }];
            
            [self setShowFieldOrFormulaViewController:NO];
            
        } else if ([self showFieldOrFormulaFieldPickerViewController] &&
                   [self showFieldOrFormulaFormulaPickerViewerController] == NO) {

            CGRect offScreen = CGRectMake([[[self fieldOrFormulaFieldPickerViewController] view] frame].origin.x + [[[self fieldOrFormulaFieldPickerViewController] view] frame].size.width,
                                          [[[self fieldOrFormulaFieldPickerViewController] view] frame].origin.y,
                                          [[[self fieldOrFormulaFieldPickerViewController] view] frame].size.width,
                                          [[[self fieldOrFormulaFieldPickerViewController] view] frame].size.height);
            
            [UIView animateWithDuration:0.3000f animations:^{
                [[[self fieldOrFormulaFieldPickerViewController] view] setFrame: offScreen];
            } completion:^(BOOL finished) {
                [[[self fieldOrFormulaFieldPickerViewController] view] removeFromSuperview];
                [self setFieldOrFormulaFieldPickerViewController: nil];
            }];
            
            [self setShowFieldOrFormulaFieldPickerViewController:NO];

        } else if ([self showFieldOrFormulaFormulaPickerViewerController] &&
                   [self showFieldOrFormulaFieldPickerViewController] == NO) {
            
            CGRect offScreen = CGRectMake([[[self fieldOrFormulaFormulaPickerViewController] view] frame].origin.x + [[[self fieldOrFormulaFormulaPickerViewController] view] frame].size.width,
                                          [[[self fieldOrFormulaFormulaPickerViewController] view] frame].origin.y,
                                          [[[self fieldOrFormulaFormulaPickerViewController] view] frame].size.width,
                                          [[[self fieldOrFormulaFormulaPickerViewController] view] frame].size.height);
            
            [UIView animateWithDuration:0.3000f animations:^{
                [[[self fieldOrFormulaFormulaPickerViewController] view] setFrame: offScreen];
            } completion:^(BOOL finished) {
                [[[self fieldOrFormulaFormulaPickerViewController] view] removeFromSuperview];
                [self setFieldOrFormulaFormulaPickerViewController: nil];
            }];
            
            [self setShowFieldOrFormulaFormulaPickerViewerController:NO];

        } else if ([self showFieldOrFormulaFieldPickerViewController] &&
                   [self showFieldOrFormulaFormulaPickerViewerController]) {
            
            @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                           reason: [NSString stringWithFormat:@"Both view controllers can't be open at the same time: %@.", NSStringFromSelector(_cmd)]
                                         userInfo: nil];
        }
        
    } else if ([self rootSelectorControllerIsVisable] == NO) {

        [self setRootSelectorControllerIsVisable:YES];
        [[[self documentObjectSelectorViewController] collectionView] setAllowsSelection: YES];
        
        CGRect offScreen = CGRectMake([[[self childViewController] view] frame].origin.x + [[[self childViewController] view] frame].size.width,
                                      [[[self childViewController] view] frame].origin.y,
                                      [[[self childViewController] view] frame].size.width,
                                      [[[self childViewController] view] frame].size.height);
        [UIView animateWithDuration:0.3000f animations:^{
            [[[self childViewController] view] setFrame: offScreen];
        } completion:^(BOOL finished) {
            [[self childDisplayedView] removeFromSuperview];
            [[[self childViewController] view] removeFromSuperview];
            [[[self documentObjectSelectorViewController] collectionView] setAllowsSelection: YES];
        }];

        [self setShouldDismissThis:[self pressedSaveButton]];
        [self setPressedSaveButton:NO];
    }
    
    return popIt;
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPushItem:(UINavigationItem *)item {
    BOOL pushIt = [self rootSelectorControllerIsVisable];

    if (pushIt) {

        [self setRootSelectorControllerIsVisable:NO];
            
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:[AppDelegate storyboardName] bundle:nil];
        UIViewController *viewControllerToAdd = nil;
        
        switch ([self typeOfObjectToPush]) {

            case MTDocumentObjectTypeLabelDynamic: {
                [[self saveButton] setEnabled:YES];

                [item setPrompt: NSLocalizedString(@"Choose a data field to add to the report.", @"Prompt to choose a data field.")];
                [item setTitle:@"Label Data"];
                MTQueryBuilderChooseFieldViewController *queryBuilderChooseFieldViewController = [[storyboard instantiateViewControllerWithIdentifier:@"UITableViewControllerChooseField"] retain];
                [queryBuilderChooseFieldViewController setExcludeTables: [NSArray array]];
                [queryBuilderChooseFieldViewController setDelegate: self];
                [[queryBuilderChooseFieldViewController view] setTag:MTDocumentObjectTypeLabelDynamic];
                viewControllerToAdd = [queryBuilderChooseFieldViewController retain];
                [queryBuilderChooseFieldViewController release];
                break;

            }
            case MTDocumentObjectTypeImage: {
                [[self saveButton] setEnabled:YES];

                [item setPrompt: NSLocalizedString(@"Choose a data field to add to the report.", @"Prompt to choose a data field.")];
                [item setTitle:@"Image"];
                //viewControllerToAdd = [[self imagePicker] retain];
                
                if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypePhotoLibrary]) {
                    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
                    [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
                    [imagePicker setDelegate: self];
                    viewControllerToAdd = [imagePicker retain];
                    [imagePicker release];
                }
                break;

            }
            case MTDocumentObjectTypeGroupKey: {
                break;
            }
            case MTDocumentObjectTypeAggregate: {
                [[self saveButton] setEnabled:NO];
                MTDocumentObjectNewAggregateViewController *documentObjectNewAggregateViewController = [storyboard instantiateViewControllerWithIdentifier:MTDocumentObjectNewAggregateViewControllerIdentifier];
                [[documentObjectNewAggregateViewController tableView] setDelegate:self];
                [self setAggregateViewController:documentObjectNewAggregateViewController];
                viewControllerToAdd = [documentObjectNewAggregateViewController retain];
                break;

            }
            case MTDocumentObjectTypeChart: {
                break;
            }
            case MTDocumentObjectTypeFormula: {
                break;
            }
            case MTDocumentObjectTypeLabelStatic: {
                [[self saveButton] setEnabled:YES];
                [item setPrompt: NSLocalizedString(@"Choose a data field to add to the report.", @"Prompt to choose a data field.")];
                [item setTitle:@"Label Data"];
                MTDocumentObjectNewStaticLabelViewController *documentObjectNewStaticLabelViewController = [storyboard instantiateViewControllerWithIdentifier:MTDocumentObjectNewStaticLabelViewControllerIdentifier];
                viewControllerToAdd = [documentObjectNewStaticLabelViewController retain];
                break;
            }
            default: {
                [item setPrompt: @""];
                break;
            }
        }
        
        [[viewControllerToAdd view] setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [[viewControllerToAdd view] setFrame:CGRectMake(CGPointZero.x, CGPointZero.y, [[[self childViewController] view] frame].size.width, [[[self childViewController] view] frame].size.height)];
        [[[self childViewController] view] addSubview:[viewControllerToAdd view]];
        
        CGRect newRect = CGRectMake(CGPointZero.x,
                                    CGPointZero.y,
                                    [[[self childViewController] view] frame].size.width,
                                    [[[self childViewController] view] frame].size.height);
        CGRect newRectOffscreen = CGRectMake(CGPointZero.x + [[[self childViewController] view] bounds].size.width,
                                             [[[self childViewController] view] frame].origin.y,
                                             [[[self childViewController] view] frame].size.width,
                                             [[[self childViewController] view] frame].size.height);
        
        [[[self childViewController] view] setFrame:newRectOffscreen];
        [[[self visibleViewController] view] addSubview:[[self childViewController] view]];
        [[[self visibleViewController] view] bringSubviewToFront:[[self childViewController] view]];
        [UIView animateWithDuration:0.3000f animations:^{
            [[[self childViewController] view] setFrame:newRect];
            //NSLog(@"Child view controller frame: %@", NSStringFromCGRect([[self childViewController] view].frame));
        } completion:^(BOOL finished) {
            
        }];
        
        [self setChildDisplayedView:[viewControllerToAdd view]];
        [self setViewControllerToPush:viewControllerToAdd];
        
        [viewControllerToAdd release];
    
    } else {
        
        pushIt = YES;
        UIViewController *viewControllerToAdd = nil;

        if ([self showAggregateFunctionsViewController]) {

            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:[AppDelegate storyboardName] bundle:nil];
            MTAggregateFunctionsViewController *aggregateFunctionsViewController = [[storyboard instantiateViewControllerWithIdentifier:MTAggregateFunctionsViewControllerIdentifier] retain];
            [aggregateFunctionsViewController setDelegate: self];
            [aggregateFunctionsViewController setSelectedFunctionType:[self aggregateFunctionType]];
            viewControllerToAdd = [aggregateFunctionsViewController retain];
            [self setAggregateFunctionsViewController:aggregateFunctionsViewController];
            [aggregateFunctionsViewController release];
            
        } else if ([self showGroupByViewController]) {
            
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:[AppDelegate storyboardName] bundle:nil];
            MTGroupByViewController *groupByViewController = [[storyboard instantiateViewControllerWithIdentifier:MTGroupByViewControllerIdentifier] retain];
            [groupByViewController setDelegate:self];
            viewControllerToAdd = [groupByViewController retain];
            [self setGroupByViewController:groupByViewController];
            [groupByViewController release];
            
        } else if ([self showFieldOrFormulaViewController]) {

            if ([self showFieldOrFormulaFieldPickerViewController] == NO &&
                [self showFieldOrFormulaFormulaPickerViewerController] == NO) {

                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:[AppDelegate storyboardName] bundle:nil];
                UITableViewController *fieldOrFormulaViewController = [[storyboard instantiateViewControllerWithIdentifier:MTFieldOrFormulaViewControllerIdentifier] retain];
                [[fieldOrFormulaViewController tableView] setDelegate:self];
                viewControllerToAdd = [fieldOrFormulaViewController retain];
                [self setFieldOrFormulaViewController:fieldOrFormulaViewController];
                [fieldOrFormulaViewController release];

            } else if ([self showFieldOrFormulaFieldPickerViewController] &&
                       [self showFieldOrFormulaFormulaPickerViewerController] == NO) {
            
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:[AppDelegate storyboardName] bundle:nil];
                MTQueryBuilderChooseFieldViewController *queryBuilderChooseFieldViewController = [[storyboard instantiateViewControllerWithIdentifier:@"UITableViewControllerChooseField"] retain];
                [queryBuilderChooseFieldViewController setExcludeTables: [NSArray array]];
                [queryBuilderChooseFieldViewController setDelegate: self];
                [[queryBuilderChooseFieldViewController view] setTag:MTViewTagFieldOrFormulaSelector];
                viewControllerToAdd = [queryBuilderChooseFieldViewController retain];
                [self setFieldOrFormulaFieldPickerViewController:queryBuilderChooseFieldViewController];
                [queryBuilderChooseFieldViewController release];
                

            } else if ([self showFieldOrFormulaFormulaPickerViewerController] &&
                       [self showFieldOrFormulaFieldPickerViewController] == NO) {

#warning Implement me when you implement fomulas.
                @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                               reason: [NSString stringWithFormat:@"Not implemented: %@.", NSStringFromSelector(_cmd)]
                                             userInfo: nil];

                
            } else if ([self showFieldOrFormulaFieldPickerViewController] &&
                       [self showFieldOrFormulaFormulaPickerViewerController]) {
                
                @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                               reason: [NSString stringWithFormat:@"Both view controllers can't be open at the same time: %@.", NSStringFromSelector(_cmd)]
                                             userInfo: nil];

            }
            
        }
        
        CGRect newRect = CGRectMake([[self containerView] frame].origin.x, [[self containerView] frame].origin.y,
                                    [[self containerView] frame].size.width,
                                    [[self containerView] frame].size.height);
        CGRect newRectOffscreen = CGRectMake(CGPointZero.x + [[self containerView] bounds].size.width,
                                             [[self containerView] frame].origin.y,
                                             [[self containerView] frame].size.width,
                                             [[self containerView] frame].size.height);

        [[viewControllerToAdd view] setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [[viewControllerToAdd view] setFrame:newRectOffscreen];

        [[self view] addSubview:[viewControllerToAdd view]];
        
        [[viewControllerToAdd view] setFrame:newRectOffscreen];
        [UIView animateWithDuration:0.3000f animations:^{
            [[viewControllerToAdd view] setFrame:newRect];
        } completion:^(BOOL finished) {
            
        }];
        [viewControllerToAdd release];

    }
    
    return pushIt;
}

- (void)pushOnScreen:(UIViewController *)viewController {
    [[viewController view] setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [[viewController view] setFrame:CGRectMake(CGPointZero.x, CGPointZero.y, [[[self childViewController] view] frame].size.width, [[[self childViewController] view] frame].size.height)];
    [[[self childViewController] view] addSubview:[viewController view]];
    
    CGRect newRect = CGRectMake(CGPointZero.x,
                                CGPointZero.y,
                                [[[self childViewController] view] frame].size.width,
                                [[[self childViewController] view] frame].size.height);
    CGRect newRectOffscreen = CGRectMake(CGPointZero.x + [[[self childViewController] view] bounds].size.width,
                                         [[[self childViewController] view] frame].origin.y,
                                         [[[self childViewController] view] frame].size.width,
                                         [[[self childViewController] view] frame].size.height);
    
    [[[self childViewController] view] setFrame:newRectOffscreen];
    [[[self visibleViewController] view] addSubview:[[self childViewController] view]];
    [[[self visibleViewController] view] bringSubviewToFront:[[self childViewController] view]];
    [UIView animateWithDuration:0.3000f animations:^{
        [[[self childViewController] view] setFrame:newRect];
    } completion:^(BOOL finished) {
        
    }];
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
#pragma mark - UITableViewControllerChooseFieldDelegate

- (void)tableViewControllerChooseFieldDidFinish:(MTQueryBuilderChooseFieldViewController *)controller withField:(RptqDatabaseSchemaField *)field {
    
    switch ([[controller view] tag]) {
            
        case MTDocumentObjectTypeLabelDynamic:
            
            [[self objectSelectorDelegate] insertDocumentObjectDataField: field];
            [[self objectSelectorDelegate] viewControllerDidFinish:self];
            
            break;
            
        case MTViewTagFieldOrFormulaSelector: {
            
            [self setAggregateFunctionInputType: MTAggregateFunctionInputTypeField];
            NSManagedObjectID *objectId = [[field objectID] retain];
            [self setAggregateInputField: objectId];
            [objectId release];
            NSString *formatString = NSLocalizedString(@"Field: %@", @"Field: %@");
            NSString *detailtext = [NSString stringWithFormat:formatString, [field display]];
            [[[[self aggregateViewController] tableViewCellAggregateInput] detailTextLabel] setText:detailtext];
            [self setFieldSelectionPopPartOneOfTwo:YES];
            [[self navigationBar] popNavigationItemAnimated:YES];

            [[self saveButton] setEnabled:YES];
            
            break;
            
        }
        default:
            break;
            
    }
    
}

#pragma mark
#pragma mark - Group By Functions View Controller Delegate Protocol

- (void)didSelectGroupByPage {
    [self setAggregateGroupByType: MTGroupByTypePage];
    [self setAggregateGroupBySectionNumber: 0];
    [self displaySelectedGroupByType];
    [[self navigationBar] popNavigationItemAnimated:YES];
}

- (void)didSelectGroupByReport {
    [self setAggregateGroupByType: MTGroupByTypeReport];
    [self setAggregateGroupBySectionNumber: 0];
    [self displaySelectedGroupByType];
    [[self navigationBar] popNavigationItemAnimated:YES];
}

- (void)didSelectGroupBySectionNumber:(NSUInteger)groupNumber {
    [self setAggregateGroupByType: MTGroupByTypeSection];
    [self setAggregateGroupBySectionNumber: groupNumber];
    [self displaySelectedGroupByType];
    [[self navigationBar] popNavigationItemAnimated:YES];
}

- (void)displaySelectedGroupByType {
    if ([self aggregateViewController]) {
        switch ([self aggregateGroupByType]) {
            case MTGroupByTypeSection: {

                NSUInteger group = [self aggregateGroupBySectionNumber];
                NSString *format = [RptqDocumentObjectAggregate displayStringForGroupByType: MTGroupByTypeSection];
                NSString *detail = [NSString stringWithFormat:format, group];
                [[[[self aggregateViewController] tableViewCellAggregateGroupBy] detailTextLabel] setText:detail];
                break;
                
            }
            case MTGroupByTypeReport: {

                NSString *detailText = [RptqDocumentObjectAggregate displayStringForGroupByType: MTGroupByTypeReport];
                [[[[self aggregateViewController] tableViewCellAggregateGroupBy] detailTextLabel] setText:detailText];
                break;
                
            }
            case MTGroupByTypePage: {

                NSString *detailText = [RptqDocumentObjectAggregate displayStringForGroupByType: MTGroupByTypePage];
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