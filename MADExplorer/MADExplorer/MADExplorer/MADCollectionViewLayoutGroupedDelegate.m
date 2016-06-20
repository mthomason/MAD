//
//  MADFileExplorerViewDelegate.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/30/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADCollectionViewLayoutGroupedDelegate.h"
#import "MADCollectionViewLayoutGroupedDelegateProtocol.h"

#import "MTCollectionViewCellDocument.h"
#import <MADCocoaExtensions/MADLabel.h>
#import <UIKit/UITableView.h>
#import <UIKit/UIActivityIndicatorView.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIImageView.h>
#import <MADFileManager/MADMetaData.h>
#import <MADFoundation/NSURL+Document.h>
#import <MADCocoaExtensions/MTMath.h>
#import <MADCocoaExtensions/NSNumberFormatter+Constructors.h>

static const CGFloat fLabelWidth        = 124.0000f;
static const CGFloat fLabelMaxHeight    = 300.0000f;

static NSString * const NotDownloaded                           = @"Not Downloaded";
static NSString * const Syncing                                 = @"Syncing";
static NSString * const Downloading                             = @"Downloading";
static NSString * const MADImageToolbarCloudDownload            = @"MADImageToolbarCloudDownload";

static inline CGRect MADCollectionViewLayoutGroupedCellLabelRect();
static inline CGRect MADCollectionViewLayoutGroupedCellLabelRect() {
    return CGRectMake(CGPointZero.x, CGPointZero.y, fLabelWidth, fLabelMaxHeight);
}

@interface MADFileExplorerViewDelegate ()

    @property (nonatomic, readwrite, strong) UILabel *testLabel;
    @property (nonatomic, readwrite, strong) NSMutableArray <NSMutableIndexSet *> *selected;
    @property (nonatomic, readwrite, strong) NSMutableArray <NSMutableIndexSet *> *highlighted;
    @property (nonatomic, strong) NSNumberFormatter *subtitleNumberFormatter;

@end

@implementation MADFileExplorerViewDelegate

- (NSString *)titleForItemAtIndexPath:(NSIndexPath *)indexPath {
    MADMetaData *metadata;
    metadata = [_delegate metadataForItemAtIndexPath:indexPath];
    NSString *title = metadata.URL.lastPathComponent.stringByDeletingPathExtension;
    return title;
}

- (NSString *)subtitleForItemAtIndexPath:(NSIndexPath *)indexPath {
    MADMetaData *metadata;
    metadata = [_delegate metadataForItemAtIndexPath:indexPath];
    NSString *subtitle = [self copySubtitleForStatus:metadata.ubiquitousItemDownloadingStatus
                                            fileSize:metadata.fileSystemFileSize];
    return subtitle;
}

- (NSNumberFormatter *)subtitleNumberFormatter {
    if (!_subtitleNumberFormatter) {
        _subtitleNumberFormatter = [NSNumberFormatter newNumberFormatterTwoDecimalPlaces];
    }
    return _subtitleNumberFormatter;
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

- (id)init {
    id delegate = [self initWithNumberOfSections:1];
    return delegate;
}

- (id)initWithNumberOfSections:(NSUInteger)numberOfSections {
    NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)numberOfSections);
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
        
    }
    return self;
}

- (void)setEditing:(BOOL)editing {
    NSLog(@"%s: %hhd", __PRETTY_FUNCTION__, editing);
    if (_editing != editing) {
        _editing = editing;
    }
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView
       willDisplayCell:(nonnull MADCollectionViewCellDocument *)cell
    forItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)indexPath.item);
    
    id <MADFileExplorerViewDelegateProtocol> delegate = _delegate;
    MADMetaData *metadata = [delegate metadataForItemAtIndexPath:indexPath];
    cell.labelTitle.text = metadata.name.copy;
    
    BOOL notDownloaded  = [metadata.ubiquitousItemDownloadingStatus isEqualToString:
                           NSMetadataUbiquitousItemDownloadingStatusNotDownloaded],
    downloading    = metadata.ubiquitousItemIsDownloading,
    uploading      = metadata.ubiquitousItemIsUploading;
    
    id cellText;
    if (downloading) {
        cellText = NSLocalizedString(Downloading, Downloading);
        cell.labelTitleSub.text = cellText;
    } else if (uploading) {
        cellText = NSLocalizedString(Syncing, Syncing);
        cell.labelTitleSub.text = cellText;
    } else {
        NSString *subtitle = [self copySubtitleForStatus:metadata.ubiquitousItemDownloadingStatus
                                                fileSize:metadata.fileSystemFileSize];
        cell.labelTitleSub.text = subtitle;
    }
    [cell setUploadingActive:uploading percent:metadata.ubiquitousItemPercentUploaded];
    [cell setDownloadingActive:downloading percent:metadata.ubiquitousItemPercentDownloaded];
    
    UIActivityIndicatorView *activityIndicator = cell.activityIndicator;
    
    if (metadata.ubiquitousItemIsDownloading || metadata.ubiquitousItemIsUploading)
        [activityIndicator startAnimating];
    else
        [activityIndicator stopAnimating];
    
    cell.imageCloudIndicator.image = notDownloaded && metadata.isUbiquitous ?
    [UIImage imageNamed:MADImageToolbarCloudDownload] : nil;
    
    [cell.labelTitle layoutIfNeeded];
    [cell.labelTitleSub layoutIfNeeded];
    
    @autoreleasepool {
        NSURL *thumbnailUrl = [NSURL newThumbnailUrlForMadUrl:metadata.URL];
        NSString *path = thumbnailUrl.path;
        if (!path) goto END_ReadThumbnail;
        
        {
            NSData *imageData = [[NSData alloc] initWithContentsOfFile:path];
            UIImage *image = [[UIImage alloc] initWithData:imageData scale:6.0];
            
            if (image != nil) {
                cell.imagePreview.image = image;
            } else {
                image = [MADCollectionViewCellDocument newDefaultThumbnail];
                cell.imagePreview.image = image;
            }
            image = nil;
            imageData = nil;
        }
        
    END_ReadThumbnail:;
    }
    
    if (_editing) {
        [cell startWobble];
    } else {
        [cell stopWobble];
    }
    
}

