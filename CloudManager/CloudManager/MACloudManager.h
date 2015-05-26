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

typedef void (^MADBlockCompletionFileStorageLocation)(BOOL cloudAvailble, NSURL *documents, NSURL *data);

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

@property (nonatomic, strong, readwrite) NSString *groupId;

+ (MACloudManager *)sharedManager;
+ (BOOL)isCloudAvailable;

+ (void)getFileStorageLocationsForUbiquityIdentifier: (NSString *)ubiquityIdentifier
                                     groupIdentifier: (NSString *)groupIdentifier
                                               delay: (void (^)())handleLongRunningCall
                                          completion: (MADBlockCompletionFileStorageLocation)handleCompletion;

+ (NSURL *)uniqueUrlInDirectory:(NSURL *)directory
              withDesiredHandle:(NSString *)desiredFileHandle
                   andExtension:(NSString *)extension;

+ (NSURL *)uniqueURLForURL:(NSURL *)url;

+ (NSString *)filenameId:(NSUInteger)tag;

@end

#endif
