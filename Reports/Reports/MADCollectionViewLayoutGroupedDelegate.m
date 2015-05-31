//
//  MADCollectionViewLayoutGroupedDelegate.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/30/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADCollectionViewLayoutGroupedDelegate.h"
#import "MADMetaData.h"
#import "MTCollectionViewCellDocument.h"
#import "UILabel+Constructors.h"
#import "UIView+Animations.h"

NSString * const MADImageToolbarCloudDownload = @"MADImageToolbarCloudDownload";

static const CGFloat fLabelWidth        = 124.0000f;
static const CGFloat fLabelMaxHeight    = 300.0000f;
static NSString * const sNotDownloaded              = @"Not Downloaded";

@interface MADCollectionViewLayoutGroupedDelegate ()

@property (nonatomic, strong) UILabel *testLabel;
@property (nonatomic, strong) UILabel *testLabelSub;

@end

@implementation MADCollectionViewLayoutGroupedDelegate

static inline CGRect rectCellLabel();
static inline CGRect rectCellLabel() {
    return CGRectMake(CGPointZero.x, CGPointZero.y, fLabelWidth, fLabelMaxHeight);
}

#pragma mark - Lazy Load

- (UILabel *)testLabel {
    if (!_testLabel) {
        UILabel *label = [UILabel documentCaption:rectCellLabel() width:fLabelWidth];
        _testLabel = label;
    }
    return _testLabel;
}

- (UILabel *)testLabelSub {
    if (!_testLabelSub) {
        UILabel *label = [UILabel documentCaption:rectCellLabel() width:fLabelWidth];
        _testLabelSub = label;
    }
    return _testLabelSub;
}

#pragma mark - UICollectionViewDelegate

- (BOOL)collectionView: (UICollectionView *)collectionView canPerformAction: (SEL)action forItemAtIndexPath: (NSIndexPath *)indexPath withSender: (id)sender {
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath { }

- (void)collectionView:(UICollectionView *)collectionView willDisplaySupplementaryView:(UICollectionReusableView *)view forElementKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath { }

- (void)collectionView: (UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind: (NSString *)elementKind atIndexPath: (NSIndexPath *)indexPath { }

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(selectionsUpdated)]) {
        [self.delegate selectionsUpdated];
    }
    MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell performSelectionAnimations];
    
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell performDeselectionAnimations];
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([self.delegate respondsToSelector:@selector(selectionsUpdated)]) {
        [self.delegate selectionsUpdated];
    }

    MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell performSelectionAnimations];
    
    if ([self.delegate isFileViewEditing] == NO) {
        [collectionView deselectItemAtIndexPath:indexPath animated:YES];
        [cell.activityIndicator startAnimating];
        [collectionView setUserInteractionEnabled: NO];
        
        if ([self.delegate respondsToSelector:@selector(userSelectedItemAtIndexPath:)]) {
            [self.delegate userSelectedItemAtIndexPath:indexPath];
        }
        
    } else {
        [collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredVertically];
    }
    
    if ([self.delegate respondsToSelector:@selector(selectionsUpdated)]) {
        [self.delegate selectionsUpdated];
    }
    
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(selectionsUpdated)]) {
        [self.delegate selectionsUpdated];
    }
    
    MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell performDeselectionAnimations];
    
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender { }

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

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return collectionView.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular ? UIEdgeInsetsMake(15.0000f, 15.0000f, 15.0000f, 15.0000f) :
                                                                                                   UIEdgeInsetsMake(5.0000f, 5.0000f, 5.0000f, 5.0000f);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return collectionView.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular ? 30.0000f : 5.0000f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return collectionView.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular ? 30.0000f : 5.0000f;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    
    NSString *filename = [self.delegate titleForItemAtIndexPath:indexPath];
    NSString *size = [self.delegate subtitleForItemAtIndexPath:indexPath];
    
    NSDictionary *attributesCaption = [MTCollectionViewCellDocument attributesCaption];
    NSDictionary *attributesCaption2 = [MTCollectionViewCellDocument attributesCaption];
    
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString: filename attributes: attributesCaption];
    
    CGFloat sizeLabelHeight = [self heightForAttributedString: attributedString contentScaleFactor: collectionView.contentScaleFactor font: [MTCollectionViewCellDocument CaptionFont]];
    
    NSAttributedString *attributedStringSub = [[NSAttributedString alloc] initWithString: size
                                                                              attributes: attributesCaption2];
    CGFloat sizeLabelSubHeight = [self heightForAttributedString: attributedStringSub contentScaleFactor: collectionView.contentScaleFactor font: [MTCollectionViewCellDocument CaptionFont2]];
    return CGSizeMake(140.0000f, 128.0000f + ceilf(sizeLabelHeight) + ceilf(sizeLabelSubHeight) + 20.0000f);
}

- (CGFloat)heightForAttributedString:(NSAttributedString *)attributedString contentScaleFactor:(CGFloat)contentScaleFactor font:(UIFont *)font {
    
    self.testLabel.frame = rectCellLabel();
    self.testLabel.font = font;
    self.testLabel.attributedText = attributedString;
    self.testLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.testLabel.contentScaleFactor = contentScaleFactor;
    [self.testLabel sizeToFit];
    return self.testLabel.frame.size.height;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(MTCollectionViewCellDocument *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {

    MADMetaData *metadata = [self.delegate metadataForItemAtIndexPath:indexPath];
    NSString *filename = metadata.name;
    cell.labelTitle.text = filename;
    
    BOOL notDownloaded = [metadata.ubiquitousItemDownloadingStatus isEqualToString: NSMetadataUbiquitousItemDownloadingStatusNotDownloaded];
    cell.progressViewDownload.hidden = !metadata.ubiquitousItemIsDownloading;
    cell.progressViewUpload.hidden = YES;
    
    cell.labelTitleSub.text = (notDownloaded ? NSLocalizedString(sNotDownloaded, sNotDownloaded) : [metadata fileSystemSizeMB]);
    
    if (metadata.ubiquitousItemIsUploading) {
        [cell.progressViewUpload setProgress:metadata.ubiquitousItemPercentUploaded animated:YES];
    } else {
        [cell.progressViewUpload setProgress:0.0000f animated:YES];
    }
    
    if (metadata.ubiquitousItemIsDownloading) {
        [cell.progressViewDownload setProgress:metadata.ubiquitousItemPercentDownloaded animated:YES];
    } else {
        [cell.progressViewDownload setProgress:0.0000f animated:YES];
    }
    
    cell.imageCloudIndicator.image = notDownloaded && metadata.isUbiquitous ? [UIImage imageNamed:MADImageToolbarCloudDownload] : nil;
    
    [cell.labelTitle layoutIfNeeded];
    [cell loadPreviewImageForUrl:metadata.URL];
    
    if ([self.delegate isFileViewEditing]) {
        [cell startWobble];
    } else {
        [cell stopWobble];
    }
    [cell normalizeTint];
}

@end