- (NSString *)copySubtitleForStatus:(NSString *)status fileSize:(unsigned long long)fileSize {
    NSString *result;
    if ([status isEqualToString: NSMetadataUbiquitousItemDownloadingStatusNotDownloaded]) {
        result = NSLocalizedString(NotDownloaded, NotDownloaded);;
    } else {
        NSNumber *systemFileSizeMB = [[NSNumber alloc] initWithDouble:madSystemFileSizeToMB(fileSize)];
        NSString *systemFileSizeString = [self.subtitleNumberFormatter stringFromNumber:systemFileSizeMB];
        result = [[NSString alloc] initWithFormat:@"%@ MB", systemFileSizeString];
    }
    return result;
}

- (void)collectionView:(UICollectionView *)collectionView
  didEndDisplayingCell:(MADCollectionViewCellDocument *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath {
    [cell stopWobble];
    NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)indexPath.item);
    
}

- (BOOL)collectionView: (UICollectionView *)collectionView canPerformAction: (SEL)action
    forItemAtIndexPath: (NSIndexPath *)indexPath withSender: (id)sender {
    NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)indexPath.item);
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView
    willDisplaySupplementaryView:(UICollectionReusableView *)view
                  forElementKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)indexPath.item);

}

- (void)collectionView: (UICollectionView *)collectionView
    didEndDisplayingSupplementaryView:(UICollectionReusableView *)view
    forElementOfKind: (NSString *)elementKind atIndexPath: (NSIndexPath *)indexPath {
    NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)indexPath.item);

}

- (void)collectionView:(UICollectionView *)collectionView
                                        didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)indexPath.item);
    
    [self.highlighted[(NSUInteger)indexPath.section] addIndex:(NSUInteger)indexPath.item];
    
//    id <MADFileExplorerViewDelegateProtocol> delegate = self.delegate;
//    if ([delegate respondsToSelector:@selector(collectionView:didChangeNumberOfItemsSelected:)]) {
//        [delegate collectionView:collectionView didChangeNumberOfItemsSelected:self.numberOfItemsSelected];
//    }
    MADCollectionViewCellDocument *cell;
    cell = (MADCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell performSelectionAnimations];
    
}

- (void)collectionView:(UICollectionView *)collectionView
                                        didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)indexPath.item);

    [self.highlighted[(NSUInteger)indexPath.section] removeIndex:(NSUInteger)indexPath.item];
    
    MADCollectionViewCellDocument *cell;
    cell = (MADCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell performDeselectionAnimations];
    
}

- (void)collectionView:(UICollectionView *)collectionView
                                                didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

    NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)indexPath.item);
    [self.selected[(NSUInteger)indexPath.section] addIndex:(NSUInteger)indexPath.item];

    id <MADFileExplorerViewDelegateProtocol> delegate = _delegate;
    MADMetaData *metadata = [delegate metadataForItemAtIndexPath:indexPath];
    MADCollectionViewCellDocument *cell = (MADCollectionViewCellDocument *)
    [collectionView cellForItemAtIndexPath:indexPath];
    [cell performSelectionAnimations];
    
    if (self.isEditing) {
        [self downloadIfNotYetDownloaded:metadata];
    } else {
        [self openURL:metadata.URL];
    }

    [self invokeOperationCollectionViewDidChangeNumberOfItemsSelected:collectionView];
    
}

- (void)openURL:(NSURL *)url {
    id open = [[NSInvocationOperation alloc] initWithTarget:self.delegate
                                                   selector:@selector(openDocumentAtURL:)
                                                     object:url];
    [[NSOperationQueue mainQueue] addOperation:open];
}

