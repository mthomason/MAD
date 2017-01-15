//
//  MADFileManagerViewController.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/12/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADFileLocationManager.h"

#import <UIKit/UIViewController.h>
#import <UIKit/UIAlertController.h>

#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADAppDelegate.h>

#import <MADCocoaExtensions/MADAlertController.h>

#import <MADFileManager/MADFileLocationManagerDelegate.h>
#import <MADFileManager/MADStorageState.h>
#import <MADFileManager/MADFilesController.h>
#import <MADFileManager/MADFileUtilities.h>
#import <MADFileManager/MADFileCoordinator.h>
#import <MADFileManager/MADFileLocationManagerDelegate.h>
#import <MADFileManager/MADAppStorageOption.h>

static NSString * const MADAppConfigurationUserDefaultsUbiquityToken       = @"MADAppConfigurationUserDefaultsUbiquityToken";
static NSString * const MADAppConfigurationUserDefaultsStorageOption       = @"MADAppConfigurationUserDefaultsStorageOption";
static NSString * const MADFirstLaunch                                     = @"MADFirstLaunch";
static NSString * const MADTitleButtonLocalOnly        = @"Local Only";
static NSString * const MADTitleButtonCloud            = @"iCloud";
static NSString * const MADTitleChooseStorageOptions   = @"Choose Storage Option";
static NSString * const MADMessageChooseStorageOptions = @"Do you want to store documents in iCloud or "
                                                            @"only on this device?";

@interface MADAlertControllerPromptStorage : UIAlertController

+ (instancetype)newAlertControllerPromptStorage:(void (^)())handlerLocal
                                          cloud:(void (^)())handlerCloud;

@end

@implementation MADAlertControllerPromptStorage

+ (instancetype)newAlertControllerPromptStorage:(void (^)())handlerLocal
                                          cloud:(void (^)())handlerCloud {

    NSString *title, *message, *localOnlyActionTitle, *cloudActionTitle;
    UIAlertController *storageController;
    UIAlertAction *option;
    title = NSLocalizedString(MADTitleChooseStorageOptions, MADTitleChooseStorageOptions),
    message = NSLocalizedString(MADMessageChooseStorageOptions, MADMessageChooseStorageOptions),
    localOnlyActionTitle = NSLocalizedString(MADTitleButtonLocalOnly, MADTitleButtonLocalOnly),
    cloudActionTitle = NSLocalizedString(MADTitleButtonCloud, MADTitleButtonCloud);
    
    storageController = [UIAlertController alertControllerWithTitle: title
                                                            message: message
                                                     preferredStyle: UIAlertControllerStyleAlert];
    
    option = [UIAlertAction actionWithTitle: localOnlyActionTitle
                                      style: UIAlertActionStyleDefault
                                    handler: handlerLocal];
    [storageController addAction:option];
    
    option = [UIAlertAction actionWithTitle: cloudActionTitle
                                      style: UIAlertActionStyleDefault
                                    handler: handlerCloud];
    [storageController addAction:option];

    return storageController;
}


@end

@interface MADFileLocationManager ()

    @property (nonatomic, readwrite, strong) MADFilesController *filesController;
    @property (nonatomic, readwrite, assign) BOOL getUserCloudPrefsFirstCall;
    @property (nonatomic, readonly)          BOOL isFirstLaunch;

@end

@implementation MADFileLocationManager

