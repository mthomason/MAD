//
//  MADFileExplorerViewDelegate.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/30/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADFileExplorerViewDelegate.h"

#import <UIKit/UITableView.h>
#import <UIKit/UIActivityIndicatorView.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIImageView.h>
#import <UIKit/UILongPressGestureRecognizer.h>
#import <UIKit/UITapGestureRecognizer.h>

#import <MADCocoaExtensions/MADLabel.h>
#import <MADCocoaExtensions/MTMath.h>
#import <MADCocoaExtensions/MADNumberFormatter.h>
#import <MADCocoaExtensions/UIView+Animations.h>

#import <MADFileManager/MADMetaData.h>

#import "MADExplorerProtocol.h"
#import "MADExplorerCaption.h"

#import "MADLabelFileExplorerDocumentCellTitle.h"
#import "MADLabelFileExplorerDocumentCellSubtitle.h"

#import "MADCollectionViewCellDocument.h"

#import "MADStandard.h"

/*char *string_for_n(unsigned long fileSize) {
    char buffer_int[12];
    const double one_for_div = 1;
    double integral, fraction;
    fraction = modf(madSystemFileSizeToMB(fileSize), &integral);
    itoa(integral, buffer_int);



    double i = integral / 10;
    strcat(&buffer_int, <#const char *#>)
    i = integral / one_for_div;
    
}*/

typedef NSMutableDictionary <NSNumber *, UILongPressGestureRecognizer *> MADMutableMapGesturesLongPress;

static const CGFloat fLabelWidth        = 124.0000f;
static const CGFloat fLabelMaxHeight    = 300.0000f;

static inline CGRect MADCollectionViewLayoutGroupedCellLabelRect();
static inline CGRect MADCollectionViewLayoutGroupedCellLabelRect() {
    return CGRectMake(CGPointZero.x, CGPointZero.y, fLabelWidth, fLabelMaxHeight);
}

@interface MADFileExplorerViewDelegate ()

    @property (nonatomic, readwrite, strong) UILabel *testLabel;
    @property (nonatomic, readwrite, strong) NSMutableArray <NSMutableIndexSet *> *selected;
    @property (nonatomic, readwrite, strong) NSMutableArray <NSMutableIndexSet *> *highlighted;
    @property (nonatomic, strong) NSNumberFormatter *subtitleNumberFormatter;

    @property (nonatomic, strong) MADMutableMapGesturesLongPress *longPressGestures;

    @property (nonatomic, copy) NSPredicate *predicateKindOfLongPressGestureRecognizer;

@end

@implementation MADFileExplorerViewDelegate

@synthesize showingPopover = _showingPopover;

- (void)dealloc {
    _predicateKindOfLongPressGestureRecognizer = nil;
    _testLabel = nil;
    [_longPressGestures removeAllObjects];
}

#pragma mark -
#pragma mark Constructors

- (instancetype)init {
    id delegate = [self initWithNumberOfSections:1];
    return delegate;
}

- (instancetype)initWithNumberOfSections:(NSUInteger)numberOfSections {
    if (self = [super init]) {
        
        id label = [MADLabel newLabelDocumentCaption: MADCollectionViewLayoutGroupedCellLabelRect()
                                               width: fLabelWidth];
        self.testLabel = label;
        
        id array = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
        id indexSet;
        for (NSUInteger i = 0; i < numberOfSections; i++) {
            indexSet = [[NSMutableIndexSet alloc] init];
            [array addObject:indexSet];
            indexSet = nil;
        }
        self.selected = array;
        
        array = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
        for (NSUInteger i = 0; i < numberOfSections; i++) {
            indexSet = [[NSMutableIndexSet alloc] init];
            [array addObject:indexSet];
            indexSet = nil;
        }
        self.highlighted = array;
        
        _editing = NO;
        
        MADMutableMapGesturesLongPress *gestures = [[MADMutableMapGesturesLongPress alloc] init];
        self.longPressGestures = gestures;
        
    }
    return self;
}

#pragma mark -
#pragma mark Properties

- (NSArray <NSIndexPath *> *)indexPathsForSelectedItems {
    __block NSArray *indexPaths = [[NSArray alloc] init];
    NSInteger sectionIndex = 0;
    for (NSIndexSet *set in _selected) {
        [set enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            NSIndexPath *path = [NSIndexPath indexPathForItem:(NSInteger)idx
                                                    inSection:sectionIndex];
            indexPaths = [indexPaths arrayByAddingObject:path];
        }];
        sectionIndex++;
    }
    return indexPaths;
}

