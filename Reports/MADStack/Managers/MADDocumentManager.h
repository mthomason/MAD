//
//  MADDocumentManager.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/16/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADDocumentManager_h
#define Reports_MADDocumentManager_h

#import <Foundation/Foundation.h>
#import <UIKit/UICollectionView.h>

@protocol MADDocumentManagerProtocol;

@class MADMetaData;
@class MADCollectionViewCellDocument;

@interface MADDocumentManager : NSObject
    <UICollectionViewDataSource>

    - (instancetype)initWithCellConfiguration:(void (^)(MADCollectionViewCellDocument *cell))cellCondiguration;
                                        
    @property (nonatomic, weak) NSObject <MADDocumentManagerProtocol> * delegate;

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
