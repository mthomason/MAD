//
//  MADFileManagerViewController.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/12/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADFileLocationManager.h"
#import <MADCocoaExtensions/UIAlertController+Constructors.h>
#import <MADFileManager/MADStorageState.h>
#import <MADFileManager/MADFilesController.h>
#import <MADFileManager/MADFileUtilities.h>
#import <MADFileManager/MADFileCoordinator.h>
#import <UIKit/UIViewController.h>

static NSString * const MADAppConfigurationUserDefaultsUbiquityToken       = @"MADAppConfigurationUserDefaultsUbiquityToken";
static NSString * const MADAppConfigurationUserDefaultsStorageOption       = @"MADAppConfigurationUserDefaultsStorageOption";
static NSString * const MADFirstLaunch                                     = @"MADFirstLaunch";

@interface MADFileLocationManager ()

    @property (nonatomic, strong, readwrite) MADFilesController *filesController;
    @property (nonatomic, assign) bool getUserCloudPrefsFirstCall;
    @property (readonly) bool isFirstLaunch;

@end

@implementation MADFileLocationManager

- (instancetype)init {

    if (self = [super init]) {
        NSLog(@"%s", __PRETTY_FUNCTION__);

        NSNumber *yes = @YES;
        NSNumber *notSet = [[NSNumber alloc] initWithShort: MADAppStorageNotSet];
        NSDictionary *defaultValues;
        defaultValues = [[NSDictionary alloc] initWithObjectsAndKeys:
                                        yes,    MADFirstLaunch,
                                        notSet, MADAppConfigurationUserDefaultsStorageOption, nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
        self.getUserCloudPrefsFirstCall = true;
    }
    return self;
}

#pragma mark - Ubiquity Identity Token Handling (Account Change)

- (BOOL)hasUbiquityIdentityChanged {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    BOOL hasChanged = NO;
    
    id <NSObject, NSCopying, NSCoding> currentToken,
                                       storedToken;
    
    currentToken = [[NSFileManager defaultManager].ubiquityIdentityToken copyWithZone:nil];
    storedToken = [self copyStoredUbiquityIdentityToken];
    
    bool currentTokenNilStoredNonNil = !currentToken && storedToken;
    bool storedTokenNilCurrentNonNil = !storedToken && currentToken;
    bool currentNotEqualStored = currentToken && storedToken && ![currentToken isEqual:storedToken];
    
    if (currentTokenNilStoredNonNil || storedTokenNilCurrentNonNil || currentNotEqualStored) {
        [self persistAccount];
        hasChanged = YES;
    }
    
    return hasChanged;
}

- (id<NSObject, NSCopying, NSCoding>)copyStoredUbiquityIdentityToken {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    id<NSObject, NSCopying, NSCoding> storedToken = nil;
    
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
    NSLog(@"\t%s", __PRETTY_FUNCTION__);
    
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

- (MADAppStorage)storageOption {
    NSLog(@"\t%s", __PRETTY_FUNCTION__);
    return (MADAppStorage)[[NSUserDefaults standardUserDefaults]
                                    integerForKey:MADAppConfigurationUserDefaultsStorageOption];
}

- (void)setStorageOption:(MADAppStorage)storageOption {
    NSLog(@"\t%s", __PRETTY_FUNCTION__);
    [[NSUserDefaults standardUserDefaults] setInteger: storageOption
                                               forKey: MADAppConfigurationUserDefaultsStorageOption];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Convenience

- (bool)isFirstLaunch {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    bool isFirstLaunch = [[NSUserDefaults standardUserDefaults] boolForKey:MADFirstLaunch] ?
                                                                                    true : false;
    if (isFirstLaunch) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:MADFirstLaunch];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return isFirstLaunch;
}

- (void)setupFileStorageLocationsForCloud {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    UIViewController <MADFileLocationManagerDelegate> *safeDelegate = _delegate;

    NSString *ubiquityIdentifier = [safeDelegate ubiquityIdentifier].copy;
    NSString *groupIdentifier = [safeDelegate groupIdentifier].copy;
    
    UIViewController <MADFileLocationManagerDelegate> * __weak weakDelegate = safeDelegate;
    typeof(self) __weak weakself = self;
    [MADFilesController getFileStorageLocationsForUbiquityIdentifier: ubiquityIdentifier
                                                     groupIdentifier: groupIdentifier
                                                               delay: ^ {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSLog(@"%s", __PRETTY_FUNCTION__);

            UIViewController <MADFileLocationManagerDelegate> *delegate = weakDelegate;
            if (delegate) {
                [delegate startLongRunningActivity];
            }
        }];
        
    } completion:^(BOOL cloudAvailable, NSURL *documents, NSURL *data) {
        
        MADFileLocationManager *sself = weakself;
        sself.storageOption = cloudAvailable ? MADAppStorageCloud : MADAppStorageLocal;
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
    NSLog(@"%s", __PRETTY_FUNCTION__);

    UIViewController <MADFileLocationManagerDelegate> *safedelegate;
    safedelegate = _delegate;
    
    NSString *groupIdentifier = [safedelegate groupIdentifier].copy;
    NSString *ubiquityIdentifier = [safedelegate ubiquityIdentifier].copy;
    NSString *fileExtention = [safedelegate fileExtention].copy;

    UIViewController <MADFileLocationManagerDelegate> __weak *wdelegate;
    wdelegate = safedelegate;
    
    typeof(self) __weak weakself = self;

    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        NSLog(@"%s", __PRETTY_FUNCTION__);

    
        UIViewController <MADFileLocationManagerDelegate> *delegate;
        delegate = wdelegate;

        MADFileLocationManager *strongself;
        strongself = weakself;
        
        if (delegate == nil || strongself == nil) return;

        
        MADFileLocationManager __weak *wself = strongself;

        UIAlertController *prompt = [UIAlertController newAlertControllerPromptStorageOptionLocal:^ {
            
            MADFileLocationManager *sself = wself;
            if (sself) {
                sself.storageOption = MADAppStorageLocal;
                [sself configureFilesController: NO storageOptionChangeHandler: nil];
            }
            
        } cloud: ^{
            
            MADFileLocationManager *sself = wself;
            if (sself) {
                sself.storageOption = MADAppStorageCloud;
                
                [sself configureFilesController: NO storageOptionChangeHandler:^{
                    
                    [MADFileUtilities migrateLocalFiles: groupIdentifier
                                                toCloud: ubiquityIdentifier
                                              extension: fileExtention];
                    
                }];
                
            }
        }];

        [delegate presentViewController:prompt animated:YES completion:nil];
    }];
}

