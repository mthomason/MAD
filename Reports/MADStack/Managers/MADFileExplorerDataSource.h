//
//  MADFileExplorerDataSource.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/16/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADFileExplorerDataSource_h
#define Reports_MADFileExplorerDataSource_h

#import <Foundation/NSObject.h>
#import <UIKit/UICollectionView.h>
#import <MADFileManager/MADFileLocationManagerDelegate.h>

@protocol MADDocumentManagerProtocol;

@class MADMetaData;
@class MADCollectionViewCellDocument;

@interface MADFileExplorerDataSource : NSObject
    <UICollectionViewDataSource,
        MADFileLocationManagerDelegate>

    - (instancetype)initWithCellConfiguration:(void (^)(MADCollectionViewCellDocument *cell))cellCondiguration NS_DESIGNATED_INITIALIZER;

    @property (nonatomic, weak) UIViewController <MADDocumentManagerProtocol> * delegate;

    - (MADMetaData *)metadataAtIndex:(NSUInteger)index;
    - (NSUInteger)count;

    - (void)updateCloudPreferences;

    - (NSString *)groupIdentifier;

    - (void)rename:(NSString *)newName itemAtIndex:(NSUInteger)index;
    - (void)removeItemAtIndex:(NSUInteger)index;
    - (void)duplicateItemAtIndex:(NSUInteger)index;


    - (NSURL *)documentsDirectory;

@end

#endif
