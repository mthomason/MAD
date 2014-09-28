//
//  CloudManager.h
//  Reports
//
//  Created by Michael Thomason on 8/4/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const MTDocumentExtentionMobleApplicationDocumentArchive;
extern NSString * const MTDocumentExtentionMobleApplicationDocument;

NSString * const MTICloudUbiquityToken;
NSString * const MTICloudUserEnabled;
NSString * const MTICloudUserPrefsSet;


NSString * const MADPreferencesCloudDesired;
NSString * const MADPreferencesCloudOptionsSelected;

NSString * const ICloudStateUpdatedNotification;
NSString * const UbiquitousContainerFetchingWillBeginNotification;
NSString * const UbiquitousContainerFetchingDidEndNotification;

@protocol MADCloudManagerProtocol <NSObject>

- (void)ubiquityIdentityDidChange;

@end

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

+ (MACloudManager *)sharedManager;

- (void)activate;
- (void)checkUserICloudPreferenceAndSetupIfNecessary:(void (^)(void))completion;
- (NSArray *)hasMadDocuments;

- (NSSet *)contentsOfDocumentsDirectoryWithPathExtension:(NSString *)extension;

- (void)handleNotificationUbiquityIdentityDidChange:(NSNotification *)notification;

- (NSURL *)cacheDirectoryNamed:(NSString *)handle;
- (NSURL *)cachedDirectoryForFileUrl:(NSURL *)fileUrl;
- (NSURL *)duplicateUrl:(NSURL *)urlToDupe;

+ (NSString *)filenameId:(NSUInteger)tag;
+ (NSString *)filenameId:(NSUInteger)tag extention:(NSString *)fileExtention;

@end
