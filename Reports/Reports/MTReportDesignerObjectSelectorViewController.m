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

typedef NS_ENUM(NSUInteger, MTDocumentObjectType) {
	MTDocumentObjectTypeLabelData = 0,
	MTDocumentObjectTypeLabel = 1,
	MTDocumentObjectTypeImage = 2,
    MTDocumentObjectTypeChart = 3,
    MTDocumentObjectTypeFormula = 4,
    MTDocumentObjectTypeAggregate = 5
};

@interface MTReportDesignerObjectSelectorViewController ()

@property (nonatomic, retain) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, retain) IBOutlet UINavigationItem *navigationItemMain;

@property (nonatomic, retain) UICollectionViewController *documentObjectSelectorViewController;
@property (nonatomic, retain) UIViewController *visibleViewController;
@property (nonatomic, retain) UIViewController *childViewController;
@property (nonatomic, retain) UIViewController *viewControllerToPush;
@property (nonatomic, retain) IBOutlet UIView *containerView;
@property (nonatomic, retain) UIView *childDisplayedView;

@property (atomic, assign) MTDocumentObjectType typeOfObjectToPush;
@property (atomic, assign) BOOL rootSelectorControllerIsVisable;

- (BOOL)childViewControllerIsVisable;
- (IBAction)done:(id)sender;


@end

@implementation MTReportDesignerObjectSelectorViewController

