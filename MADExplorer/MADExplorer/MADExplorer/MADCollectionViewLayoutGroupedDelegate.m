//
//  MADCollectionViewLayoutGroupedDelegate.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/30/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADCollectionViewLayoutGroupedDelegate.h"
#import "MADCollectionViewLayoutGroupedDelegateProtocol.h"

#import "MTCollectionViewCellDocument.h"
#import <MADCocoaExtensions/MADLabel.h>

static const CGFloat fLabelWidth        = 124.0000f;
static const CGFloat fLabelMaxHeight    = 300.0000f;

static inline CGRect MADCollectionViewLayoutGroupedCellLabelRect();
static inline CGRect MADCollectionViewLayoutGroupedCellLabelRect() {
    return CGRectMake(CGPointZero.x, CGPointZero.y, fLabelWidth, fLabelMaxHeight);
}

@interface MADCollectionViewLayoutGroupedDelegate ()

    @property (nonatomic, strong) UILabel *testLabel;

@end

@implementation MADCollectionViewLayoutGroupedDelegate

#pragma mark - Lazy Load

- (UILabel *)testLabel {
    if (!_testLabel) {
        UILabel *label = [MADLabel newLabelDocumentCaption: MADCollectionViewLayoutGroupedCellLabelRect()
                                                     width: fLabelWidth];
        _testLabel = label;
    }
    return _testLabel;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView
       willDisplayCell:(nonnull MADCollectionViewCellDocument *)cell
    forItemAtIndexPath:(nonnull NSIndexPath *)indexPath { }

- (BOOL)collectionView: (UICollectionView *)collectionView canPerformAction: (SEL)action
    forItemAtIndexPath: (NSIndexPath *)indexPath withSender: (id)sender {
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView
            didEndDisplayingCell:(MADCollectionViewCellDocument *)cell
              forItemAtIndexPath:(NSIndexPath *)indexPath { }

- (void)collectionView:(UICollectionView *)collectionView
    willDisplaySupplementaryView:(UICollectionReusableView *)view
                  forElementKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {

}

- (void)collectionView: (UICollectionView *)collectionView
    didEndDisplayingSupplementaryView:(UICollectionReusableView *)view
    forElementOfKind: (NSString *)elementKind atIndexPath: (NSIndexPath *)indexPath {

}

- (void)collectionView:(UICollectionView *)collectionView
                                        didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {

    id <MADCollectionViewLayoutFilesDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(selectionsUpdated)]) {
        [delegate selectionsUpdated];
    }
    MADCollectionViewCellDocument *cell;
    cell = (MADCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell performSelectionAnimations];
    
}

- (void)collectionView:(UICollectionView *)collectionView
                                        didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {

    MADCollectionViewCellDocument *cell;
    cell = (MADCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell performDeselectionAnimations];
    
}

- (void)collectionView:(UICollectionView *)collectionView
                                                didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

    id <MADCollectionViewLayoutFilesDelegate> delegate = self.delegate;
    NSInvocationOperation *operations;
    if ([delegate respondsToSelector:@selector(selectionsUpdated)]) {
        operations = [[NSInvocationOperation alloc] initWithTarget: delegate
                                                          selector: @selector(selectionsUpdated)
                                                            object: nil];
        [[NSOperationQueue mainQueue] addOperation:operations];
    }
    
    if ([delegate respondsToSelector:@selector(userSelectedItemAtIndexPath:)]) {
        NSIndexPath *path = indexPath.copy;
        operations = [[NSInvocationOperation alloc] initWithTarget: delegate
                                                          selector: @selector(userSelectedItemAtIndexPath:)
                                                            object: path];
        [[NSOperationQueue mainQueue] addOperation:operations];
    }
    
    if ([delegate respondsToSelector:@selector(selectionsUpdated)]) {
        operations = [[NSInvocationOperation alloc] initWithTarget: delegate
                                                          selector: @selector(selectionsUpdated)
                                                            object: nil];
        [[NSOperationQueue mainQueue] addOperation:operations];
    }
    
}

- (void)collectionView:(UICollectionView *)collectionView
                                            didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {

    id <MADCollectionViewLayoutFilesDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(selectionsUpdated)]) {
        [delegate selectionsUpdated];
    }
    
    MADCollectionViewCellDocument *cell;
    cell = (MADCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell performDeselectionAnimations];
    
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action
    forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender { }

- (BOOL)collectionView:(UICollectionView *)collectionView
                                        shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
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

    id <MADCollectionViewLayoutFilesDelegate> delegate = self.delegate;
    NSString *filename = [delegate titleForItemAtIndexPath:indexPath].copy;
    NSString *size = [delegate subtitleForItemAtIndexPath:indexPath].copy;
    
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

    self.testLabel.frame = MADCollectionViewLayoutGroupedCellLabelRect();
    self.testLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.testLabel.contentScaleFactor = contentScaleFactor;
    self.testLabel.font = font;
    self.testLabel.attributedText = attributedString;
    [self.testLabel sizeToFit];

    CGFloat height = self.testLabel.frame.size.height;

    self.testLabel.font = nil;
    self.testLabel.attributedText = nil;

    return height;
}

@end
