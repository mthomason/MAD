//
//  MADExplorerDataSource.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/16/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADExplorerDataSource_h
#define Reports_MADExplorerDataSource_h

#import <Foundation/NSObject.h>
#import <UIKit/UICollectionView.h>
#import <MADFileManager/MADFileLocationManagerDelegate.h>

@protocol MADDocumentManagerProtocol;

@class MADMetaData, MADCollectionViewCellDocument;

@interface MADExplorerDataSource : NSObject
    <UICollectionViewDataSource,
        MADFileLocationManagerDelegate>
    - (instancetype)initWithFileExtension:(NSString *)fileExtension
                                  groupID:(NSString *)groupID
                               ubiquityID:(NSString *)ubiquityID
                        cellConfiguration:(void (^)(MADCollectionViewCellDocument *cell, NSIndexPath *path))config
                        NS_DESIGNATED_INITIALIZER;

    @property (nonatomic, weak) UIViewController <MADDocumentManagerProtocol> * delegate;

    - (MADMetaData *)metadataAtIndex:(NSUInteger)index;

    - (NSString *)title:(NSIndexPath *)index;
    - (NSString *)subtitle:(NSIndexPath *)index;

    - (NSUInteger)count;

    - (void)updateCloudPreferences;

    + (NSString *)groupIdentifier;

    - (void)rename:(NSString *)newName itemAtIndex:(NSUInteger)index;
    - (void)removeItemAtIndex:(NSUInteger)index;
    - (void)duplicateItemAtIndex:(NSUInteger)index;

    - (NSURL *)documentsDirectory;

@end

#endif
