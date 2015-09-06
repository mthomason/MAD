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

#import "MTApplicationInstance.h"

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

#import "UIColor+EverydayApps.h"
#import "UIDevice+Hack.h"
#import "NSParagraphStyle+CommonStyles.h"

#import "MADFileManager.h"

#import "MTNavigationController.h"
#import "MTNavigationControllerHideBottomBarUnlicensed.h"

#import "MADFilesController.h"
#import "MADLocalFileCoordinator.h"
#import "MADCloudFileCoordinator.h"
#import "MADMetaData.h"

#if MAD_DESIGNER
    #import "UIViewController+Designer.h"
#elif MAD_VIEWER
    #import "UIViewController+Viewer.h"
#endif

#ifndef MADWATCHKIT
    #import "MADToolboxNavigationController.h"
    #import "MTNavigationController.h"
    #import "MADTransparentPresentationController.h"
    #import "MADNavigationBarFixedSize.h"
#endif

NSString * const MADUpgradeInstalledChinook                         = @"MADUpgradeInstalledChinook";
NSString * const MADUpgradeInstalledSamples                         = @"MADUpgradeInstalledSamples";

NSString * const MADAppConfigurationUserDefaultsStorageOption       = @"MADAppConfigurationUserDefaultsStorageOption";
NSString * const MADAppConfigurationUserDefaultsUbiquityToken       = @"MADAppConfigurationUserDefaultsUbiquityToken";
NSString * const MADAppConfigurationUserDefaultsSamplesInstalled    = @"MADAppConfigurationUserDefaultsSamplesInstalled";

NSString * const MADIDUser                                          = @"MADIDUser";
NSString * const MADAppConfigurationApplicationGroupsPrimary        = @"group.everydayapps.mad.primary";

NSString * const MTApplicationIdMadDesigner                         = @"666001433";
NSString * const MTApplicationIdMadViewer                           = @"666003759";

NSString * const MTBundleIdMadDesigner                              = @"com.everydayapps.mad.designer";
NSString * const MTBundleIdMadViewer                                = @"com.everydayapps.mad.viewer";


NSString * const MTGlobalBundleVersion                              = @"8.0.47";
NSString * const MTGlobalBundleShortVersion                         = @"8.0.47";
NSString * const MTGlobalBundleRev                                  = @"1989";

NSString * const MTBundleDisplayName                                = @"CFBundleDisplayName";

NSString * const NSFetchedResultsCacheName                          = @"NSFetchedResultsCacheName";
NSString * const NSFetchedResultsCacheTables                        = @"NSFetchedResultsCacheTables";
NSString * const NSFetchedResultsCacheLinks                         = @"NSFetchedResultsCacheLinks";
NSString * const NSFetchedResultsCacheGroups                        = @"NSFetchedResultsCacheGroups";
NSString * const NSFetchedResultsCachePredicates                    = @"NSFetchedResultsCachePredicates";

const char * MADQueueAppInstance = "com.everydayapps.mad.designer.app";

@interface MTApplicationInstance ()
    <NSCoding>

@property (nonatomic, strong) NSURL *currentDocument;           //To support opening multiple documents
                                                                    //change this url to the url of the open
                                                                    //document.  This url will be key for the
                                                                    //documents array.

@property (nonatomic, strong, readwrite) MADFileManager *fileManager;
@property (nonatomic, strong) NSUserDefaults *applicationUserDefaults;
@property (nonatomic, readonly, getter=isFirstLaunch) BOOL firstLaunch;
@property (nonatomic, strong) dispatch_queue_t appInstaceQueue;

@end

@implementation MTApplicationInstance

static MTApplicationInstance *mainInstance;

+ (UIViewController *)initalViewController {
    return
        #ifndef MADWATCHKIT
            [UIViewController initalViewController];
        #else
            nil;
        #endif
}

- (instancetype)copyWithZone:(NSZone *)zone {
    return self;
}

+ (void)load { }

+ (instancetype)allocWithZone:(NSZone *)zone {
    return [super allocWithZone:zone];
}

