//
//  MTApplicaitonInstance.m
//  MAD
//
//  Created by Michael Thomason on 2/16/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADAppConfiguration.h"

#if MAD_DESIGNER || MADWATCHKIT
NSString * const MADUbiquityIdentifier                                  = @"iCloud.com.everydayapps.mad.designer";
#elif MAD_VIEWER
NSString * const MADUbiquityIdentifier                                  = @"iCloud.com.everydayapps.mad.viewer";
#endif

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <QuickLook/QuickLook.h>
#import <MessageUI/MessageUI.h>
#import "MAD.h"


#if MAD_DESIGNER
    #import "UIViewController+Designer.h"
#elif MAD_VIEWER
    #import "UIViewController+Viewer.h"
#endif

#ifndef MADWATCHKIT
    #import "MADToolboxNavigationController.h"
    #import "MADNavigationController.h"
    #import "MADTransparentPresentationController.h"
    #import "MADNavigationBarFixedSize.h"
#endif

#import "AppDelegate.h"

NSString * const MADUpgradeInstalledSamples                         = @"MADUpgradeInstalledSamples";
NSString * const MADUpgradeInstalledSamplesLondon                   = @"MADUpgradeInstalledSamplesLondon";
NSString * const MADUpgradeInstalledSamplesMusic                    = @"MADUpgradeInstalledSamplesMusic";
NSString * const MADUpgradeInstalledChinook                         = @"MADUpgradeInstalledChinook";

NSString * const MADAppConfigurationUserDefaultsSamplesInstalled    = @"MADAppConfigurationUserDefaultsSamplesInstalled";

NSString * const MADIDUser                                          = @"MADIDUser";
NSString * const MADAppConfigurationApplicationGroupsPrimary        = @"group.everydayapps.mad.primary";

NSString * const MTApplicationIdMadDesigner                         = @"666001433";
NSString * const MTApplicationIdMadViewer                           = @"666003759";

NSString * const MTBundleIdMadDesigner                              = @"com.everydayapps.mad.designer";
NSString * const MTBundleIdMadViewer                                = @"com.everydayapps.mad.viewer";


NSString * const MTGlobalBundleVersion                              = @"8.0.166";
NSString * const MTGlobalBundleShortVersion                         = @"8.0.166";
NSString * const MTGlobalBundleRev                                  = @"2108";

NSString * const MTBundleDisplayName                                = @"CFBundleDisplayName";

const char * MADQueueAppInstance = "com.everydayapps.mad.designer.app";

NSString * const MTSampleDatabaseChinook            = @"chinook";
NSString * const MTDocumentExtentionSqlite3         = @"sqlite3";


@interface MADAppConfiguration ()

@property (nonatomic, strong, readwrite) NSUserDefaults *applicationUserDefaults;
@property (nonatomic, strong) dispatch_queue_t appInstaceQueue;

@end

@implementation MADAppConfiguration

+ (MADAppConfiguration *)mainInstance {
    return ((AppDelegate *)[UIApplication sharedApplication].delegate).appConfiguration;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
        dispatch_queue_t appInstaceQueue = dispatch_queue_create(MADQueueAppInstance, DISPATCH_QUEUE_SERIAL);
        self.appInstaceQueue = appInstaceQueue;
        
        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:MADAppConfigurationApplicationGroupsPrimary];
        NSNumber *defaultSamplesInstalled = @(NO);
        NSNumber *defaultReportsInstalled = @(NO);
        NSNumber *defaultChinookInstalled = @(NO);
        NSDictionary *defaultsToRegister = @{MADUpgradeInstalledChinook: defaultChinookInstalled,
                                             MADUpgradeInstalledSamples : defaultReportsInstalled,
                                             MADAppConfigurationUserDefaultsSamplesInstalled : defaultSamplesInstalled,
                                             };
        [defaults registerDefaults:defaultsToRegister];
        self.applicationUserDefaults = defaults;
        
#ifndef MADWATCHKIT
        // FIXME: Run these checks on app instance start...
        NSCAssert([MTGlobalBundleShortVersion isEqualToString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]], @"Whoa! CFBundleShortVersionString, bra.");
        NSCAssert([[self bundleId] isEqualToString:[[NSBundle mainBundle] bundleIdentifier]], @"Whoops! check the hard-coded bundle identifier!");
        NSCAssert([MTGlobalBundleRev isEqualToString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"MADRev"]], @"Check the hard-coded MADRev, dog!");
        NSCAssert([[self bundleId] isEqualToString:MTBundleIdMadDesigner] || [[self bundleId] isEqualToString:MTBundleIdMadViewer], @"Bundle ID is incorrect.");
        NSCAssert([[self bundleVersion] isEqualToString:MTGlobalBundleVersion], @"Bundle version is incorrect.");
        NSCAssert([MTGlobalBundleShortVersion isEqualToString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]], @"Bundle version is incorrect.");
#endif
        
    }
    return self;
}

#pragma mark - App settings

- (NSString *)applicationNamePrefixPartFormat {
    return @"MAD %@";
}

- (NSString *)applicationNameSufixPart {
    return [self isMadDesigner] ?
                            NSLocalizedString(@"Designer", @"Designer") :
                            NSLocalizedString(@"Viewer", @"Viewer");
}

- (NSString *)applicationId {
    return [self isMadDesigner] ?
                            MTApplicationIdMadDesigner :
                            MTApplicationIdMadViewer;
}