- (instancetype)init {

    if (self = [super init]) {
        //NSLog(@"%s", __PRETTY_FUNCTION__);

        NSNumber *yes = @YES;
        NSNumber *notSet = [[NSNumber alloc] initWithInteger: MADAppStorageNotSet];
        NSDictionary *defaultValues;
        defaultValues = [[NSDictionary alloc] initWithObjectsAndKeys:
                                        yes,    MADFirstLaunch,
                                        notSet, MADAppConfigurationUserDefaultsStorageOption, nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
        self.getUserCloudPrefsFirstCall = YES;
    }
    return self;
}

#pragma mark - Ubiquity Identity Token Handling (Account Change)

- (BOOL)hasUbiquityIdentityChanged {
    //NSLog(@"%s", __PRETTY_FUNCTION__);

    BOOL hasChanged = NO;
    
    id <NSObject, NSCopying, NSCoding> currentToken,
                                       storedToken;
    
    currentToken = [[NSFileManager defaultManager].ubiquityIdentityToken copyWithZone:nil];
    storedToken = [self copyStoredUbiquityIdentityToken];
    
    if ((!currentToken && storedToken) ||
        (!storedToken && currentToken) ||
        (currentToken && storedToken && ![currentToken isEqual:storedToken])) {
        
        [self persistAccount];
        
        hasChanged = YES;
    }
    
    return hasChanged;
}

- (id<NSObject, NSCopying, NSCoding>)copyStoredUbiquityIdentityToken {
    //NSLog(@"%s", __PRETTY_FUNCTION__);

    id <NSObject, NSCopying, NSCoding> storedToken = nil;
    
    // Determine if the iCloud account associated with this device has changed since the last
    //    time the user launched the app.
    NSData *ubiquityIdentityTokenArchive;
    ubiquityIdentityTokenArchive = [[NSUserDefaults standardUserDefaults]
                                    objectForKey:MADAppConfigurationUserDefaultsUbiquityToken];
    
    if (ubiquityIdentityTokenArchive) {
        storedToken = [NSKeyedUnarchiver unarchiveObjectWithData:ubiquityIdentityTokenArchive];
    }
    
    return storedToken;
}

- (void)persistAccount {
    //NSLog(@"\t%s", __PRETTY_FUNCTION__);
    
    id<NSObject, NSCopying, NSCoding> token;
    token = [[NSFileManager defaultManager].ubiquityIdentityToken copyWithZone:nil];
    if (token) {
        NSData *ubiquityIdentityTokenArchive;
        ubiquityIdentityTokenArchive = [NSKeyedArchiver archivedDataWithRootObject:token];
        [[NSUserDefaults standardUserDefaults]
                                        setObject: ubiquityIdentityTokenArchive
                                           forKey: MADAppConfigurationUserDefaultsUbiquityToken];
    } else {
        [[NSUserDefaults standardUserDefaults]
                                removeObjectForKey:MADAppConfigurationUserDefaultsUbiquityToken];
    }
}

#pragma mark - Overrides

+ (BOOL)StorageOptionsInitialized {
    NSString *MADAppConfigurationUserDefaultsStorageOptionSet = @"MADAppConfigurationUserDefaultsStorageOptionSet";
    return [[NSUserDefaults standardUserDefaults] boolForKey:MADAppConfigurationUserDefaultsStorageOptionSet];
}

+ (NSInteger)StorageOptionUserDefaults {
    return [[NSUserDefaults standardUserDefaults] integerForKey:MADAppConfigurationUserDefaultsStorageOption];
}

+ (MADAppStorage)StorageOption {
    MADAppStorage storageOption;
    storageOption = [self StorageOptionsInitialized] ? [self StorageOptionUserDefaults] :
                                                      MADAppStorageStateUnknown;
    return storageOption;
}

+ (void)setStorageOption:(MADAppStorage)storageOption {
    [[NSUserDefaults standardUserDefaults] setInteger: storageOption
                                               forKey: MADAppConfigurationUserDefaultsStorageOption];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Convenience

- (BOOL)isFirstLaunch {
    //NSLog(@"%s", __PRETTY_FUNCTION__);

    BOOL isFirstLaunch = [[NSUserDefaults standardUserDefaults] boolForKey:MADFirstLaunch] ?
                                                                                    YES : NO;
    if (isFirstLaunch) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:MADFirstLaunch];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return isFirstLaunch;
}

- (void)setupFileStorageLocationsForCloud {
    //NSLog(@"%s", __PRETTY_FUNCTION__);

    UIViewController <MADFileLocationManagerDelegate> *safeDelegate = _delegate;

    NSString *ubiquityIdentifier = [safeDelegate ubiquityIdentifier].copy;
    NSString *groupIdentifier = [safeDelegate groupIdentifier].copy;
    
    UIViewController <MADFileLocationManagerDelegate> * __weak weakDelegate = safeDelegate;
    typeof(self) __weak weakself = self;
    
    [MADFilesController getFileStorageLocationsForUbiquityIdentifier: ubiquityIdentifier
                                                     groupIdentifier: groupIdentifier
                                                               delay: ^ {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            UIViewController <MADFileLocationManagerDelegate> *delegate = weakDelegate;
            if (delegate) {
                [delegate startLongRunningActivity];
            }
        }];
        
    } completion:^(BOOL cloudAvailable, NSURL *documents, NSURL *data) {
        
        MADFileLocationManager *sself = weakself;
        MADAppStorage storageOption = cloudAvailable ? MADAppStorageCloud : MADAppStorageLocal;
        [self.class setStorageOption: storageOption];
        
        [sself configureFilesController: NO storageOptionChangeHandler: nil];
        
        UIViewController <MADFileLocationManagerDelegate> * __weak wdelegate = sself.delegate;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            UIViewController <MADFileLocationManagerDelegate> * sdelegate = wdelegate;
            if (sdelegate) {
                [sdelegate completedLongRunningActivity];
            }
            
        }];
        
    }];
}

