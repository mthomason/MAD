//
//  MADFileExplorerViewDelegate.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/30/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADFileExplorerViewDelegate.h"
#import "MADCollectionViewLayoutGroupedDelegateProtocol.h"

#import <UIKit/UITableView.h>
#import <UIKit/UIActivityIndicatorView.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIImageView.h>
#import <UIKit/UILongPressGestureRecognizer.h>
#import <UIKit/UITapGestureRecognizer.h>

#import <MADExplorer/MADAttributedStringFileExplorer.h>

#import <MADCocoaExtensions/MADLabel.h>
#import <MADCocoaExtensions/MTMath.h>
#import <MADCocoaExtensions/MADNumberFormatter.h>

#import <MADFileManager/MADMetaData.h>

#import "MADLabelFileExplorerDocumentCellTitle.h"
#import "MADLabelFileExplorerDocumentCellSubtitle.h"

#import "MTCollectionViewCellDocument.h"

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
typedef NSMutableDictionary <NSNumber *, UITapGestureRecognizer *>       MADMutableMapGesturesTap;

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

- (void)dealloc {
    _predicateKindOfLongPressGestureRecognizer = nil;
    [_longPressGestures removeAllObjects];
}

#pragma mark -
#pragma mark Constructors

- (instancetype)init {
    id delegate = [self initWithNumberOfSections:1];
    return delegate;
}

- (instancetype)initWithNumberOfSections:(NSUInteger)numberOfSections {
    //NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)numberOfSections);
    if (self = [super init]) {
        
        id label = [MADLabel newLabelDocumentCaption: MADCollectionViewLayoutGroupedCellLabelRect()
                                               width: fLabelWidth];
        self.testLabel = label;
        
        id array = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
        id indexSet;
        for (NSUInteger i = 0; i < numberOfSections; i++) {
            indexSet = [[NSMutableIndexSet alloc] init];
            [array addObject:indexSet];
        }
        self.selected = array;
        
        array = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
        for (NSUInteger i = 0; i < numberOfSections; i++) {
            indexSet = [[NSMutableIndexSet alloc] init];
            [array addObject:indexSet];
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
    //NSLog(@"%s: %hhd", __PRETTY_FUNCTION__, editing);
    if (_editing != editing) {
        _editing = editing;
    }
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView
       willDisplayCell:(nonnull MADCollectionViewCellDocument *)cell
    forItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    //NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)indexPath.item);
    
    id <MADFileExplorerViewDelegateProtocol, UIGestureRecognizerDelegate> delegate = _delegate;
    SEL actionEdit = @selector(actionActivateEditMode:);
    
    UILongPressGestureRecognizer *longPressGesture;
    longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget: self
                                                                     action: actionEdit];
    longPressGesture.delegate = delegate;
    [cell addGestureRecognizer: longPressGesture];
    
    cell.labelTitle.handleTap = ^(MADCollectionViewCellDocument *cell) {
        [self actionRename:cell];
    };
    
    /*MADLabelFileExplorerDocumentCellTitle *labelTitle = cell.labelTitle;
    labelTitle.handleTap = ^(id sender) {
        [self actionRename:sender];
    };*/

    
    NSNumber *hash = [[NSNumber alloc] initWithUnsignedInteger:cell.hash];
    _longPressGestures[hash] = longPressGesture;
    
    MADMetaData *metadata = [delegate metadataForItemAtIndexPath:indexPath];
    [cell updateDisplayForMetaData:metadata editing:_editing];

}

- (NSPredicate *)predicateKindOfLongPressGestureRecognizer {
    
    if (_predicateKindOfLongPressGestureRecognizer == nil) {
        
        NSString *format = @"NOT (self isKindOfClass: %@)";
        NSPredicate *predicate = [NSPredicate predicateWithFormat: format, [UILongPressGestureRecognizer class]];
        _predicateKindOfLongPressGestureRecognizer = predicate.copy;
        
    }
    return _predicateKindOfLongPressGestureRecognizer;

}

- (void)collectionView:(UICollectionView *)collectionView
  didEndDisplayingCell:(MADCollectionViewCellDocument *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    
    //id predicate = self.predicateKindOfLongPressGestureRecognizer;
    
    //NSArray<__kindof UIGestureRecognizer *> *gestures, *gesturesFiltered;
    //gestures = cell.gestureRecognizers.copy;
    //gesturesFiltered = [gestures filteredArrayUsingPredicate:predicate];
    //[cell setGestureRecognizers:gesturesFiltered];
    
    NSNumber *hash = [[NSNumber alloc] initWithUnsignedInteger:cell.hash];
    id gestureToRemove = _longPressGestures[hash];
    [cell removeGestureRecognizer: gestureToRemove];
    [cell prepareForReuse];
    [_longPressGestures removeObjectForKey: hash];
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

- (void)collectionView:(UICollectionView *)collectionView
                                        didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.highlighted[(NSUInteger)indexPath.section] addIndex:(NSUInteger)indexPath.item];
}