+ (MTApplicationInstance *)mainInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mainInstance = [[self alloc] init];
    });
    return mainInstance;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {

    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder { }

- (instancetype)init {
    self = [super init];
    if (self) {
        
        dispatch_queue_t appInstaceQueue = dispatch_queue_create(MADQueueAppInstance, DISPATCH_QUEUE_SERIAL);
        self.appInstaceQueue = appInstaceQueue;
        
        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:MADAppConfigurationApplicationGroupsPrimary];
        self.applicationUserDefaults = defaults;
    
        [self registerDefaults];
        
        MADFileManager *openFiles = [[MADFileManager alloc] init];
        self.fileManager = openFiles;
        
#ifndef MADWATCHKIT
        // FIXME: Run these checks on app instance start...
        NSCAssert([MTGlobalBundleShortVersion isEqualToString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]], @"Whoa! CFBundleShortVersionString, bra.");
        NSCAssert([[MTApplicationInstance bundleId] isEqualToString:[[NSBundle mainBundle] bundleIdentifier]], @"Whoops! check the hard-coded bundle identifier!");
        NSCAssert([MTGlobalBundleRev isEqualToString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"MADRev"]], @"Check the hard-coded MADRev, dog!");
        NSCAssert([[MTApplicationInstance bundleId] isEqualToString:MTBundleIdMadDesigner] || [[MTApplicationInstance bundleId] isEqualToString:MTBundleIdMadViewer], @"Bundle ID is incorrect.");
        NSCAssert([[MTApplicationInstance bundleVersion] isEqualToString:MTGlobalBundleVersion], @"Bundle version is incorrect.");
        NSCAssert([MTGlobalBundleShortVersion isEqualToString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]], @"Bundle version is incorrect.");
#endif
        
    }
    return self;
}

#pragma mark - App settings

+ (NSString *)applicationNamePrefixPartFormat {
    return @"MAD %@";
}

+ (NSString *)applicationNameSufixPart {
    return [MTApplicationInstance isMadDesigner] ?  NSLocalizedString(@"Designer", @"Designer") :
                                                    NSLocalizedString(@"Viewer", @"Viewer");
}

+ (NSString *)applicationId {
    return [MTApplicationInstance isMadDesigner] ?
                                        MTApplicationIdMadDesigner :
                                        MTApplicationIdMadViewer;
}

+ (NSString *)bundleDisplayName {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:MTBundleDisplayName];;
}

+ (NSString *)applicationName {
    NSString *localizedPrefix = [MTApplicationInstance applicationNamePrefixPartFormat];
    NSString *localizedSuffix = [MTApplicationInstance applicationNameSufixPart];
    return [NSString stringWithFormat: localizedPrefix, localizedSuffix];
}

+ (NSString *)madDesigner {
    NSString *localizedPrefix = [MTApplicationInstance applicationNamePrefixPartFormat];
    NSString *localizedSuffix = NSLocalizedString(@"Designer", @"Designer");
    return [NSString stringWithFormat: localizedPrefix, localizedSuffix];
}

+ (NSString *)madViewer {
    NSString *localizedPrefix = [MTApplicationInstance applicationNamePrefixPartFormat];
    NSString *localizedSuffix = NSLocalizedString(@"Viewer", @"Viewer");
    return [NSString stringWithFormat: localizedPrefix, localizedSuffix];
}

+ (NSString *)madQuery {
    NSString *localizedPrefix = [MTApplicationInstance applicationNamePrefixPartFormat];
    NSString *localizedSuffix = NSLocalizedString(@"Query", @"Query");
    return [NSString stringWithFormat: localizedPrefix, localizedSuffix];
}

+ (BOOL)isMadViewer {
    static BOOL _isMadViewer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
        _isMadViewer = [bundleId isEqualToString:MTBundleIdMadViewer];
    });
    return _isMadViewer;
}

+ (BOOL)isMadDesigner {
    static BOOL _isMadDesigner;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
        _isMadDesigner = [bundleId isEqualToString:MTBundleIdMadDesigner];
    });
    return _isMadDesigner;
}

+ (NSString *)bundleId {
    static NSString *_bundleId;
    if ([MTApplicationInstance isMadDesigner]) {
        _bundleId = MTBundleIdMadDesigner;
    } else if ([MTApplicationInstance isMadViewer]) {
        _bundleId = MTBundleIdMadViewer;
    }
    return _bundleId;
}

+ (NSString *)bundleVersion {
    return MTGlobalBundleVersion;
}

+ (NSAttributedString *)localizedAttributedApplicationNameMadDesigner {
    NSString *title = [MTApplicationInstance madDesigner];
    return [MTApplicationInstance logoForTitle:title];
}