- (NSString *)bundleDisplayName {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:MTBundleDisplayName];;
}

- (NSString *)applicationName {
    NSString *localizedPrefix = [self applicationNamePrefixPartFormat];
    NSString *localizedSuffix = [self applicationNameSufixPart];
    return [NSString stringWithFormat: localizedPrefix, localizedSuffix];
}

- (NSString *)madDesigner {
    NSString *localizedPrefix = [self applicationNamePrefixPartFormat];
    NSString *localizedSuffix = NSLocalizedString(@"Designer", @"Designer");
    return [NSString stringWithFormat: localizedPrefix, localizedSuffix];
}

- (NSString *)madViewer {
    NSString *localizedPrefix = [self applicationNamePrefixPartFormat];
    NSString *localizedSuffix = NSLocalizedString(@"Viewer", @"Viewer");
    return [NSString stringWithFormat: localizedPrefix, localizedSuffix];
}

- (NSString *)madQuery {
    NSString *localizedPrefix = [self applicationNamePrefixPartFormat];
    NSString *localizedSuffix = NSLocalizedString(@"Query", @"Query");
    return [NSString stringWithFormat: localizedPrefix, localizedSuffix];
}

- (BOOL)isMadViewer {
    static BOOL _isMadViewer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
        _isMadViewer = [bundleId isEqualToString:MTBundleIdMadViewer];
    });
    return _isMadViewer;
}

- (BOOL)isMadDesigner {
    static BOOL _isMadDesigner;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
        _isMadDesigner = [bundleId isEqualToString:MTBundleIdMadDesigner];
    });
    return _isMadDesigner;
}

- (NSString *)bundleId {
    static NSString *_bundleId;
    if ([self isMadDesigner]) {
        _bundleId = MTBundleIdMadDesigner;
    } else if ([self isMadViewer]) {
        _bundleId = MTBundleIdMadViewer;
    }
    return _bundleId;
}

- (NSString *)bundleVersion {
    return MTGlobalBundleVersion;
}

- (void)registerDefaultsFromSettingsBundle {
    
    dispatch_queue_t dipatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(dipatchQueue, ^{
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            dispatch_queue_t dipatchQueueBg = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
            dispatch_async(dipatchQueueBg, ^{
                
                NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
                [standardUserDefaults synchronize];
                
                NSString *pathSettingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
                NSAssert(pathSettingsBundle, @"Could not find Settings.bundle");
                NSString *pathRootPlist = [pathSettingsBundle stringByAppendingPathComponent:@"Root.plist"];
                
                
                NSDictionary *rootPlistSettings = [NSDictionary dictionaryWithContentsOfFile:pathRootPlist];
                NSArray *preferences = rootPlistSettings[@"PreferenceSpecifiers"];
                NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
                
                for (NSDictionary *prefSpecification in preferences)  {
                    NSString *key = prefSpecification[@"Key"];
                    if (key) {
                        
                        id currentObject = [standardUserDefaults objectForKey:key];
                        if (currentObject == nil) {
                            
                            id objectToSet = prefSpecification[@"DefaultValue"];
                            defaultsToRegister[key] = objectToSet;
                        }
                    }
                }
                
                [standardUserDefaults registerDefaults:defaultsToRegister];
                [standardUserDefaults synchronize];
                
            });
        });
    });
}

+ (NSURL *)applicationBundleSampleDatabaseChinook {
    return [[NSBundle mainBundle] URLForResource:MTSampleDatabaseChinook
                                   withExtension:MTDocumentExtentionSqlite3];
}

+ (NSURL *)applicationSupportSampleDatabaseChinook {
    NSURL *appSupportDirectory = [[NSFileManager defaultManager] localApplicationSupportDirectoryForGroupIdentifier:MADIdentifierGroup];
    NSString *filename = [NSString stringWithFormat:@"%@.%@", MTSampleDatabaseChinook, MTDocumentExtentionSqlite3];
    return [appSupportDirectory URLByAppendingPathComponent:filename isDirectory:NO];
}

#pragma mark - Property Overrides

- (NSString *)ubiquityIdentifier {
    return MADUbiquityIdentifier;
}

- (BOOL)isCloudAvailable {
    return [MADFilesController isCloudAvailable];
}

- (BOOL)sampleInstalled {
    return [self.applicationUserDefaults boolForKey:MADAppConfigurationUserDefaultsSamplesInstalled];
}

- (void)installedSample {
    [self.applicationUserDefaults setBool:YES forKey:MADAppConfigurationUserDefaultsSamplesInstalled];
}

- (BOOL)isFirstLaunch {
    BOOL firstLaunch = [self.applicationUserDefaults stringForKey:MADIDUser] == nil;
    if (firstLaunch) {
        dispatch_async(self.appInstaceQueue, ^{
            NSUUID *uuid = [NSUUID UUID];
            [self.applicationUserDefaults setObject:uuid.UUIDString forKey:MADIDUser];
            [self.applicationUserDefaults synchronize];
        });
    }
    return firstLaunch;
}

- (void)runHandlerOnFirstLaunch:(void (^)(void))firstLaunchHandler
             subsquientLaunches:(void (^)(void))subsequentLaunch
                    everyLaunch:(void (^)(void))everyLaunch {
    if (self.isFirstLaunch) {
        firstLaunchHandler();
    } else {
        subsequentLaunch();
    }
    everyLaunch();
}

@end
