//
//  MADDocumentManager.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/16/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MADDocumentManagerProtocol <NSObject>

    - (void)documentManagerDidChangeContent:(NSArray *)inserts
                                    removes:(NSArray *)removes
                                    updates:(NSArray *)updates
                                 completion:(void (^)(BOOL, NSError *))completion;

    - (void)handleDidDisconnectFromClound:(id)sender;
    - (void)handleDidStartLongRunningActivity;
    - (void)handleDidCompletedLongRunningActivity;

@end

@class MADMetaData;

@interface MADDocumentManager : NSObject

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