- (NSArray <NSIndexPath *> *)indexPathsForHighlightedItems {
    __block NSArray *indexPaths = [[NSArray alloc] init];
    NSInteger sectionIndex = 0;
    for (NSIndexSet *set in _highlighted) {
        [set enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            NSIndexPath *path = [NSIndexPath indexPathForItem:(NSInteger)idx
                                                    inSection:sectionIndex];
            indexPaths = [indexPaths arrayByAddingObject:path];
        }];
        sectionIndex++;
    }
    return indexPaths;
}

- (NSUInteger)numberOfItemsSelected {
    NSUInteger c = 0;
    for (NSIndexSet *set in _selected) {
        c += set.count;
    }
    return c;
}

- (NSUInteger)numberOfItemsHighlighted {
    NSUInteger c = 0;
    for (NSIndexSet *set in _highlighted) {
        c += set.count;
    }
    return c;
}

- (void)setEditing:(BOOL)editing {
    //NSLog(@"%s: %@", __PRETTY_FUNCTION__, editing ? @"YES" : @"NO");
    if (_editing != editing) {
        _editing = editing;
    }
}

#pragma mark -
#pragma mark Overrides

- (void)setShowingPopover:(BOOL)showingPopover {
    if (_showingPopover != showingPopover) {
        id <MADExplorerProtocol, UIGestureRecognizerDelegate> sdelegate = self.delegate;
        NSArray <NSIndexPath *> *visibleItems;
        visibleItems = [[sdelegate fileExplorerView] indexPathsForVisibleItems];
        id <MADExplorerProtocol, UIGestureRecognizerDelegate> __weak wdelegate = sdelegate;
        [visibleItems enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            MADCollectionViewCellDocument *visibleCell;
            visibleCell = (MADCollectionViewCellDocument *)[[wdelegate fileExplorerView] cellForItemAtIndexPath:obj];
            if (showingPopover) {
                visibleCell.labelTitle.textColor = visibleCell.labelTitle.disabledTextColor.copy;
            } else {
                visibleCell.labelTitle.textColor = visibleCell.labelTitle.enabledTextColor.copy;
            }
        }];
        _showingPopover = showingPopover;
    }
}

- (BOOL)isShowingPopover {
    return _showingPopover;
}

- (NSPredicate *)predicateKindOfLongPressGestureRecognizer {
    
    if (_predicateKindOfLongPressGestureRecognizer == nil) {
        NSPredicate *predicate;
        NSExpression *left, *right;
        left = [NSExpression expressionForEvaluatedObject];
        right = [NSExpression expressionForConstantValue:[UILongPressGestureRecognizer class]];
        predicate = [NSComparisonPredicate predicateWithLeftExpression: left
                                                       rightExpression: right
                                                        customSelector: @selector(isMemberOfClass:)];
        _predicateKindOfLongPressGestureRecognizer = predicate.copy;
        
    }
    return _predicateKindOfLongPressGestureRecognizer;
}

#pragma mark -
#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView
       willDisplayCell:(nonnull MADCollectionViewCellDocument *)cell
    forItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    typeof(_delegate) __strong fileExplorerDelegate = _delegate;
    cell.contentView.autoresizingMask = MADViewAutoresizingFlexable();
    cell.contentView.translatesAutoresizingMaskIntoConstraints = YES;
    
    id <MADExplorerProtocol, UIGestureRecognizerDelegate> delegate = fileExplorerDelegate;
    SEL actionEdit = @selector(actionActivateEditMode:);
    
    UILongPressGestureRecognizer *longPressGesture;
    longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget: self
                                                                     action: actionEdit];
    longPressGesture.delegate = delegate;
    [cell addGestureRecognizer: longPressGesture];
    typeof(_delegate) __weak weakdelegate = fileExplorerDelegate;
    cell.labelTitle.handleTap = ^(MADCollectionViewCellDocument *c) {
        [weakdelegate actionRename:c];
    };
    
    NSNumber *hash = [[NSNumber alloc] initWithUnsignedInteger:cell.hash];
    _longPressGestures[hash] = longPressGesture;
    
    MADMetaData *metadata = [delegate metadataForItemAtIndexPath:indexPath];
    [cell updateDisplayForMetaData:metadata editing:_editing];

}