- (void)dealloc {
    [_viewControllerToPush release];
    [_visibleViewController release];
    [_childDisplayedView release];
    [_containerView release];
    [_navigationBar release];
    [_navigationItemMain release];
    [_documentObjectSelectorViewController release];
    [_childViewController release];
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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // MARK: Add collection view contorller.
    [[self navigationItemMain] setPrompt:NSLocalizedString(@"Choose an object to add to the report.", @"Prompt to choose an object.")];
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
    
    [self setRootSelectorControllerIsVisable:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    CGRect rect = CGRectMake(CGPointZero.x,
                             CGPointZero.y + [[self navigationBar] frame].size.height,
                             [[self view] frame].size.width,
                             [[self view] frame].size.height - [[self navigationBar] frame].size.height);
    [[[self childViewController] view] setFrame: rect];
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
    [[self objectSelectorDelegate] viewControllerDidFinish: self];
}

- (BOOL)childViewControllerIsVisable {
    return ![self rootSelectorControllerIsVisable];
}

#pragma mark - UITableViewControllerChooseFieldDelegate

- (void)tableViewControllerChooseFieldDidFinish:(MTQueryBuilderChooseFieldViewController *)controller withField:(RptqDatabaseSchemaField *)field {
    [[self objectSelectorDelegate] insertDocumentObjectDataField: field];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *selectedImage = [info objectForKey:UIImagePickerControllerEditedImage];
    if (!selectedImage) {
        selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    if (selectedImage) {
        [selectedImage retain];


        
        
        
        [selectedImage release];
    }
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {

}

#pragma mark - UICollectionViewDataSource

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *result = nil;
    NSString *cellIdentifier = nil;
    NSUInteger tag = 0;
    switch ([indexPath section]) {
        case 0: {
            switch ([indexPath row]) {
                case 0: {
                    cellIdentifier = MTIdentiferDocumentObjectLabelCollectionViewCell;
                    tag = MTDocumentObjectTypeLabel;
                    break;
                }
                case 1: {
                    cellIdentifier = MTIdentiferDocumentObjectFormulaCollectionViewCell;
                    tag = MTDocumentObjectTypeFormula;
                    break;
                }
                case 2: {
                    cellIdentifier = MTIdentiferDocumentObjectImageCollectionViewCell;
                    tag = MTDocumentObjectTypeImage;
                    break;
                }
                case 3: {
                    cellIdentifier = MTIdentiferDocumentObjectChartCollectionViewCell;
                    tag = MTDocumentObjectTypeChart;
                    break;
                }
                case 4: {
                    cellIdentifier = MTIdentiferDocumentObjectAggregateCollectionViewCell;
                    tag = MTDocumentObjectTypeAggregate;
                    break;
                }
                case 5: {
                    cellIdentifier = MTIdentiferDocumentObjectDataCollectionViewCell;
                    tag = MTDocumentObjectTypeLabelData;
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

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

    [collectionView deselectItemAtIndexPath:indexPath animated:YES];

    NSString *navigationItemTitle = nil;
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    MTDocumentObjectType objectType = [[cell contentView] tag];
    [self setTypeOfObjectToPush: objectType];

    switch ([indexPath section]) {
        case 0: {
            switch (objectType) {
                case MTDocumentObjectTypeLabel:
                    navigationItemTitle = NSLocalizedString(@"Label", @"Label");
                    break;
                case MTDocumentObjectTypeLabelData:
                    navigationItemTitle = NSLocalizedString(@"Data", @"Data");
                    break;
                case MTDocumentObjectTypeChart:
                    navigationItemTitle = NSLocalizedString(@"Chart", @"Chart");
                    [[self objectSelectorDelegate] insertDocumentObjectNewChart];
                    break;
                case MTDocumentObjectTypeImage:
                    navigationItemTitle = NSLocalizedString(@"Image", @"Image");
                    break;
                case MTDocumentObjectTypeAggregate:
                    navigationItemTitle = NSLocalizedString(@"Aggregate", @"Aggregate");
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

    UINavigationItem *itemToPush = [[UINavigationItem alloc] initWithTitle:navigationItemTitle];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                target:self
                                                                                action:@selector(pressedBackButton:)];

    [itemToPush setBackBarButtonItem:backButton];
    [[self navigationBar] pushNavigationItem:itemToPush animated:YES];
    
    [backButton release];
    
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

#pragma mark - UICollectionViewFlowLayoutDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(150.0000f, 100.0000f);
}

#pragma mark - UINavigationBarDelegate

- (void)navigationBar:(UINavigationBar *)navigationBar didPopItem:(UINavigationItem *)item {
 
}

- (void)navigationBar:(UINavigationBar *)navigationBar didPushItem:(UINavigationItem *)item {
    
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {

    BOOL popIt = [self rootSelectorControllerIsVisable] == NO;
    if (popIt) {

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

            case MTDocumentObjectTypeLabelData: {
                [item setPrompt: NSLocalizedString(@"Choose a data field to add to the report.", @"Prompt to choose a data field.")];
                [item setTitle:@"Label Data"];
                MTQueryBuilderChooseFieldViewController *queryBuilderChooseFieldViewController = [[storyboard instantiateViewControllerWithIdentifier:@"UITableViewControllerChooseField"] retain];
                [queryBuilderChooseFieldViewController setExcludeTables: [NSArray array]];
                [queryBuilderChooseFieldViewController setDelegate: self];
                viewControllerToAdd = [queryBuilderChooseFieldViewController retain];
                [queryBuilderChooseFieldViewController release];
                break;
            }
            
            case MTDocumentObjectTypeImage: {
                [item setPrompt: NSLocalizedString(@"Choose a data field to add to the report.", @"Prompt to choose a data field.")];
                [item setTitle:@"Image"];
                if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypePhotoLibrary]) {
                    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
                    [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
                    [imagePicker setDelegate: self];
                    viewControllerToAdd = [imagePicker retain];
                    [imagePicker release];
                }
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
            NSLog(@"Child view controller frame: %@", NSStringFromCGRect([[self childViewController] view].frame));
        } completion:^(BOOL finished) {
            
        }];
        
        [self setChildDisplayedView:[viewControllerToAdd view]];
        
        [self setViewControllerToPush:viewControllerToAdd];
        
        [viewControllerToAdd release];
    
    }
    
    return pushIt;
}

@end