- (void)getUserCloudPrefs {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    if (self.isFirstLaunch || self.getUserCloudPrefsFirstCall == false) {

        self.getUserCloudPrefsFirstCall = false;

        MADStorageState *storageState;
        storageState = [MADStorageState newStorageStateWithStorageOption: [self storageOption]
                                              hasUbiquityIdentityChanged: [self hasUbiquityIdentityChanged]
                                                        isCloudReadilyAvailable: [MADFilesController isCloudReadilyAvailable]];
        if (storageState.cloudAvailable) {
            
            if (storageState.storageOption == MADAppStorageCloud) {
                
                [self setupFileStorageLocationsForCloud];
                
            } else if (storageState.storageOption == MADAppStorageLocal ||
                       storageState.storageOption == MADAppStorageNotSet) {

                [self setupFileStorageLocationsForLocal];

            }
            
        } else {
        
            if (storageState.storageOption == MADAppStorageCloud) {
                self.storageOption = MADAppStorageNotSet;
            }
            
            [self configureFilesController: NO storageOptionChangeHandler: nil];
            
        }
    } else {
        self.getUserCloudPrefsFirstCall = false;
        [self getUserCloudPrefsSubsquient];
    }
}

- (void)getUserCloudPrefsSubsquient {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    MADStorageState *storageState;
    storageState = [MADStorageState newStorageStateWithStorageOption: [self storageOption]
                                          hasUbiquityIdentityChanged: [self hasUbiquityIdentityChanged]
                                                    isCloudReadilyAvailable: [MADFilesController isCloudReadilyAvailable]];
    if (storageState.accountDidChange) {
        
        switch (storageState.storageOption) {
        
            case MADAppStorageCloud: {
            
                self.storageOption = MADAppStorageNotSet;
                
                UIViewController <MADFileLocationManagerDelegate> *delegate;
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

    NSLog(@"%s", __PRETTY_FUNCTION__);

    if (self.filesController != nil && !accountChanged) return;

    
    UIViewController <MADFileLocationManagerDelegate> *delegate;
    delegate = _delegate;
    
    
    if (!self.filesController) {
        
        NSString *identifier = [self copyIdentifierForStorageOption];
        NSString *fileExtention = [delegate fileExtention].copy;
        MADAppStorage storageOption = self.storageOption;
        id filesController;
        filesController = [MADFilesController newFilesControllerWithPathExtension: fileExtention
                                                                    storageOption: storageOption
                                                                       identifier: identifier
                                                                firstQueryHandler: storageChangedHandler];
        self.filesController = filesController;
        [delegate didConfigureFilesController: self.filesController];
        [self.filesController startSearching];
        
    } else if (accountChanged) {
        NSString *identifer = [self copyIdentifierForStorageOption];
        NSString *fileExtention = [delegate fileExtention].copy;
        MADAppStorage storageOption = self.storageOption;
        id fc = [MADFileCoordinator newFileCoordinatorWithPathExtension: fileExtention
                                                          storageOption: storageOption
                                                             identifier: identifer
                                                      firstQueryHandler: storageChangedHandler];
        self.filesController.fileCoordinator = fc;
        [self.delegate didConfigureFilesController: self.filesController];
    }

}

- (NSString *)copyIdentifierForStorageOption {

    NSLog(@"%s", __PRETTY_FUNCTION__);

    UIViewController <MADFileLocationManagerDelegate> *delegate;
    NSString *groupIdentifer;

    delegate = _delegate;
    groupIdentifer = [self storageOption] != MADAppStorageCloud ? [delegate groupIdentifier] :
                                                                  [delegate ubiquityIdentifier];
    return groupIdentifer.copy;
}

@end
