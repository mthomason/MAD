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

@interface MTReportDesignerObjectSelectorViewController ()

@property (atomic, assign) MTDocumentObjectType typeOfObjectToPush;

@property (nonatomic, retain) UIViewController *visableViewController;
@property (nonatomic, retain) UIViewController *childViewController;
@property (nonatomic, retain) UICollectionViewController *documentObjectSelectorViewController;

@property (atomic, assign) BOOL rootSelectorControllerIsVisable;

- (BOOL)childViewControllerIsVisable;

@end

@implementation MTReportDesignerObjectSelectorViewController

@synthesize visableViewController = _visableViewController;

- (void)dealloc {
    if (_visableViewController) [_visableViewController release];
    [_segmentedControlSelectorType release];
    [_containerView release];
    [_toolbarMain release];
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
    BOOL imagePickerAvailable = [UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypePhotoLibrary];
    
    [[self segmentedControlSelectorType] setSelectedSegmentIndex: MNSSegmentedControlOptionsData];

    [[self segmentedControlSelectorType] setEnabled: imagePickerAvailable
                                  forSegmentAtIndex: MNSSegmentedControlOptionsMedia];
    [[self segmentedControlSelectorType] setEnabled: YES
                                  forSegmentAtIndex: MNSSegmentedControlOptionsData];
    [[self segmentedControlSelectorType] setEnabled: YES
                                  forSegmentAtIndex: MNSSegmentedControlOptionsObjects];
    [self showObjectSelector];
    [[self navigationBar] setDelegate:self];
    
    UIViewController *childViewController = [[UIViewController alloc] init];
    [self setChildViewController:childViewController];
    [childViewController release];
    
    [self setRootSelectorControllerIsVisable:YES];
}

#pragma mark - Actions

- (IBAction)segmentedControlSelectorTypeValueChanged:(id)sender {
    [self showObjectSelector];
}

- (IBAction)done:(id)sender {
    [[self objectSelectorDelegate] viewControllerDidFinish: self];
}


- (void)showObjectSelectorOfType:(MTDocumentObjectType)objectType {
    UIViewController *hidingView = nil;
    if ([self visableViewController] != nil) {
        hidingView = [[self visableViewController] retain];
    }
    
    switch (objectType) {
        case MNSSegmentedControlOptionsData: {

            [[self navigationItemMain] setPrompt: NSLocalizedString(@"Choose a data field to add to the report.", @"Prompt to choose a data field.")];
            UIStoryboard *storyboard = [[UIStoryboard storyboardWithName:[AppDelegate storyboardName] bundle:nil] retain];
            MTQueryBuilderChooseFieldViewController *queryBuilderChooseFieldViewController = [[storyboard instantiateViewControllerWithIdentifier:@"UITableViewControllerChooseField"] retain];
            [queryBuilderChooseFieldViewController setExcludeTables:[NSArray array]];
            [queryBuilderChooseFieldViewController setDelegate: self];
            [self setVisableViewController: queryBuilderChooseFieldViewController];
            [queryBuilderChooseFieldViewController release];
            [storyboard release];
            
            break;
        }
        case MNSSegmentedControlOptionsMedia: {

            [[self navigationItemMain] setPrompt: NSLocalizedString(@"Choose an image to add to the report.", @"Prompt to choose an image.")];
            if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypePhotoLibrary]) {
                UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
                [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
                [imagePicker setDelegate: self];
                [self setVisableViewController: imagePicker];
                [imagePicker release];
            }

            break;
        }
        case MNSSegmentedControlOptionsObjects: {

            [[self navigationItemMain] setPrompt:NSLocalizedString(@"Choose an object to add to the report.", @"Prompt to choose an object.")];
            UIStoryboard *storyboard = [[UIStoryboard storyboardWithName:[AppDelegate storyboardName] bundle:nil] retain];
            UICollectionViewController *documentObjectSelectorViewController = [[storyboard instantiateViewControllerWithIdentifier:@"MTDocumentObjectSelectorViewControllerIdentifier"] retain];
            [[documentObjectSelectorViewController collectionView] setDelegate:self];
            [[documentObjectSelectorViewController collectionView] setDataSource:self];
            [self setVisableViewController: documentObjectSelectorViewController];
            [self setDocumentObjectSelectorViewController:documentObjectSelectorViewController];
            [documentObjectSelectorViewController release];
            [storyboard release];
            
            break;
        }
        default:
            break;
    }
    
    [[[self visableViewController] view] setFrame:[[self containerView] bounds]];
    [UIView animateWithDuration:0.20000f animations:^{
        if (hidingView) [[hidingView view] removeFromSuperview];
        if ([self visableViewController]) {
            [[self containerView] addSubview:[[self visableViewController] view]];
        }
    } completion:^(BOOL finished) {
        if (hidingView) [hidingView release];
    }];
}