- (void)setupFileStorageLocationsForLocal {
    //NSLog(@"%s", __PRETTY_FUNCTION__);

    id <MADFileLocationManagerDelegate> safedelegate;
    safedelegate = _delegate;
    
    NSString *groupIdentifier = [safedelegate groupIdentifier].copy;
    NSString *ubiquityIdentifier = [safedelegate ubiquityIdentifier].copy;
    NSString *fileExtention = [safedelegate fileExtention].copy;

    id <MADFileLocationManagerDelegate> __weak wdelegate;
    wdelegate = safedelegate;
    
    typeof(self) __weak weakself = self;

    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        //NSLog(@"%s", __PRETTY_FUNCTION__);
        
        id <MADFileLocationManagerDelegate> delegate;
        delegate = wdelegate;
        
        MADFileLocationManager *strongself;
        strongself = weakself;
        
        if (delegate == nil || strongself == nil) return;
        
        MADFileLocationManager __weak *wself = strongself;
        
        void (^handlerLocal)();
        void (^handlerCloud)();
        
        handlerLocal = ^ {
            MADFileLocationManager *sself = wself;
            if (sself) {
                [MADFileLocationManager setStorageOption:MADAppStorageLocal];
                [sself configureFilesController: NO storageOptionChangeHandler: nil];
            }
        };

        handlerCloud = ^{
            
            MADFileLocationManager *sself = wself;
            if (!sself) return;
            
            [MADFileLocationManager setStorageOption:MADAppStorageCloud];
            
            void (^handleStorageOptionChanged)(void);
            handleStorageOptionChanged = ^{
                [MADFileUtilities migrateLocalFiles: groupIdentifier
                                            toCloud: ubiquityIdentifier
                                          extension: fileExtention];
            };
            
            [sself configureFilesController: NO
                 storageOptionChangeHandler: handleStorageOptionChanged];
        };
        
        id prompt = [MADAlertControllerPromptStorage newAlertControllerPromptStorage: handlerLocal
                                                                               cloud: handlerCloud];
        
        UIViewController *presentingController = delegate.presentingController;
        [presentingController presentViewController:prompt animated:YES completion:nil];
        
    }];
}

- (void)getUserCloudPrefs {
    //NSLog(@"%s", __PRETTY_FUNCTION__);

    if (self.isFirstLaunch || self.getUserCloudPrefsFirstCall == NO) {

        self.getUserCloudPrefsFirstCall = NO;

        MADStorageState *storageState;
        MADAppStorage storageOption = [self.class StorageOption];
        BOOL hasUbiquityIdentityChanged = [self hasUbiquityIdentityChanged];
        BOOL isCloudReadilyAvailable = [MADFilesController isCloudReadilyAvailable];
        
        storageState = [MADStorageState newStorageStateWithStorageOption: storageOption
                                              hasUbiquityIdentityChanged: hasUbiquityIdentityChanged
                                                 isCloudReadilyAvailable: isCloudReadilyAvailable];
        if (storageState.cloudAvailable) {
            
            if (storageState.storageOption == MADAppStorageCloud) {
                
                [self setupFileStorageLocationsForCloud];
                
            } else if (storageState.storageOption == MADAppStorageLocal ||
                       storageState.storageOption == MADAppStorageNotSet) {

                [self setupFileStorageLocationsForLocal];

            }
            
        } else {
        
            if (storageState.storageOption == MADAppStorageCloud) {
                [self.class setStorageOption: MADAppStorageNotSet];
            }
            
            [self configureFilesController: NO storageOptionChangeHandler: nil];
            
        }
    } else {
        self.getUserCloudPrefsFirstCall = NO;
        [self getUserCloudPrefsSubsquient];
    }
}

