//
//  CloudManager.h
//  Reports
//
//  Created by Michael Thomason on 8/4/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const MTDocumentExtentionMobleApplicationDocumentArchive;

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

@property (nonatomic, assign) BOOL isCloudEnabled;

@property (nonatomic, strong, readonly) NSURL *dataDirectoryURL;
@property (nonatomic, strong, readonly) NSURL *documentsDirectoryURL;
@property (nonatomic, strong, readonly) NSURL *localTemporaryDirectory;
@property (nonatomic, strong, readonly) NSURL *cachesDirectory;
@property (nonatomic, strong, readonly) NSURL *applicationSupport;

- (void)updateICloudEnabled:(NSNotification *)notification;
- (NSURL *)cacheDirectoryNamed:(NSString *)handle;
- (NSURL *)cachedDirectoryForFileUrl:(NSURL *)fileUrl;
- (NSSet *)contentsOfDocumentsDirectoryWithPathExtension:(NSString *)extension;
- (void)activate;
- (NSURL *)duplicateUrl:(NSURL *)urlToDupe;

+ (MACloudManager *)sharedManager;
+ (NSString *)filenameId:(NSUInteger)tag;
+ (NSString *)filenameId:(NSUInteger)tag extention:(NSString *)fileExtention;

@end
