//
//  MADCollectionViewLayoutGroupedDelegate.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/30/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADCollectionViewLayoutGroupedDelegate.h"
#import "MTCollectionViewCellDocument.h"
#import <MADCocoaExtensions/MADLabel.h>

NSString * const MADImageToolbarCloudDownload = @"MADImageToolbarCloudDownload";

static const CGFloat fLabelWidth        = 124.0000f;
static const CGFloat fLabelMaxHeight    = 300.0000f;

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
        UILabel *label = [MADLabel newDocumentCaption:rectCellLabel() width:fLabelWidth];
        _testLabel = label;
    }
    return _testLabel;
}

- (UILabel *)testLabelSub {
    if (!_testLabelSub) {
        UILabel *label = [MADLabel newDocumentCaption:rectCellLabel() width:fLabelWidth];
        _testLabelSub = label;
    }
    return _testLabelSub;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(nonnull MTCollectionViewCellDocument *)cell forItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    //NSLog(@"\t%s", __PRETTY_FUNCTION__);

}

- (BOOL)collectionView: (UICollectionView *)collectionView canPerformAction: (SEL)action forItemAtIndexPath: (NSIndexPath *)indexPath withSender: (id)sender {
    //NSLog(@"\t%s", __PRETTY_FUNCTION__);
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(MTCollectionViewCellDocument *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"\t%s", __PRETTY_FUNCTION__);
    /*if ([self.delegate isFileViewEditing]) {
        [cell startWobble];
    } else {
        [cell stopWobble];
    }*/
}

- (void)collectionView:(UICollectionView *)collectionView willDisplaySupplementaryView:(UICollectionReusableView *)view forElementKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"\t%s", __PRETTY_FUNCTION__);

}

- (void)collectionView: (UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind: (NSString *)elementKind atIndexPath: (NSIndexPath *)indexPath {
    //NSLog(@"\t%s", __PRETTY_FUNCTION__);
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"\t%s", __PRETTY_FUNCTION__);
    if ([self.delegate respondsToSelector:@selector(selectionsUpdated)]) {
        [self.delegate selectionsUpdated];
    }
    MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell performSelectionAnimations];
    
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"\t%s", __PRETTY_FUNCTION__);
    MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell performDeselectionAnimations];
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"\t%s", __PRETTY_FUNCTION__);
    
    if ([self.delegate respondsToSelector:@selector(selectionsUpdated)]) {
        [self.delegate selectionsUpdated];
    }

    if ([self.delegate respondsToSelector:@selector(userSelectedItemAtIndexPath:)]) {
        NSIndexPath *path = indexPath.copy;
        [self.delegate userSelectedItemAtIndexPath:path];
    }
    
    if ([self.delegate respondsToSelector:@selector(selectionsUpdated)]) {
        [self.delegate selectionsUpdated];
    }
    
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"\t%s", __PRETTY_FUNCTION__);
    if ([self.delegate respondsToSelector:@selector(selectionsUpdated)]) {
        [self.delegate selectionsUpdated];
    }
    
    MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell performDeselectionAnimations];
    
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    //NSLog(@"\t%s", __PRETTY_FUNCTION__);
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"\t%s", __PRETTY_FUNCTION__);
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"\t%s", __PRETTY_FUNCTION__);
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"\t%s", __PRETTY_FUNCTION__);
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"\t%s", __PRETTY_FUNCTION__);
    return NO;
}

#pragma mark - UICollectionViewFlowLayoutDelegate

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    //NSLog(@"\t%s", __PRETTY_FUNCTION__);
    return collectionView.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular ? UIEdgeInsetsMake(15.0000f, 15.0000f, 15.0000f, 15.0000f) :
                                                                                                   UIEdgeInsetsMake(5.0000f, 5.0000f, 5.0000f, 5.0000f);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    //NSLog(@"\t%s", __PRETTY_FUNCTION__);
    return collectionView.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular ? 30.0000f : 5.0000f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    //NSLog(@"\t%s", __PRETTY_FUNCTION__);
    return collectionView.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular ? 30.0000f : 5.0000f;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    //NSLog(@"\t%s", __PRETTY_FUNCTION__);
    return CGSizeZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"\t%s", __PRETTY_FUNCTION__);
    
    NSString *filename = [self.delegate titleForItemAtIndexPath:indexPath];
    NSString *size = [self.delegate subtitleForItemAtIndexPath:indexPath];
    
    NSDictionary *attributesCaption = [MTCollectionViewCellDocument attributesCaption];
    NSDictionary *attributesCaption2 = [MTCollectionViewCellDocument attributesCaption];
    
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString: filename attributes: attributesCaption];
    
    UIFont *font = [MTCollectionViewCellDocument newCaptionFont];
    CGFloat sizeLabelHeight = [self heightForAttributedString: attributedString
                                           contentScaleFactor: collectionView.contentScaleFactor
                                                         font: font];
    
    NSAttributedString *attributedStringSub = [[NSAttributedString alloc] initWithString: size
                                                                              attributes: attributesCaption2];
    
    font = [MTCollectionViewCellDocument newCaptionFont2];
    CGFloat sizeLabelSubHeight = [self heightForAttributedString: attributedStringSub
                                              contentScaleFactor: collectionView.contentScaleFactor
                                                            font: font];
    return CGSizeMake(140.0000f, (CGFloat)(128.0 + ceil(sizeLabelHeight) + ceil(sizeLabelSubHeight) + 20.0));
}

- (CGFloat)heightForAttributedString:(NSAttributedString *)attributedString contentScaleFactor:(CGFloat)contentScaleFactor font:(UIFont *)font {
    //NSLog(@"\t%s", __PRETTY_FUNCTION__);
    
    self.testLabel.frame = rectCellLabel();
    self.testLabel.font = font;
    self.testLabel.attributedText = attributedString;
    self.testLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.testLabel.contentScaleFactor = contentScaleFactor;
    [self.testLabel sizeToFit];
    return self.testLabel.frame.size.height;
}

@end
