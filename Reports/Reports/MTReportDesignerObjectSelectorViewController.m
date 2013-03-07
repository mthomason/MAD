//
//  UIViewControllerObjectSelector.m
//  Reports
//
//  Created by Michael Thomason on 1/15/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTReportDesignerObjectSelectorViewController.h"

@interface MTReportDesignerObjectSelectorViewController ()

@property (retain) UIViewController *visableViewController;

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
}

#pragma mark - Actions

- (IBAction)segmentedControlSelectorTypeValueChanged:(id)sender {
    [self showObjectSelector];
}

- (IBAction)done:(id)sender {
    [[self objectSelectorDelegate] viewControllerDidFinish: self];
}

- (void)showObjectSelector {
    UIViewController *hidingView = nil;
    if ([self visableViewController] != nil) {
        hidingView = [[self visableViewController] retain];
    }

    switch ([[self segmentedControlSelectorType] selectedSegmentIndex]) {
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

#pragma mark UITableViewControllerChooseFieldDelegate

- (void)tableViewControllerChooseFieldDidFinish:(MTQueryBuilderChooseFieldViewController *)controller withField:(RptqField *)field {
    [[self objectSelectorDelegate] insertDocumentObjectDataField: field];
}

#pragma mark UIImagePickerControllerDelegate

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

NSString * const MTIdentiferDocumentObjectLabelCollectionViewCell = @"MTIdentiferDocumentObjectLabelCollectionViewCell";
NSString * const MTIdentiferDocumentObjectFormulaCollectionViewCell = @"MTIdentiferDocumentObjectFormulaCollectionViewCell";
NSString * const MTIdentiferDocumentObjectHyperlinkCellCollectionViewCell = @"MTIdentiferDocumentObjectHyperlinkCellCollectionViewCell";
NSString * const MTIdentiferDocumentObjectChartCollectionViewCell = @"MTIdentiferDocumentObjectChartCollectionViewCell";

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
                    cellIdentifier = MTIdentiferDocumentObjectHyperlinkCellCollectionViewCell;
                    break;
                }
                case 3: {
                    cellIdentifier = MTIdentiferDocumentObjectChartCollectionViewCell;
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
    switch ([indexPath section]) {
        case 0: {
            switch ([indexPath row]) {
                case 0:
                    [[self objectSelectorDelegate] insertDocumentObjectNewLabel];
                    break;
                case 1:
                    [[self objectSelectorDelegate] insertDocumentObjectNewFormula];
                    break;
                case 2:
                    [[self objectSelectorDelegate] insertDocumentObjectNewHyperlink];
                    break;
                case 3:
                    [[self objectSelectorDelegate] insertDocumentObjectNewChart];
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
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
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


@end