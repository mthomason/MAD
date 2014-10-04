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

extern NSString * const MTDocumentExtentionMobleApplicationDocument;
extern NSString * const MTDocumentExtentionMobleApplicationDocumentArchive;
extern NSString * const MADNotificationFileManagerDidUpdateFileLocations;
extern NSString * const MADNotificationCloudStateUpdated;
extern NSString * const MADNotificationUbiquitousContainerFetchingWillBegin;
extern NSString * const MADNotificationUbiquitousContainerFetchingDidEnd;

@protocol MADCloudManagerProtocol <NSObject>

- (void)ubiquityIdentityDidChange;

@end

@class MADFileLocationManager;

@interface MACloudManager : NSObject

@property (nonatomic, weak) id <MADCloudManagerProtocol> delegate;

@property (nonatomic, assign, getter=isCloudEnabled, readonly) BOOL cloudEnabled;
@property (nonatomic, strong, readonly) NSURL *dataDirectoryURL;
@property (nonatomic, strong, readonly) NSURL *documentsDirectoryURL;
@property (nonatomic, strong, readonly) NSURL *localTemporaryDirectory;
@property (nonatomic, strong, readonly) NSURL *cachesDirectory;
@property (nonatomic, strong, readonly) NSURL *applicationSupport;
@property (nonatomic, assign, readonly) BOOL cloudDesired;
@property (nonatomic, assign, readonly) BOOL cloudAvailble;
@property (nonatomic, assign, readonly) BOOL cloudOptionsPresentedAndSelectedByUser;

@property (nonatomic, strong, readonly) MADFileLocationManager *fileLocationManager;

+ (MACloudManager *)sharedManager;

- (void)activate;
- (void)checkUserICloudPreferenceAndSetupIfNecessary:(void (^)(void))completion;

- (NSArray *)hasMadDocuments;

- (NSSet *)contentsOfDocumentsDirectoryWithPathExtension:(NSString *)extension;

- (void)handleNotificationUbiquityIdentityDidChange:(NSNotification *)notification;

- (NSURL *)duplicateUrl:(NSURL *)urlToDupe;
- (void)moveDocument:(NSURL*)source
          toLocation:(NSURL*)destination
          completion:(void (^)(BOOL success, NSError *error))completion;
- (NSURL *)uniqueUrlForDocumentWithName:(NSString *)name withExtension:(NSString *)extension;

+ (NSString *)filenameId:(NSUInteger)tag;
+ (NSString *)filenameId:(NSUInteger)tag extention:(NSString *)fileExtention;


@end

#endif
