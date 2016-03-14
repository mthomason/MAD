//
//  MADCollectionViewLayoutGroupedDelegate.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/30/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADCollectionViewLayoutGroupedDelegate_h
#define Reports_MADCollectionViewLayoutGroupedDelegate_h

#import <Foundation/NSObject.h>
#import <UIKit/UICollectionView.h>
#import <UIKit/UICollectionViewFlowLayout.h>

extern NSString * const MADImageToolbarCloudDownload;

@class  MADMetaData;

@protocol MADCollectionViewLayoutFilesDelegate <NSObject>
@required

- (NSString *)titleForItemAtIndexPath:(NSIndexPath *)indexPath;
- (NSString *)subtitleForItemAtIndexPath:(NSIndexPath *)indexPath;
- (MADMetaData *)metadataForItemAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)isFileViewEditing;

@optional

- (void)userSelectedItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)selectionsUpdated;

@end

@interface MADCollectionViewLayoutGroupedDelegate : NSObject
    <UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, weak) id <MADCollectionViewLayoutFilesDelegate> delegate;

@end

#endif
