//
//  CloudManager.h
//  Reports
//
//  Created by Michael Thomason on 8/4/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MACloudManager_h
#define MAD_MACloudManager_h

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MACloudManagerSection) {
    MACloudManagerSectionLocal = 0,
    MACloudManagerSectionCloud = 1,
};

extern NSString * const MADNotificationCloudStateUpdated;

extern NSString * const MADNotificationUbiquitousContainerFetchingWillBegin;
extern NSString * const MADNotificationUbiquitousContainerFetchingDidEnd;

@protocol MADCloudManagerProtocolAppDetails <NSObject>
- (NSString *)ubiquityIdentifier;
@end

@protocol MADCloudManagerProtocolCallbacks <NSObject>

- (void)ubiquityIdentityDidChange;

@end

@class MADMetadataQueryManager, MADMetaData;

@interface MACloudManager : NSObject

@property (nonatomic, weak) id <MADCloudManagerProtocolCallbacks> delegate;
@property (nonatomic, weak) id <MADCloudManagerProtocolAppDetails> delegateApplication;

@property (nonatomic, strong) NSString *searchString;

@property (nonatomic, strong, readonly) MADMetadataQueryManager *fileLocationManager;

@property (nonatomic, strong, readonly) NSMutableArray       *documentCacheCloudMetaDataItems;
@property (nonatomic, strong, readonly) NSMutableArray       *documentCacheLocalUrls;

@property (nonatomic, strong, readwrite) NSString *groupId;

+ (MACloudManager *)sharedManager;
+ (BOOL)isCloudAvailable;

+ (void)getFileStorageLocationsForUbiquityIdentifier: (NSString *)ubiquityIdentifier
                                     groupIdentifier: (NSString *)groupIdentifier
                                               delay: (void (^)())handleLongRunningCall
                                          completion: (void (^)(BOOL cloudAvailble, NSURL *documents, NSURL *data))handleCompletion;

// File operations

- (void)moveDocument: (NSURL *)source
          toLocation: (NSURL *)destination
          completion: (void (^)(BOOL, NSError *))completion;

+ (BOOL)duplicateUrl:(NSURL *)urlToDupe;

- (BOOL)copyUrl: (NSURL *)urlToCopy
          toUrl: (NSURL *)uniqueUrl
     completion: (void (^)(BOOL, NSURL *, NSError *))completion;

- (NSURL *)uniqueUrlForDocumentWithName: (NSString *)name
                          withExtension: (NSString *)extension
                            inContainer: (MACloudManagerSection)container;
+ (NSURL *)uniqueUrlInDirectory:(NSURL *)directory
              withDesiredHandle:(NSString *)desiredFileHandle
                   andExtension:(NSString *)extension;
+ (NSURL *)uniqueURLForURL:(NSURL *)url;

// File name helpers

+ (NSString *)filenameId:(NSUInteger)tag;

- (MADMetaData *)metadataForItemAtLocation:(NSUInteger)location
                                 inSection:(MACloudManagerSection)section;

@end

#endif