- (void)getUserCloudPrefsSubsquient {
    //NSLog(@"%s", __PRETTY_FUNCTION__);

    MADStorageState *storageState;
    storageState = [MADStorageState newStorageStateWithStorageOption: [self.class StorageOption]
                                          hasUbiquityIdentityChanged: [self hasUbiquityIdentityChanged]
                                             isCloudReadilyAvailable: [MADFilesController isCloudReadilyAvailable]];
    if (storageState.accountDidChange) {
        
        switch (storageState.storageOption) {
        
            case MADAppStorageCloud: {
            
                [self.class setStorageOption: MADAppStorageNotSet];
                
                id <MADFileLocationManagerDelegate> delegate;
                delegate = _delegate;
                
                if ([delegate respondsToSelector:@selector(didDisconnectFromCloud:)]) {
                    [delegate didDisconnectFromCloud:self];
                }
                
                break;
            }

            case MADAppStorageLocal:
            case MADAppStorageNotSet:
            default:
                [self getUserCloudPrefs];
                break;

        }
        
        
    } else {

        if (storageState.storageOption == MADAppStorageNotSet) {

            [self getUserCloudPrefs];

        } else {

            [self configureFilesController: NO storageOptionChangeHandler: nil];

        }

    }
}

- (void)configureFilesController: (BOOL)accountChanged
      storageOptionChangeHandler: (void (^)(void))storageChangedHandler {

    if (self.filesController != nil && !accountChanged) return;

    id <MADFileLocationManagerDelegate> delegate;
    delegate = _delegate;
    
    if (!_filesController) {
        
        NSString *identifier = [self copyIdentifierForStorageOption];
        NSString *fileExtention = [delegate fileExtention].copy;
        MADAppStorage storageOption = [self.class StorageOption];

        id filesController;
        filesController = [MADFilesController newFilesControllerWithPathExtension: fileExtention
                                                                    storageOption: storageOption
                                                                       identifier: identifier
                                                                firstQueryHandler: storageChangedHandler];
        [delegate didConfigureFilesController: filesController];
        [filesController startSearching];
        _filesController = filesController;
        
    } else if (accountChanged) {
        NSString *identifier = [self copyIdentifierForStorageOption];
        NSString *fileExtention = [delegate fileExtention].copy;
        MADAppStorage storageOption = [self.class StorageOption];
        id fc = [MADFileCoordinator newFileCoordinatorWithPathExtension: fileExtention
                                                          storageOption: storageOption
                                                             identifier: identifier
                                                      firstQueryHandler: storageChangedHandler];
        _filesController.fileCoordinator = fc;
        [delegate didConfigureFilesController: _filesController];
    }

}

- (NSString *)copyIdentifierForStorageOption {

    //NSLog(@"%s", __PRETTY_FUNCTION__);

    id <MADFileLocationManagerDelegate> delegate = _delegate;

    NSString *groupIdentifer;
    groupIdentifer = [self.class StorageOption] != MADAppStorageCloud ? [delegate groupIdentifier] :
                                                                        [delegate ubiquityIdentifier];
    return groupIdentifer.copy;
}

/*
- (id)debugQuickLookObject {
    NSMutableString *debug = [[NSMutableString alloc] init];
    NSString *classname = NSStringFromClass([self class]);
    id uppercaseClassname = [classname uppercaseString];
    [debug appendFormat:@"--%@--\n", uppercaseClassname];
    [debug appendFormat:@"Is first launch:       %@", self.isFirstLaunch ? @"Yes" : @"No"];
    [debug appendFormat:@"Get user cloud prefs:  %@", self.getUserCloudPrefsFirstCall ? @"Yes" : @"No"];
    [debug appendFormat:@"\tDelegate:            %@\n", self.delegate];
    [debug appendFormat:@"\tFiles controller:    %@\n", self.filesController];
    return debug;
}
*/

@end