+ (NSAttributedString *)localizedAttributedApplicationNameMadViewer {
    NSString *title = [MTApplicationInstance madViewer];
    return [MTApplicationInstance logoForTitle:title];
}

+ (NSAttributedString *)localizedAttributedApplicationNameMadQuery {
    NSString *title = [MTApplicationInstance madQuery];
    return [MTApplicationInstance logoForTitle:title];
}
            
+ (NSAttributedString *)logoForTitle:(NSString *)title {
    
    
    NSParagraphStyle *paragraphStyle = [NSParagraphStyle titleBarStyle];
    NSMutableAttributedString *attributedStringMadDesigner = [[NSMutableAttributedString alloc] initWithString:title];
    NSInteger length = [[attributedStringMadDesigner string] length];
    
    UIFont *fonta = [UIFont fontWithName:@"HelveticaNeue-Light" size:20.0000f];
    UIFont *fontb = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0000f];
    NSRange range = NSMakeRange(0, length);
    UIColor *foregroundColor = [UIColor whiteColor];
    NSArray *components = [title componentsSeparatedByString:@" "];
    NSRange firstRange;
    NSRange secondRange;
    
    if (components.count == 2) {
        firstRange = [title rangeOfString:components[0]];
        secondRange = [title rangeOfString:components[1]];
    } else {
        firstRange = range; secondRange = range;
    }
    
    [attributedStringMadDesigner addAttribute: NSFontAttributeName
                                        value: fonta
                                        range: firstRange];
    
    [attributedStringMadDesigner addAttribute: NSFontAttributeName
                                        value: fontb
                                        range: secondRange];
    
    [attributedStringMadDesigner addAttribute: NSParagraphStyleAttributeName
                                        value: paragraphStyle
                                        range: range];
    
    [attributedStringMadDesigner addAttribute: NSForegroundColorAttributeName
                                        value: foregroundColor
                                        range: range];
    
    [attributedStringMadDesigner addAttribute:NSKernAttributeName
                                        value:[NSNull null]
                                        range:range];
    return attributedStringMadDesigner;
}

