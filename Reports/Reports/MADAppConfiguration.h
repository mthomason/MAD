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

extern NSString * const MADUpgradeInstalledSamples;
extern NSString * const MADUpgradeInstalledSamplesLondon;
extern NSString * const MADUpgradeInstalledSamplesMusic;
extern NSString * const MADUpgradeInstalledChinook;

extern NSString * const MADUpgradeInstalledChinook;
extern NSString * const MADUbiquityIdentifier;
extern NSString * const MTBundleIdMadDesigner;
extern NSString * const MTBundleIdMadViewer;

extern NSString * const MTGlobalBundleVersion;
extern NSString * const MTGlobalBundleShortVersion;
extern NSString * const MTGlobalBundleRev;

extern NSString * const MADUpgradeInstalledSamples;

extern NSString * const MADAppConfigurationUserDefaultsStorageOption;
extern NSString * const MADAppConfigurationUserDefaultsUbiquityToken;
extern NSString * const MADAppConfigurationUserDefaultsSamplesInstalled;

@class MADocument;

@interface MADAppConfiguration : NSObject

- (void)runHandlerOnFirstLaunch:(void (^)(void))firstLaunchHandler
             subsquientLaunches:(void (^)(void))subsequentLaunch
                    everyLaunch:(void (^)(void))everyLaunch;

@property (nonatomic, strong) MADFilesController *filesController;

@property (nonatomic, readonly, getter=isCloudAvailable) BOOL cloudAvailable;
@property (nonatomic, strong, readonly) NSUserDefaults *applicationUserDefaults;

+ (MADAppConfiguration *)mainInstance;
- (void)registerDefaultsFromSettingsBundle;

- (BOOL)sampleInstalled;
- (void)installedSample;

- (NSString *)applicationName;
- (NSString *)applicationNameSufixPart;

- (BOOL)isMadViewer;
- (BOOL)isMadDesigner;
- (NSString *)bundleId;
- (NSString *)bundleVersion;

- (NSString *)madDesigner;
- (NSString *)madViewer;
- (NSString *)madQuery;

/*- (id <MADFileCoordinator>)listsCoordinatorForCurrentConfigurationWithPathExtension:(NSString *)pathExtension firstQueryHandler:(void (^)(void))firstQueryHandler;
- (id <MADFileCoordinator>)listsCoordinatorForCurrentConfigurationWithLastPathComponent:(NSString *)lastPathComponent firstQueryHandler:(void (^)(void))firstQueryHandler;
- (MADFilesController *)filesControllerForCurrentConfigurationWithPathExtension:(NSString *)pathExtension firstQueryHandler:(void (^)(void))firstQueryHandler;
- (MADFilesController *)filesControllerForCurrentConfigurationWithLastPathComponent:(NSString *)lastPathComponent firstQueryHandler:(void (^)(void))firstQueryHandler;*/

+ (NSURL *)applicationBundleSampleDatabaseChinook;
+ (NSURL *)applicationSupportSampleDatabaseChinook;

@end

#endif