- (void)collectionView:(UICollectionView *)collectionView
                                        didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {

    [self.highlighted[(NSUInteger)indexPath.section] removeIndex:(NSUInteger)indexPath.item];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

    [self.selected[(NSUInteger)indexPath.section] addIndex:(NSUInteger)indexPath.item];

    MADMetaData *metadata;
    NSURL *url;
    
    metadata = [_delegate metadataForItemAtIndexPath:indexPath];
    url = metadata.URL.copy;
    
    if (self.isEditing) {
        [self downloadIfNotYetDownloaded: metadata];
    } else {
        [self openURL: url];
    }

    [self invokeOperationCollectionViewDidChangeNumberOfItemsSelected:collectionView];
    
}

- (void)collectionView:(UICollectionView *)collectionView
                                            didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {

    [self.selected[(NSUInteger)indexPath.section] removeIndex:(NSUInteger)indexPath.item];

    [self invokeOperationCollectionViewDidChangeNumberOfItemsSelected:collectionView];
// FIXME: Do something here.
    /*MADCollectionViewCellDocument *cell;
    cell = (MADCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];*/
    
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action
    forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    //NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)indexPath.item);

    
}

- (BOOL)collectionView:(UICollectionView *)collectionView
                                        shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    //Deselect when not editing, or when editing and already selected.
    return _editing ?
        [_selected[(NSUInteger)indexPath.section] containsIndex:(NSUInteger)indexPath.item] : YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView
                                        shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView
                                        shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView
                                        shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark - UICollectionViewFlowLayoutDelegate

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

    CGFloat sizeLabel[2];
    UIFont *font;
    NSString *filename, *size;
    NSAttributedString *attributedString, *attributedStringSub;
 
    filename = [self copyTitleForItemAtIndexPath:indexPath];
    size = [self copySubtitleForItemAtIndexPath:indexPath];
    
    attributedString = [MADAttributedStringFileExplorer newAttributedStringFileExplorerCaption:filename];
    
    font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    sizeLabel[0] = [self heightForAttributedString: attributedString
                                           contentScaleFactor: collectionView.contentScaleFactor
                                                         font: font];
    
    attributedStringSub = [MADAttributedStringFileExplorer newAttributedStringFileExplorerCaption: size];
    
    font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    sizeLabel[1] = [self heightForAttributedString: attributedStringSub
                                      contentScaleFactor: collectionView.contentScaleFactor
                                                    font: font];
    return CGSizeMake(140.0000f,
                      (CGFloat)(128.0 + ceil(sizeLabel[0]) + ceil(sizeLabel[1]) + 20.0));
}

/*- (UILabel *)testLabel {
    if (_testLabel == nil) {
        id label = [MADLabel newLabelDocumentCaption: MADCollectionViewLayoutGroupedCellLabelRect()
                                               width: fLabelWidth];
        _testLabel = label;
    }
    return _testLabel;
}*/

- (CGFloat)heightForAttributedString:(NSAttributedString *)attributedString
                  contentScaleFactor:(CGFloat)contentScaleFactor font:(UIFont *)font {

    //NSLog(@"%s", __PRETTY_FUNCTION__);
    UILabel __unsafe_unretained *lbl = _testLabel;
    lbl.frame = MADCollectionViewLayoutGroupedCellLabelRect();
    lbl.lineBreakMode = NSLineBreakByWordWrapping;
    lbl.contentScaleFactor = contentScaleFactor;
    lbl.font = font;
    lbl.attributedText = attributedString;
    [lbl sizeToFit];

    CGFloat height = lbl.frame.size.height;

    lbl.font = nil;
    lbl.attributedText = nil;

    return height;
}

- (void)invokeOperationCollectionViewDidChangeNumberOfItemsSelected:(UICollectionView *)collectionView {
    
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    NSObject <MADFileExplorerViewDelegateProtocol> *delegate = self.delegate;
    NSUInteger numberOfItemsSelected = [self numberOfItemsSelected];
    [delegate fileExplorerDidChangeNumberOfItemsSelected: numberOfItemsSelected];

}

- (void)openURL:(NSURL *)url {
    MADFileExplorerDelegate delegate = self.delegate;
    NSURL *urlToOpen = url.copy;
    id open = [[NSInvocationOperation alloc] initWithTarget: self.delegate
                                                   selector: @selector(openDocumentAtURL:)
                                                     object: urlToOpen];
    [[NSOperationQueue mainQueue] addOperation:open];
}

- (void)downloadIfNotYetDownloaded:(MADMetaData *)metadata {
    
    if (metadata.isDownloaded) {
        
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


- (NSString *)copySubtitleForStatus:(NSString *)status fileSize:(unsigned long long)fileSize {
    NSString *result;
    result = [status isEqualToString: NSMetadataUbiquitousItemDownloadingStatusNotDownloaded] ?
                        NSLocalizedString(MADTextNotDownloaded, MADTextNotDownloaded) :
                        [MADStandard newStandardStringForFileSize:fileSize];
    return result;
}

- (NSString *)copyTitleForItemAtIndexPath:(NSIndexPath *)indexPath {
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

- (NSString *)copySubtitleForItemAtIndexPath:(NSIndexPath *)indexPath {
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