- (void)collectionView:(UICollectionView *)collectionView
  didEndDisplayingCell:(MADCollectionViewCellDocument *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath {
    NSNumber *hash = [[NSNumber alloc] initWithUnsignedInteger:cell.hash];
    id gestureToRemove = _longPressGestures[hash];
    [cell removeGestureRecognizer: gestureToRemove];
    [cell prepareForReuse];
    if (self.isShowingPopover) {
        cell.labelTitle.textColor = cell.labelTitle.disabledTextColor.copy;
    } else {
        cell.labelTitle.textColor = cell.labelTitle.enabledTextColor.copy;
    }
    [_longPressGestures removeObjectForKey: hash];

    cell.delegate = nil;
}

- (BOOL)collectionView: (UICollectionView *)collectionView canPerformAction: (SEL)action
    forItemAtIndexPath: (NSIndexPath *)indexPath withSender: (id)sender {
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView
    willDisplaySupplementaryView:(UICollectionReusableView *)view
                  forElementKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath { }

- (void)collectionView: (UICollectionView *)collectionView
    didEndDisplayingSupplementaryView:(UICollectionReusableView *)view
    forElementOfKind: (NSString *)elementKind atIndexPath: (NSIndexPath *)indexPath { }

#pragma mark Highlight Item

- (BOOL)collectionView:(UICollectionView *)collectionView
                            shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)indexPath.item);
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView
                                        didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)indexPath.item);
    [self.highlighted[(NSUInteger)indexPath.section] addIndex:(NSUInteger)indexPath.item];
}

#pragma mark Unhighlight Item

- (void)collectionView:(UICollectionView *)collectionView
                                        didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {

    //NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)indexPath.item);
    [self.highlighted[(NSUInteger)indexPath.section] removeIndex:(NSUInteger)indexPath.item];
}

#pragma mark Select Item

- (BOOL)collectionView:(UICollectionView *)collectionView
                            shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)indexPath.item);
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView
                            didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)indexPath.item);

    [self.selected[(NSUInteger)indexPath.section] addIndex:(NSUInteger)indexPath.item];

    MADMetaData *metadata;
    NSURL *url;
    
    metadata = [_delegate metadataForItemAtIndexPath:indexPath];
    url = metadata.URL.copy;
    
    if (self.isEditing) {
        [self downloadIfNotYetDownloaded: metadata];
    } else {
        collectionView.allowsSelection = NO;
        MADCollectionViewCellDocument *cell;
        cell = (MADCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
        cell.working = YES;
        [self.delegate openDocumentAtURL:url];
    }

    [self invokeOperationDidChangeNumberOfItemsSelected:collectionView];
    
}

- (void)collectionView:(UICollectionView *)collectionView allowSelection:(BOOL)allowSelection {

    if (allowSelection) {
        NSInteger section = 0;
        for (NSMutableIndexSet *selectedSections in self.selected) {
            [selectedSections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                MADCollectionViewCellDocument *cell;
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:(NSInteger)idx
                                                             inSection:section];
                cell = (MADCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
                if (cell != nil) cell.working = NO;

            }];
            section++;
        }
        [self.selected removeAllObjects];
    }
    collectionView.allowsSelection = allowSelection;
}

#pragma mark Deselect Item

- (BOOL)collectionView:(UICollectionView *)collectionView
                            shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)indexPath.item);
    
    return _editing ?
        [_selected[(NSUInteger)indexPath.section] containsIndex:(NSUInteger)indexPath.item] :
        YES;
}

- (void)collectionView:(UICollectionView *)collectionView
                            didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {

    //NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)indexPath.item);
    MADCollectionViewCellDocument *cell;
    cell = (MADCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
    cell.working = NO;
    [self.selected[(NSUInteger)indexPath.section] removeIndex:(NSUInteger)indexPath.item];
    [self invokeOperationDidChangeNumberOfItemsSelected:collectionView];
}

- (void)collectionView:(UICollectionView *)collectionView
         performAction:(SEL)action
    forItemAtIndexPath:(NSIndexPath *)indexPath
            withSender:(id)sender {
    //NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)indexPath.item);
}

- (BOOL)collectionView:(UICollectionView *)collectionView
                            shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)indexPath.item);
    return NO;
}

