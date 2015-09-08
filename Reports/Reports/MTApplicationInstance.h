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

@class MADFilesController, UITraitCollection, UIViewController;
@protocol MADFileCoordinator;

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

@class MADocument;

@interface MTApplicationInstance : NSObject

+ (MTApplicationInstance *)mainInstance;

+ (UIViewController *)initalViewController;

- (void)runHandlerOnFirstLaunch:(void (^)(void))firstLaunchHandler
             subsquientLaunches:(void (^)(void))subsequentLaunch
                    everyLaunch:(void (^)(void))everyLaunch;

@property (nonatomic, strong) MADFilesController *filesController;

@property (nonatomic, readonly) MADAppStorageState storageState;
@property (nonatomic, assign) MADAppStorage storageOption;

@property (nonatomic, readonly, getter=isCloudAvailable) BOOL cloudAvailable;

- (void)initalizeAppearance;
- (void)registerDefaultsFromSettingsBundle;

- (BOOL)sampleInstalled;
- (void)installedSample;

+ (NSString *)applicationName;

+ (NSString *)applicationNameSufixPart;

+ (BOOL)isMadViewer;
+ (BOOL)isMadDesigner;
+ (NSString *)bundleId;
+ (NSString *)bundleVersion;
+ (void)deleteCoreDataCache;

+ (NSString *)madDesigner;
+ (NSString *)madViewer;
+ (NSString *)madQuery;

+ (NSString *)bundleDisplayName;

- (id<MADFileCoordinator>)listsCoordinatorForCurrentConfigurationWithPathExtension:(NSString *)pathExtension firstQueryHandler:(void (^)(void))firstQueryHandler;
- (id<MADFileCoordinator>)listsCoordinatorForCurrentConfigurationWithLastPathComponent:(NSString *)lastPathComponent firstQueryHandler:(void (^)(void))firstQueryHandler;
- (MADFilesController *)filesControllerForCurrentConfigurationWithPathExtension:(NSString *)pathExtension firstQueryHandler:(void (^)(void))firstQueryHandler;
- (MADFilesController *)filesControllerForCurrentConfigurationWithLastPathComponent:(NSString *)lastPathComponent firstQueryHandler:(void (^)(void))firstQueryHandler;

@end

#endif
