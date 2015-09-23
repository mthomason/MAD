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

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <QuickLook/QuickLook.h>
#import <MessageUI/MessageUI.h>
#import <MAD/MADConstants.h>
#import <MADFoundation/MADApplicationProtocol.h>
#import <MADFoundation/MADAppDelegate.h>
#import <MADFoundation/UIApplication+MADAppDelegate.h>

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

NSString * const MTBundleIdMadDesigner                              = @"com.everydayapps.mad.designer";
NSString * const MTBundleIdMadViewer                                = @"com.everydayapps.mad.viewer";


NSString * const MTGlobalBundleVersion                              = @"8.0.271";
NSString * const MTGlobalBundleShortVersion                         = @"8.0.271";
NSString * const MTGlobalBundleRev                                  = @"2213";

const char * MADQueueAppInstance = "com.everydayapps.mad.designer.app";

NSString * const MTSampleDatabaseChinook            = @"chinook";
NSString * const MTDocumentExtentionSqlite3         = @"sqlite3";


@interface MADAppConfiguration ()

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
        
#ifndef MADWATCHKIT
        // FIXME: Run these checks on app instance start...
        NSCAssert([MTGlobalBundleShortVersion isEqualToString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]], @"Whoa! CFBundleShortVersionString, bra.");
        //NSCAssert([[self bundleId] isEqualToString:[[NSBundle mainBundle] bundleIdentifier]], @"Whoops! check the hard-coded bundle identifier!");
        NSCAssert([MTGlobalBundleRev isEqualToString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"MADRev"]], @"Check the hard-coded MADRev, dog!");
        //NSCAssert([[self bundleId] isEqualToString:MTBundleIdMadDesigner] || [[self bundleId] isEqualToString:MTBundleIdMadViewer], @"Bundle ID is incorrect.");
        NSCAssert([[self bundleVersion] isEqualToString:MTGlobalBundleVersion], @"Bundle version is incorrect.");
        NSCAssert([MTGlobalBundleShortVersion isEqualToString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]], @"Bundle version is incorrect.");
#endif
        
    }
    return self;
}

#pragma mark - App settings

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
    MADAppDelegate delegate = [UIApplication AppDelegate];
    NSURL *appSupportDirectory = [[NSFileManager defaultManager] localApplicationSupportDirectoryForGroupIdentifier:[delegate groupIdentifier]];
    NSString *filename = [NSString stringWithFormat:@"%@.%@", MTSampleDatabaseChinook, MTDocumentExtentionSqlite3];
    return [appSupportDirectory URLByAppendingPathComponent:filename isDirectory:NO];
}

#pragma mark - Property Overrides

- (BOOL)isCloudAvailable {
    return [MADFilesController isCloudAvailable];
}


@end