- (void)downloadIfNotYetDownloaded:(MADMetaData *)metadata {
    if (metadata.isUbiquitous && metadata.isUbiquitousItemDownloadingStatusNotDownloaded) {
        
        NSURL *url = metadata.URL.copy;
        void (^startDownload)(void);
        startDownload = ^{
            NSError *error = nil;
            [[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL:url
                                                                          error:&error];
        };
        [[NSOperationQueue mainQueue] addOperationWithBlock:startDownload];
        
    }
}

- (void)collectionView:(UICollectionView *)collectionView
                                            didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)indexPath.item);

    [self.selected[(NSUInteger)indexPath.section] removeIndex:(NSUInteger)indexPath.item];

    [self invokeOperationCollectionViewDidChangeNumberOfItemsSelected:collectionView];
    
    MADCollectionViewCellDocument *cell;
    cell = (MADCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell performDeselectionAnimations];
    
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action
    forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)indexPath.item);

    
}

- (BOOL)collectionView:(UICollectionView *)collectionView
                                        shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)indexPath.item);
    
    //Deselect when not editing, or when editing and already selected.
    return _editing ?
        [_selected[(NSUInteger)indexPath.section] containsIndex:(NSUInteger)indexPath.item] : YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView
                                        shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)indexPath.item);
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView
                                        shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)indexPath.item);
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView
                                        shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)indexPath.item);
    return NO;
}

#pragma mark - UICollectionViewFlowLayoutDelegate

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
    NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)section);
    return collectionView.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular ?
            UIEdgeInsetsMake(15.0000f, 15.0000f, 15.0000f, 15.0000f) :
            UIEdgeInsetsMake(5.0000f, 5.0000f, 5.0000f, 5.0000f);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
                                    minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)section);
    return collectionView.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular ?
        30.0000f : 5.0000f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
                                    minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)section);
    return collectionView.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular ?
        30.0000f : 5.0000f;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
                                            referenceSizeForHeaderInSection:(NSInteger)section {
    NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)section);
    return CGSizeZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {

    NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)indexPath.item);
    id <MADFileExplorerViewDelegateProtocol> delegate = self.delegate;
    NSString *filename = [self titleForItemAtIndexPath:indexPath].copy;
    NSString *size = [self subtitleForItemAtIndexPath:indexPath].copy;
    
    NSDictionary *attributesCaption = [MADCollectionViewCellDocument newAttributesCaption];
    NSDictionary *attributesCaption2 = [MADCollectionViewCellDocument newAttributesCaption];
    
    NSAttributedString *attributedString;
    attributedString = [[NSAttributedString alloc] initWithString: filename
                                                       attributes: attributesCaption];
    
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    CGFloat sizeLabelHeight = [self heightForAttributedString: attributedString
                                           contentScaleFactor: collectionView.contentScaleFactor
                                                         font: font];
    
    NSAttributedString *attributedStringSub;
    attributedStringSub = [[NSAttributedString alloc] initWithString: size
                                                          attributes: attributesCaption2];
    
    font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    CGFloat sizeLabelSubHeight = [self heightForAttributedString: attributedStringSub
                                              contentScaleFactor: collectionView.contentScaleFactor
                                                            font: font];
    return CGSizeMake(140.0000f,
                      (CGFloat)(128.0 + ceil(sizeLabelHeight) + ceil(sizeLabelSubHeight) + 20.0));
}

- (CGFloat)heightForAttributedString:(NSAttributedString *)attributedString
                  contentScaleFactor:(CGFloat)contentScaleFactor font:(UIFont *)font {

    NSLog(@"%s", __PRETTY_FUNCTION__);
    UILabel * __unsafe_unretained lbl = _testLabel;
    lbl.frame = MADCollectionViewLayoutGroupedCellLabelRect();
    lbl.lineBreakMode = NSLineBreakByWordWrapping;
    lbl.contentScaleFactor = contentScaleFactor;
    lbl.font = font;
    lbl.attributedText = attributedString;
    [lbl sizeToFit];

    CGFloat height = self.testLabel.frame.size.height;

    lbl.font = nil;
    lbl.attributedText = nil;

    return height;
}

- (void)invokeOperationCollectionViewDidChangeNumberOfItemsSelected:(UICollectionView *)collectionView {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSObject <MADFileExplorerViewDelegateProtocol> *delegate = self.delegate;
    NSInvocationOperation *operations;
    SEL selector = @selector(collectionView:didChangeNumberOfItemsSelected:);
    if ([delegate respondsToSelector:selector]) {
        NSMethodSignature *signature = [delegate methodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setArgument:&collectionView atIndex:2];
        NSNumber *count = [[NSNumber alloc] initWithUnsignedInteger:self.numberOfItemsSelected];
        [invocation setArgument:&count atIndex:3];
        operations = [[NSInvocationOperation alloc] initWithInvocation:invocation];
        [[NSOperationQueue mainQueue] addOperation:operations];
    }
}

@end
