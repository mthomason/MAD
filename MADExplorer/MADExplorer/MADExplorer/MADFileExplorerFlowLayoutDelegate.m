//
//  MADFileExplorerFlowLayoutDelegate.m
//  MADExplorer
//
//  Created by Michael on 1/27/18.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
/*
#import "MADFileExplorerFlowLayoutDelegate.h"
#import <UIKit/UILabel.h>
#import <MADFileManager/MADMetaData.h>
#import "MADExplorerCellTitle.h"
#import "MADExplorerProtocol.h"
#import "MADExplorerCaption.h"
#import "MADStandard.h"

static const CGFloat fLabelWidth        = 124.0000f;
static const CGFloat fLabelMaxHeight    = 300.0000f;

static inline CGRect MADCollectionViewLayoutGroupedCellLabelRect(void);
static inline CGRect MADCollectionViewLayoutGroupedCellLabelRect(void) {
    return CGRectMake(CGPointZero.x, CGPointZero.y, fLabelWidth, fLabelMaxHeight);
}

@interface MADFileExplorerFlowLayoutDelegate ()

    @property (nonatomic, readwrite, strong) UILabel *testLabel;

@end

@implementation MADFileExplorerFlowLayoutDelegate

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

    CGFloat sizeLabel[2];
    UIFont *font;
    NSString *filename, *size;
    NSAttributedString *attributedString, *attributedStringSub;
 
    filename = [self titleForItemAtIndexPath:indexPath];
    size = [self subtitleForItemAtIndexPath:indexPath];
    
    attributedString = [MADExplorerCaption newExplorerCaption: filename];
    
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
    id metadata = [_delegate metadataForItemAtIndexPath:indexPath];
    id subtitle = [MADExplorerCellTitle newExplorerCellTitle:metadata];
    return subtitle;
}

@end
*/
