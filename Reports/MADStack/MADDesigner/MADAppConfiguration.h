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
#import <MADFileManager/MADFileManager.h>

@class MADFilesController, UITraitCollection, UIViewController;
@protocol MADFileCoordinator;

extern NSString * const MADUpgradeInstalledSamples;
extern NSString * const MADUpgradeInstalledSamplesLondon;
extern NSString * const MADUpgradeInstalledSamplesMusic;
extern NSString * const MADUpgradeInstalledChinook;

extern NSString * const MADUpgradeInstalledChinook;
extern NSString * const MTBundleIdMadDesigner;
extern NSString * const MTBundleIdMadViewer;

extern NSString * const MTGlobalBundleVersion;
extern NSString * const MTGlobalBundleShortVersion;
extern NSString * const MTGlobalBundleRev;

extern NSString * const MADUpgradeInstalledSamples;

@class MADocument;

@interface MADAppConfiguration : NSObject

- (void)runHandlerOnFirstLaunch:(void (^)(void))firstLaunchHandler
             subsquientLaunches:(void (^)(void))subsequentLaunch
                    everyLaunch:(void (^)(void))everyLaunch;

@property (nonatomic, readonly, getter=isCloudAvailable) BOOL cloudAvailable;
@property (nonatomic, strong, readonly) NSUserDefaults *applicationUserDefaults;

//+ (MADAppConfiguration *)mainInstance;
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
- (NSString *)madQuery;

- (BOOL)isFirstLaunch;

+ (NSURL *)applicationBundleSampleDatabaseChinook;
+ (NSURL *)applicationSupportSampleDatabaseChinook;

@end

#endif