- (void)initalizeAppearance {
    UIColor *tintColorWhite = [UIColor tintColorWhite];
    NSDictionary *titleTextAttributes = @{ NSForegroundColorAttributeName : tintColorWhite};
    [[UITabBarItem appearance] setTitleTextAttributes: titleTextAttributes forState: UIControlStateNormal];    //Make tab bar buttons white
    
    #ifndef MADWATCHKIT
        [UINavigationBar appearanceWhenContainedIn:[MTNavigationController class], nil].barTintColor                = [UIColor tintColorBlue];
        [UINavigationBar appearanceWhenContainedIn:[MADToolboxNavigationController class], nil].barTintColor        = [UIColor clearColor];
        [UINavigationBar appearanceWhenContainedIn:[MADTransparentPresentationController class], nil].barTintColor  = [UIColor clearColor];
    #endif

    [UINavigationBar appearanceWhenContainedIn:[QLPreviewController class], nil].barTintColor                       = [UIColor tintColorAnalogous4];
    [UINavigationBar appearanceWhenContainedIn:[MFMailComposeViewController class], nil].barTintColor               = [UIColor tintColorAnalogous4];
    
    #ifndef MADWATCHKIT
        [UINavigationBar appearanceWhenContainedIn:[MTNavigationController class], nil].tintColor                   = tintColorWhite;
    #endif
    
    [UINavigationBar appearanceWhenContainedIn:[UIViewController class], nil].tintColor                             = tintColorWhite;
    [UINavigationBar appearanceWhenContainedIn:[UINavigationController class], nil].tintColor                       = tintColorWhite;
    [UINavigationBar appearanceWhenContainedIn:[QLPreviewController class], nil].tintColor                          = [UIColor tintColorRed];
    [UINavigationBar appearanceWhenContainedIn:[MFMailComposeViewController class], nil].tintColor                  = [UIColor tintColorRed];
    [UIBarButtonItem appearanceWhenContainedIn:[UIToolbar class], nil].tintColor                                    = tintColorWhite;
    [UIBarButtonItem appearance].tintColor                                                                          = tintColorWhite;
    [UILabel appearanceWhenContainedIn:[UITableViewCell class], nil].highlightedTextColor                           = [UIColor edaOrange];
    [UILabel appearanceWhenContainedIn:[UICollectionViewCell class], nil].highlightedTextColor                      = [UIColor edaOrange];
    [UIImageView appearanceWhenContainedIn:[UICollectionViewCell class], nil].tintColor                             = [UIColor edaOrange];
    [UISegmentedControl appearanceWhenContainedIn:[UINavigationBar class], nil].tintColor                           = tintColorWhite;
    
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

#pragma mark - Property Overrides

- (BOOL)isCloudAvailable {
    return [MADFilesController isCloudAvailable];
}

- (MADAppStorageState)storageState {
    return (MADAppStorageState) {
        .storageOption = self.storageOption,
        .accountDidChange = [self hasUbiquityIdentityChanged],
        .cloudAvailable = [MADFilesController isCloudAvailable]
    };
}

- (void)cleanupBeforeTerminate {
    [self.openDocument closeWithCompletionHandler:nil];
}

- (BOOL)sampleInstalled {
    return [self.applicationUserDefaults boolForKey:MADAppConfigurationUserDefaultsSamplesInstalled];
}

- (void)installedSample {
    [self.applicationUserDefaults setBool:YES forKey:MADAppConfigurationUserDefaultsSamplesInstalled];
}

- (MADAppStorage)storageOption {
    NSInteger value = [self.applicationUserDefaults integerForKey:MADAppConfigurationUserDefaultsStorageOption];
    return (MADAppStorage)value;
}

- (void)setStorageOption:(MADAppStorage)storageOption {
    [self.applicationUserDefaults setInteger:storageOption forKey:MADAppConfigurationUserDefaultsStorageOption];
    [self.applicationUserDefaults synchronize];
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

- (void)registerDefaults {
    NSUserDefaults *defaults = self.applicationUserDefaults;
    NSNumber *defaultStorage = @(MADAppStorageNotSet);
    NSNumber *defaultSamplesInstalled = @(NO);
    NSNumber *defaultReportsInstalled = @(NO);
    NSNumber *defaultChinookInstalled = @(NO);
    [defaults registerDefaults:@{MADUpgradeInstalledChinook: defaultChinookInstalled,
                                 MADUpgradeInstalledSamples : defaultReportsInstalled,
                                 MADAppConfigurationUserDefaultsSamplesInstalled : defaultSamplesInstalled,
                                 MADAppConfigurationUserDefaultsStorageOption: defaultStorage
                                 }];
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

#pragma mark - Ubiquity Identity Token Handling (Account Change Info)

- (BOOL)hasUbiquityIdentityChanged {
    BOOL hasChanged = NO;
    
    id<NSObject, NSCopying, NSCoding> currentToken = [NSFileManager defaultManager].ubiquityIdentityToken;
    id<NSObject, NSCopying, NSCoding> storedToken = [self storedUbiquityIdentityToken];
    
    BOOL currentTokenNilStoredNonNil = !currentToken && storedToken;
    BOOL storedTokenNilCurrentNonNil = !storedToken && currentToken;
    BOOL currentNotEqualStored = currentToken && storedToken && ![currentToken isEqual:storedToken];
    
    if (currentTokenNilStoredNonNil || storedTokenNilCurrentNonNil || currentNotEqualStored) {
        [self persistAccount];
        
        hasChanged = YES;
    }
    
    return hasChanged;
}

- (id<NSObject, NSCopying, NSCoding>)storedUbiquityIdentityToken {
    id<NSObject, NSCopying, NSCoding> storedToken = nil;
    
    // Determine if the iCloud account associated with this device has changed since the last time the user launched the app.
    NSData *ubiquityIdentityTokenArchive = [self.applicationUserDefaults objectForKey:MADAppConfigurationUserDefaultsUbiquityToken];
    
    if (ubiquityIdentityTokenArchive) {
        storedToken = [NSKeyedUnarchiver unarchiveObjectWithData:ubiquityIdentityTokenArchive];
    }
    
    return storedToken;
}

- (void)persistAccount {
    NSUserDefaults *defaults = self.applicationUserDefaults;
    id<NSObject, NSCopying, NSCoding> token = [NSFileManager defaultManager].ubiquityIdentityToken;
    
    if (token) {
        // The account has changed.
        NSData *ubiquityIdentityTokenArchive = [NSKeyedArchiver archivedDataWithRootObject:token];
        
        [defaults setObject:ubiquityIdentityTokenArchive forKey:MADAppConfigurationUserDefaultsUbiquityToken];
    }
    else {
        // There is no signed-in account.
        [defaults removeObjectForKey:MADAppConfigurationUserDefaultsUbiquityToken];
    }
}

#pragma mark - Document Operations

- (id<MADFileCoordinator>)listsCoordinatorForCurrentConfigurationWithPathExtension:(NSString *)pathExtension firstQueryHandler:(void (^)(void))firstQueryHandler {
    if ([MTApplicationInstance mainInstance].storageOption != MADAppStorageCloud) {
        // This will be called if the storage option is either `AAPLAppStorageLocal` or `AAPLAppStorageNotSet`.
        return [[MADLocalFileCoordinator alloc] initWithPathExtension:pathExtension identifier:MADIdentifierGroup firstQueryUpdateHandler:firstQueryHandler];
    }  else {
        return [[MADCloudFileCoordinator alloc] initWithPathExtension:pathExtension identifier:MADUbiquityIdentifier firstQueryUpdateHandler:firstQueryHandler];
    }
}

- (id<MADFileCoordinator>)listsCoordinatorForCurrentConfigurationWithLastPathComponent:(NSString *)lastPathComponent firstQueryHandler:(void (^)(void))firstQueryHandler {
    if ([MTApplicationInstance mainInstance].storageOption != MADAppStorageCloud) {
        // This will be called if the storage option is either `AAPLAppStorageLocal` or `AAPLAppStorageNotSet`.
        return [[MADLocalFileCoordinator alloc] initWithLastPathComponent:lastPathComponent identifier:MADIdentifierGroup firstQueryUpdateHandler:firstQueryHandler];
    } else {
        return [[MADCloudFileCoordinator alloc] initWithLastPathComponent:lastPathComponent identifier:MADUbiquityIdentifier firstQueryUpdateHandler:firstQueryHandler];
    }
}

- (MADFilesController *)filesControllerForCurrentConfigurationWithPathExtension:(NSString *)pathExtension firstQueryHandler:(void (^)(void))firstQueryHandler {

    id<MADFileCoordinator> fileCoordinator = [self listsCoordinatorForCurrentConfigurationWithPathExtension:pathExtension firstQueryHandler:firstQueryHandler];
    MADFilesController *filesController = [[MADFilesController alloc] initWithFileCoordinator:fileCoordinator
                                                                                delegateQueue:[NSOperationQueue mainQueue]
                                                                               sortComparator:^NSComparisonResult(MADMetaData *lhs, MADMetaData *rhs) {
                                                                                   return [lhs.name localizedCaseInsensitiveCompare:rhs.name];
                                                                               }];
    return filesController;
}

- (MADFilesController *)filesControllerForCurrentConfigurationWithLastPathComponent:(NSString *)lastPathComponent firstQueryHandler:(void (^)(void))firstQueryHandler {

    id<MADFileCoordinator> fileCoordinator = [self listsCoordinatorForCurrentConfigurationWithLastPathComponent:lastPathComponent firstQueryHandler:firstQueryHandler];
    MADFilesController *filesController = [[MADFilesController alloc] initWithFileCoordinator:fileCoordinator
                                                                                delegateQueue:[NSOperationQueue mainQueue]
                                                                               sortComparator:^NSComparisonResult(MADMetaData *lhs, MADMetaData *rhs) {
                                                                                   return [lhs.name localizedCaseInsensitiveCompare:rhs.name];
                                                                               }];
    return filesController;
}

#pragma mark - Document Operations

- (void)closeReport:(UITraitCollection *)traitCollectionForThumbnail completion:(void (^)(BOOL))completion {
    
    [[self openDocument] regenThumbnailWithTraits:traitCollectionForThumbnail];
    __weak MADocument *activeDocument = [self openDocument];
    if (activeDocument && activeDocument.documentState != UIDocumentStateClosed) {
        __weak MTApplicationInstance *weakself = self;
        [activeDocument closeWithCompletionHandler:^(BOOL success) {
            if (success) {
                weakself.reportState = MTReportStateClosed;
                [weakself.fileManager removeDocumentWithUrl:weakself.fileManager.openUrl];
            }
            completion(success);
        }];
    }
}

- (MADocument *)openDocument {
    if (self.reportState == MTReportStateOpen) return (MADocument *)self.fileManager.openDocument;
    else return nil;
}

+ (void)deleteCoreDataCache {
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheName];
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheTables];
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheLinks];
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheGroups];
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCachePredicates];
}

@end
