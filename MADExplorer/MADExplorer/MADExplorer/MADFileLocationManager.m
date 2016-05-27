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
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSNumber *yes = @YES;
        NSNumber *notSet = [[NSNumber alloc] initWithShort: MADAppStorageNotSet];
        NSDictionary *defaultValues = [[NSDictionary alloc] initWithObjectsAndKeys:
                                        yes, MADFirstLaunch,
                                        notSet, MADAppConfigurationUserDefaultsStorageOption, nil];
        [defaults registerDefaults:defaultValues];
        self.getUserCloudPrefsFirstCall = true;
    }
    return self;
}

#pragma mark - Ubiquity Identity Token Handling (Account Change Info)

- (BOOL)hasUbiquityIdentityChanged {
    BOOL hasChanged = NO;
    
    id <NSObject, NSCopying, NSCoding> currentToken = [[NSFileManager defaultManager].ubiquityIdentityToken copyWithZone:nil];
    id <NSObject, NSCopying, NSCoding> storedToken = [self storedUbiquityIdentityToken];
    
    bool currentTokenNilStoredNonNil = !currentToken && storedToken;
    bool storedTokenNilCurrentNonNil = !storedToken && currentToken;
    bool currentNotEqualStored = currentToken && storedToken && ![currentToken isEqual:storedToken];
    
    if (currentTokenNilStoredNonNil || storedTokenNilCurrentNonNil || currentNotEqualStored) {
        [self persistAccount];
        hasChanged = YES;
    }
    
    return hasChanged;
}

- (id<NSObject, NSCopying, NSCoding>)storedUbiquityIdentityToken {

    id<NSObject, NSCopying, NSCoding> storedToken = nil;
    
    // Determine if the iCloud account associated with this device has changed since the last time the user launched the app.
    NSData *ubiquityIdentityTokenArchive;
    ubiquityIdentityTokenArchive = [[NSUserDefaults standardUserDefaults] objectForKey:MADAppConfigurationUserDefaultsUbiquityToken];
    
    if (ubiquityIdentityTokenArchive) {
        storedToken = [NSKeyedUnarchiver unarchiveObjectWithData:ubiquityIdentityTokenArchive];
    }
    
    return storedToken;
}

- (void)persistAccount {
    NSLog(@"\t%s", __PRETTY_FUNCTION__);
    id<NSObject, NSCopying, NSCoding> token = [[NSFileManager defaultManager].ubiquityIdentityToken copyWithZone:nil];
    if (token) {
        NSData *ubiquityIdentityTokenArchive = [NSKeyedArchiver archivedDataWithRootObject:token];
        [[NSUserDefaults standardUserDefaults] setObject:ubiquityIdentityTokenArchive
                                                  forKey:MADAppConfigurationUserDefaultsUbiquityToken];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:MADAppConfigurationUserDefaultsUbiquityToken];
    }
}

#pragma mark - Overrides

- (MADAppStorage)storageOption {
    NSLog(@"\t%s", __PRETTY_FUNCTION__);
    return (MADAppStorage)[[NSUserDefaults standardUserDefaults] integerForKey:MADAppConfigurationUserDefaultsStorageOption];
}

- (void)setStorageOption:(MADAppStorage)storageOption {
    NSLog(@"\t%s", __PRETTY_FUNCTION__);
    [[NSUserDefaults standardUserDefaults] setInteger:storageOption forKey:MADAppConfigurationUserDefaultsStorageOption];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Convenience

- (MADStorageState *)newStorageState {
    MADStorageState *storageState = [[MADStorageState alloc] init];
    storageState.storageOption = self.storageOption;
    storageState.accountDidChange = [self hasUbiquityIdentityChanged];
    storageState.cloudAvailable = [MADFilesController isCloudAvailable];
    return storageState;
}

- (bool)isFirstLaunch {
    bool isFirstLaunch = [[NSUserDefaults standardUserDefaults] boolForKey:MADFirstLaunch] ?
                                                                                    true : false;
    if (isFirstLaunch) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:MADFirstLaunch];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return isFirstLaunch;
}

- (void)setupFileStorageLocationsForCloud {
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

    UIViewController <MADFileLocationManagerDelegate> *safedelegate;
    safedelegate = _delegate;
    
    NSString *groupIdentifier = [safedelegate groupIdentifier].copy;
    NSString *ubiquityIdentifier = [safedelegate ubiquityIdentifier].copy;
    NSString *fileExtention = [safedelegate fileExtention].copy;

    UIViewController <MADFileLocationManagerDelegate> __weak *wdelegate;
    wdelegate = safedelegate;
    
    typeof(self) __weak weakself = self;

    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
    
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

    if (self.isFirstLaunch || self.getUserCloudPrefsFirstCall == false) {

        self.getUserCloudPrefsFirstCall = false;

        MADStorageState *storageState = [self newStorageState];
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
    
    MADStorageState *storageState = [self newStorageState];
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
      storageOptionChangeHandler: (void (^)(void))storageOptionChangeHandler {
    
    if (self.filesController != nil && !accountChanged) return;

    
    UIViewController <MADFileLocationManagerDelegate> *delegate;
    delegate = _delegate;
    
    
    if (!self.filesController) {
        
        NSString *identifier = [self copyIdentifierForStorageOption];
        NSString *fileExtention = [delegate fileExtention].copy;
        MADAppStorage storageOption = self.storageOption;
        id filesController = [MADFilesController newFilesControllerWithPathExtension:fileExtention
                                                                       storageOption:storageOption
                                                                          identifier:identifier
                                                                   firstQueryHandler:storageOptionChangeHandler];
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
                                                      firstQueryHandler: storageOptionChangeHandler];
        self.filesController.fileCoordinator = fc;
        [self.delegate didConfigureFilesController: self.filesController];
    }

}

- (NSString *)copyIdentifierForStorageOption {
    UIViewController <MADFileLocationManagerDelegate> *delegate;
    delegate = _delegate;
    return self.storageOption != MADAppStorageCloud ? [delegate groupIdentifier].copy :
                                                      [delegate ubiquityIdentifier].copy;
}

@end
