//
//  MTApplicaitonInstance.h
//  MAD
//
//  Created by Michael Thomason on 2/16/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTApplicationInstance_h
#define Reports_MTApplicationInstance_h

#import <Foundation/Foundation.h>

@class MADFilesController, UITraitCollection;
@protocol MADFileCoordinator;

typedef NS_ENUM(NSUInteger, MTReportState) {
	MTReportStateOpen = 0,
	MTReportStateClosed
};

typedef NS_ENUM(NSUInteger, MADAppStorage) {
    MADAppStorageNotSet = 0,
    MADAppStorageCloud,
    MADAppStorageLocal
};

typedef struct MADAppStorageState {
    MADAppStorage storageOption;
    BOOL accountDidChange;
    BOOL cloudAvailable;
} MADAppStorageState;

extern NSString * const MADUbiquityIdentifier;
extern NSString * const MTBundleIdMadDesigner;
extern NSString * const MTBundleIdMadViewer;

extern NSString * const MTGlobalBundleVersion;
extern NSString * const MTGlobalBundleShortVersion;
extern NSString * const MTGlobalBundleRev;

extern NSString * const MADUpgradeInstalledChinook;
extern NSString * const MADUpgradeInstalledSamples;

@class MADocument, MTReportDesigner, MTReportViewer, MTQueryDesigner, MADFileManager;

@interface MTApplicationInstance : NSObject

+ (MTApplicationInstance *)mainInstance;

- (void)runHandlerOnFirstLaunch:(void (^)(void))firstLaunchHandler
             subsquientLaunches:(void (^)(void))subsequentLaunch;

@property (nonatomic, assign) MTReportState reportState;

@property (nonatomic, strong) MADFilesController *filesController;

//@property (nonatomic, strong, readonly) MTUser *user;

@property (nonatomic, strong, readonly) MTReportDesigner *reportDesigner;
@property (nonatomic, strong, readonly) MTReportViewer *reportViewer;
@property (nonatomic, strong, readonly) MTQueryDesigner *queryDesigner;

@property (nonatomic, strong, readonly) MADFileManager *fileManager;

@property (nonatomic, readonly) MADAppStorageState storageState;
@property (nonatomic, assign) MADAppStorage storageOption;

@property (nonatomic, readonly, getter=isCloudAvailable) BOOL cloudAvailable;
@property (nonatomic, strong, readonly) MADocument *openDocument;

- (void)initalizeAppearance;
- (void)registerDefaultsFromSettingsBundle;

- (BOOL)sampleInstalled;
- (void)installedSample;

- (void)cleanupBeforeTerminate;

+ (NSString *)applicationName;
+ (NSAttributedString *)localizedAttributedApplicationNameMadDesigner;
+ (NSAttributedString *)localizedAttributedApplicationNameMadViewer;
+ (NSAttributedString *)localizedAttributedApplicationNameMadQuery;

+ (NSString *)applicationNameSufixPart;

+ (BOOL)isMadViewer;
+ (BOOL)isMadDesigner;
+ (NSString *)bundleId;
+ (NSString *)bundleVersion;
+ (void)deleteCoreDataCache;
+ (NSString *)storyboardName;

+ (NSString *)madDesigner;
+ (NSString *)madViewer;
+ (NSString *)madQuery;

+ (NSString *)bundleDisplayName;

- (void)closeReport:(UITraitCollection *)traitCollectionForThumbnail completion:(void (^)(BOOL))completion;

- (id<MADFileCoordinator>)listsCoordinatorForCurrentConfigurationWithPathExtension:(NSString *)pathExtension firstQueryHandler:(void (^)(void))firstQueryHandler;
- (id<MADFileCoordinator>)listsCoordinatorForCurrentConfigurationWithLastPathComponent:(NSString *)lastPathComponent firstQueryHandler:(void (^)(void))firstQueryHandler;
- (MADFilesController *)filesControllerForCurrentConfigurationWithPathExtension:(NSString *)pathExtension firstQueryHandler:(void (^)(void))firstQueryHandler;
- (MADFilesController *)filesControllerForCurrentConfigurationWithLastPathComponent:(NSString *)lastPathComponent firstQueryHandler:(void (^)(void))firstQueryHandler;

@end

#endif