- (void)showObjectSelector {

    UIViewController *hidingView = nil;
    if ([self visableViewController] != nil) {
        hidingView = [[self visableViewController] retain];
    }

    switch (MNSSegmentedControlOptionsObjects) {
        case MNSSegmentedControlOptionsData: {
            [[self navigationItemMain] setPrompt: NSLocalizedString(@"Choose a data field to add to the report.", @"Prompt to choose a data field.")];
            
            UIStoryboard *storyboard = [[UIStoryboard storyboardWithName:[AppDelegate storyboardName] bundle:nil] retain];
            MTQueryBuilderChooseFieldViewController *queryBuilderChooseFieldViewController = [[storyboard instantiateViewControllerWithIdentifier:@"UITableViewControllerChooseField"] retain];
            [queryBuilderChooseFieldViewController setExcludeTables:[NSArray array]];
            [queryBuilderChooseFieldViewController setDelegate: self];
            [self setVisableViewController: queryBuilderChooseFieldViewController];
            [queryBuilderChooseFieldViewController release];
            [storyboard release];
            
            break;
        }
        case MNSSegmentedControlOptionsMedia: {
            [[self navigationItemMain] setPrompt: NSLocalizedString(@"Choose an image to add to the report.", @"Prompt to choose an image.")];
            if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypePhotoLibrary]) {
                UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
                [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
                [imagePicker setDelegate: self];
                [self setVisableViewController: imagePicker];
                [imagePicker release];
            }
            break;
        }
        case MNSSegmentedControlOptionsObjects:
            [[self navigationItemMain] setPrompt:NSLocalizedString(@"Choose an object to add to the report.", @"Prompt to choose an object.")];
            UIStoryboard *storyboard = [[UIStoryboard storyboardWithName:[AppDelegate storyboardName] bundle:nil] retain];
            UICollectionViewController *documentObjectSelectorViewController = [[storyboard instantiateViewControllerWithIdentifier:@"MTDocumentObjectSelectorViewControllerIdentifier"] retain];
            [[documentObjectSelectorViewController collectionView] setDelegate:self];
            [[documentObjectSelectorViewController collectionView] setDataSource:self];
            [self setVisableViewController: documentObjectSelectorViewController];
            [documentObjectSelectorViewController release];
            [storyboard release];
            break;
        default:
            break;
    }
    
    [[[self visableViewController] view] setFrame:[[self containerView] bounds]];
    [UIView animateWithDuration:0.20000f animations:^{
        if (hidingView) [[hidingView view] removeFromSuperview];
        if ([self visableViewController]) {
            [[self containerView] addSubview:[[self visableViewController] view]];
        }
    } completion:^(BOOL finished) {
        if (hidingView) [hidingView release];
    }];

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
    switch ([indexPath section]) {
        case 0: {
            switch ([indexPath row]) {
                case 0: {
                    cellIdentifier = MTIdentiferDocumentObjectLabelCollectionViewCell;
                    break;
                }
                case 1: {
                    cellIdentifier = MTIdentiferDocumentObjectFormulaCollectionViewCell;
                    break;
                }
                case 2: {
                    cellIdentifier = MTIdentiferDocumentObjectImageCollectionViewCell;
                    break;
                }
                case 3: {
                    cellIdentifier = MTIdentiferDocumentObjectChartCollectionViewCell;
                    break;
                }
                case 4: {
                    cellIdentifier = MTIdentiferDocumentObjectAggregateCollectionViewCell;
                    break;
                }
                case 5: {
                    cellIdentifier = MTIdentiferDocumentObjectDataCollectionViewCell;
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
    MTDocumentObjectType objectType = [indexPath row];
    
    [self setTypeOfObjectToPush: objectType];
//    [collectionView setAllowsSelection: NO];

    switch ([indexPath section]) {
        case 0: {
            switch (objectType) {
                case MTDocumentObjectTypeLabel:
                    navigationItemTitle = NSLocalizedString(@"Label", @"Label");
                    //[[self objectSelectorDelegate] insertDocumentObjectNewLabel];
                    break;
                case MTDocumentObjectTypeLabelData:
                    navigationItemTitle = NSLocalizedString(@"Data", @"Data");
                    //[[self objectSelectorDelegate] insertDocumentObjectNewFormula];
                    break;
                case MTDocumentObjectTypeChart:
                    navigationItemTitle = NSLocalizedString(@"Chart", @"Chart");
                    [[self objectSelectorDelegate] insertDocumentObjectNewChart];
                    break;
                case MTDocumentObjectTypeImage:
                    navigationItemTitle = NSLocalizedString(@"Image", @"Image");
                    [self showObjectSelectorOfType:MTDocumentObjectTypeImage];
                    break;
                case MTDocumentObjectTypeAggregate:
                    navigationItemTitle = NSLocalizedString(@"Aggregate", @"Aggregate");
                    [self showObjectSelectorOfType:MTDocumentObjectTypeAggregate];
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
    //[itemToPush release];
    
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
 
    CGRect offScreen = CGRectMake([[[self childViewController] view] frame].origin.x + [[[self childViewController] view] frame].size.width,
                                  [[[self childViewController] view] frame].origin.y,
                                  [[[self childViewController] view] frame].size.width,
                                  [[[self childViewController] view] frame].size.height);

    [UIView animateWithDuration:0.3000f animations:^{
        [[[self childViewController] view] setFrame: offScreen];
    } completion:^(BOOL finished) {
        [[[self childViewController] view] removeFromSuperview];
        [[[self documentObjectSelectorViewController] collectionView] setAllowsSelection: YES];
    }];

}

- (void)navigationBar:(UINavigationBar *)navigationBar didPushItem:(UINavigationItem *)item {
    
    [item setPrompt: NSLocalizedString(@"Choose a data field to add to the report.", @"Prompt to choose a data field.")];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:[AppDelegate storyboardName] bundle:nil];
    UIView *viewToAdd = nil;

    switch ([self typeOfObjectToPush]) {
        case MTDocumentObjectTypeLabelData: {

            MTQueryBuilderChooseFieldViewController *queryBuilderChooseFieldViewController = [[storyboard instantiateViewControllerWithIdentifier:@"UITableViewControllerChooseField"] retain];
            [queryBuilderChooseFieldViewController setExcludeTables: [NSArray array]];
            [queryBuilderChooseFieldViewController setDelegate: self];
            viewToAdd = [[queryBuilderChooseFieldViewController tableView] retain];
            [queryBuilderChooseFieldViewController release];

            break;
        }
        default: {

            break;
        }
    }

    [viewToAdd setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [viewToAdd setBounds:[[[self childViewController] view] bounds]];
    [[[self childViewController] view] addSubview:viewToAdd];

    CGRect newRect = [[[self visableViewController] view] frame];
    CGRect newRectOffscreen = CGRectMake(CGPointZero.x + [[[self childViewController] view] bounds].size.width,
                                         [[[self childViewController] view] frame].origin.y,
                                         [[[self childViewController] view] frame].size.width,
                                         [[[self childViewController] view] frame].size.height);
    
    [[[self childViewController] view] setFrame:newRectOffscreen];
    [[[self visableViewController] view] addSubview:[[self childViewController] view]];
    [[[self visableViewController] view] bringSubviewToFront:[[self childViewController] view]];
    [UIView animateWithDuration:0.3000f animations:^{
        [[[self childViewController] view] setFrame:newRect];
    } completion:^(BOOL finished) {
        
    }];

    [viewToAdd release];

}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {
    BOOL popIt = [self rootSelectorControllerIsVisable] == NO;
    if (popIt) {
        [self setRootSelectorControllerIsVisable:YES];
        [[[self documentObjectSelectorViewController] collectionView] setAllowsSelection: YES];
    }
    return popIt;
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPushItem:(UINavigationItem *)item {
    BOOL pushIt = [self rootSelectorControllerIsVisable];
    if (pushIt) {
        [self setRootSelectorControllerIsVisable:NO];
    }
    return pushIt;
}

@end