#pragma mark -
#pragma mark UICollectionViewFlowLayoutDelegate

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
    return collectionView.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular ?
                                    UIEdgeInsetsMake(15.0000f, 15.0000f, 15.0000f, 15.0000f) :
                                    UIEdgeInsetsMake(5.0000f, 5.0000f, 5.0000f, 5.0000f);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
                                    minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return collectionView.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular ?
                                    30.0000f : 5.0000f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
                                    minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return collectionView.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular ?
                                    30.0000f : 5.0000f;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
                                            referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)indexPath.item);

    CGFloat sizeLabel[2];
    UIFont *font;
    NSString *filename, *size;
    NSAttributedString *attributedString, *attributedStringSub;
 
    filename = [self titleForItemAtIndexPath:indexPath];
    size = [self subtitleForItemAtIndexPath:indexPath];
    
    attributedString = [MADExplorerCaption newExplorerCaption:filename];
    
    font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    sizeLabel[0] = [self heightForAttributedString: attributedString
                                contentScaleFactor: collectionView.contentScaleFactor
                                              font: font];
    
    attributedStringSub = [MADExplorerCaption newExplorerCaption: size];
    
    font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    sizeLabel[1] = [self heightForAttributedString: attributedStringSub
                                contentScaleFactor: collectionView.contentScaleFactor
                                              font: font];
    return CGSizeMake(140.0000f,
                      (CGFloat)(128.0 + ceil(sizeLabel[0]) + ceil(sizeLabel[1]) + 20.0));
}

- (CGFloat)heightForAttributedString:(NSAttributedString *)attributedString
                  contentScaleFactor:(CGFloat)contentScaleFactor
                                font:(UIFont *)font {

    UILabel *lbl = _testLabel;
    lbl.frame = MADCollectionViewLayoutGroupedCellLabelRect();
    lbl.lineBreakMode = NSLineBreakByWordWrapping;
    lbl.contentScaleFactor = contentScaleFactor;
    lbl.font = font;
    lbl.attributedText = attributedString;
    [lbl sizeToFit];

    CGFloat height = lbl.frame.size.height;

    lbl.font = nil;
    lbl.attributedText = nil;
    lbl = nil;

    return height;
}

- (void)invokeOperationDidChangeNumberOfItemsSelected:(UICollectionView *)collectionView {
    NSObject <MADExplorerProtocol> *delegate = self.delegate;
    NSUInteger numberOfItemsSelected = [self numberOfItemsSelected];
    [delegate explorerDidChangeNumberOfItemsSelected: numberOfItemsSelected];
}

- (void)downloadIfNotYetDownloaded:(MADMetaData *)metadata {
    
    if (!metadata.isDownloaded) {
        
        NSURL *url = metadata.URL.copy;
        
        void (^startDownload)(void);
        startDownload = ^{

            if (url != nil) {
                NSError *error = nil;
                [[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL: url
                                                                              error: &error];
            }

        };
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:startDownload];
        
    }
    
}

#pragma mark -
#pragma mark Helpers

- (NSString *)subtitleForStatus:(NSString *)status fileSize:(unsigned long long)fileSize {
    id result;
    result = [status isEqualToString: NSMetadataUbiquitousItemDownloadingStatusNotDownloaded] ?
                        NSLocalizedString(MADTextNotDownloaded, MADTextNotDownloaded) :
                        [MADStandard newStandardStringForFileSize:fileSize];
    return result;
}

- (NSString *)titleForItemAtIndexPath:(NSIndexPath *)indexPath {
    MADMetaData *metadata;
    NSURL *url;
    NSString *lastPathComponent, *title, *result;
    
    metadata = [self.delegate metadataForItemAtIndexPath:indexPath];
    url = metadata.URL.copy;
    
    lastPathComponent = url.lastPathComponent;
    title = lastPathComponent.stringByDeletingPathExtension;
    
    result = [[NSString alloc] initWithString: title];
    return result;
}

- (NSString *)subtitleForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *subtitle;
    unsigned long long fileSize;
    MADMetaData *metadata;
    NSString *ubiquitousItemDownloadingStatus;
    
    @autoreleasepool {
        metadata = [_delegate metadataForItemAtIndexPath:indexPath];
        fileSize = metadata.fileSystemFileSize;
        ubiquitousItemDownloadingStatus = metadata.ubiquitousItemDownloadingStatus.copy;
        metadata = nil;
        subtitle = [MADStringFormatted newStringFormattedSubtitle:ubiquitousItemDownloadingStatus
                                                         fileSize:fileSize];
    }
    
    return subtitle;
}

- (NSNumberFormatter *)subtitleNumberFormatter {
    if (!_subtitleNumberFormatter) {
        _subtitleNumberFormatter = [MADNumberFormatter newNumberFormatterTwoDecimalPlaces];
    }
    return _subtitleNumberFormatter;
}

#pragma mark -
#pragma mark Actions

- (void)actionEmail:(id)sender {
    [_delegate actionEmail:self];
}

- (void)actionActivateEditMode:(id)sender {
    [_delegate actionActivateEditMode:sender];
}

- (void)actionRename:(id)sender {
    [_delegate actionRename:sender];
}

- (void)duplicate:(id)sender {
    [_delegate actionDuplicate:self];
}

@end
