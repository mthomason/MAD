//
//  MADFileManagerViewController.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/12/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADFileManager.h"
#import <MADFileManager/MADFilesController.h>
#import <MADFileManager/MADStorageState.h>
#import <MADFileManager/MADFileUtilities.h>
#import <MADFileManager/MADLocalFileCoordinator.h>
#import <MADFileManager/MADCloudFileCoordinator.h>
#import <MADFileManager/MADMetaData.h>

static NSString * const MADAppConfigurationUserDefaultsUbiquityToken       = @"MADAppConfigurationUserDefaultsUbiquityToken";
static NSString * const MADAppConfigurationUserDefaultsStorageOption       = @"MADAppConfigurationUserDefaultsStorageOption";
static NSString * const MADFirstLaunch                                     = @"MADFirstLaunch";

@interface MADFileManager ()

    @property (nonatomic, strong, readwrite) MADFilesController *filesController;
    @property (nonatomic, assign) MTReportState reportState;
    @property (nonatomic, assign) BOOL getUserCloudPrefsFirstCall;
    @property (readonly) BOOL isFirstLaunch;
    @property (readonly) NSString *ubiquityIdentifier;
    @property (readonly) NSString *groupIdentifier;
    @property (readonly) NSString *fileExtention;

@end

@implementation MADFileManager

- (instancetype)init {
    if (self = [super init]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSNumber *yes = @YES;
        NSNumber *notSet = @(MADAppStorageNotSet);
        NSDictionary *defaultValues = @{MADFirstLaunch: yes,
                                        MADAppConfigurationUserDefaultsStorageOption : notSet};
        [defaults registerDefaults:defaultValues];
        self.getUserCloudPrefsFirstCall = YES;
    }
    return self;
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
    NSData *ubiquityIdentityTokenArchive = [[NSUserDefaults standardUserDefaults] objectForKey:MADAppConfigurationUserDefaultsUbiquityToken];
    
    if (ubiquityIdentityTokenArchive) {
        storedToken = [NSKeyedUnarchiver unarchiveObjectWithData:ubiquityIdentityTokenArchive];
    }
    
    return storedToken;
}

- (void)persistAccount {
    id<NSObject, NSCopying, NSCoding> token = [NSFileManager defaultManager].ubiquityIdentityToken;
    if (token) {
        NSData *ubiquityIdentityTokenArchive = [NSKeyedArchiver archivedDataWithRootObject:token];
        [[NSUserDefaults standardUserDefaults] setObject:ubiquityIdentityTokenArchive forKey:MADAppConfigurationUserDefaultsUbiquityToken];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:MADAppConfigurationUserDefaultsUbiquityToken];
    }
}

#pragma mark - Overrides

- (MADAppStorage)storageOption {
    NSInteger value = [[NSUserDefaults standardUserDefaults] integerForKey:MADAppConfigurationUserDefaultsStorageOption];
    return (MADAppStorage)value;
}

- (void)setStorageOption:(MADAppStorage)storageOption {
    [[NSUserDefaults standardUserDefaults] setInteger:storageOption forKey:MADAppConfigurationUserDefaultsStorageOption];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Convenience

- (MADStorageState *)storageState {
    MADStorageState *storageState = [[MADStorageState alloc] init];
    storageState.storageOption = self.storageOption;
    storageState.accountDidChange = [self hasUbiquityIdentityChanged];
    storageState.cloudAvailable = [MADFilesController isCloudAvailable];
    return storageState;
}

- (BOOL)isFirstLaunch {
    BOOL isFirstLaunch = [[NSUserDefaults standardUserDefaults] boolForKey:MADFirstLaunch];
    if (isFirstLaunch) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:MADFirstLaunch];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return isFirstLaunch;
}

- (NSString *)ubiquityIdentifier {
    return [self.delegate ubiquityIdentifier];
}

- (NSString *)groupIdentifier {
    return [self.delegate groupIdentifier];
}

- (NSString *)fileExtention {
    return [self.delegate fileExtention];
}

- (void)getUserCloudPrefs {
    if (self.isFirstLaunch || self.getUserCloudPrefsFirstCall == NO) {
        self.getUserCloudPrefsFirstCall = NO;
        MADStorageState *storageState = self.storageState;
        if (storageState.cloudAvailable) {
            
            if (storageState.storageOption == MADAppStorageCloud) {
                
                void (^activityIndicatorStart)() = ^ {
                    [self.delegate startLongRunningActivity];
                };
                void (^activityIndicatorStop)() = ^ {
                    [self.delegate completedLongRunningActivity];
                };
                
                void (^handleLongRunningCloudLookup)() = ^ {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:activityIndicatorStart];
                };
                
                MADBlockCompletionFileStorageLocation completion = ^(BOOL cloudAvailable, NSURL *documents, NSURL *data) {
                    self.storageOption = cloudAvailable ? MADAppStorageCloud : MADAppStorageLocal;
                    [self configureFilesController: NO storageOptionChangeHandler: nil];
                    [[NSOperationQueue mainQueue] addOperationWithBlock:activityIndicatorStop];
                    
                };
                
                [MADFilesController getFileStorageLocationsForUbiquityIdentifier:self.ubiquityIdentifier
                                                                 groupIdentifier:self.groupIdentifier
                                                                           delay:handleLongRunningCloudLookup
                                                                      completion:completion];
                
                
            } else if (storageState.storageOption == MADAppStorageLocal ||
                       storageState.storageOption == MADAppStorageNotSet) {
                
                void (^handleOptionCloud)() = ^ {
                    self.storageOption = MADAppStorageCloud;
                    [self configureFilesController: NO storageOptionChangeHandler:^{
                        [MADFileUtilities migrateLocalFiles: self.groupIdentifier
                                                    toCloud: self.ubiquityIdentifier
                                                  extension: self.fileExtention];
                    }];
                    
                };
                void (^handleOptionLocal)() = ^ {
                    self.storageOption = MADAppStorageLocal;
                    [self configureFilesController: NO storageOptionChangeHandler: nil];
                };
                UIAlertController *prompt = [self.delegate promotStorageOptionLocal:handleOptionLocal
                                                                              cloud:handleOptionCloud];
                [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                    [self.delegate presentViewController:prompt animated:YES completion:nil];
                }];
            }
        } else {
            if (storageState.storageOption == MADAppStorageCloud) {
                self.storageOption = MADAppStorageNotSet;
            }
            [self configureFilesController: NO storageOptionChangeHandler: nil];
        }
    } else {
        self.getUserCloudPrefsFirstCall = NO;
        [self getUserCloudPrefsSubsquient];
    }
}

- (void)getUserCloudPrefsSubsquient {
    
    MADStorageState *storageState = self.storageState;
    if (storageState.accountDidChange) {
        
        switch (storageState.storageOption) {
            case MADAppStorageCloud: {
                
                UIAlertController *signedOutController = [self.delegate promotCloudSignOut:^(UIAlertAction *action) {
                    self.storageOption = MADAppStorageNotSet;
                    [self getUserCloudPrefs];
                }];
                [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                    [self.delegate presentViewController:signedOutController animated:YES completion:nil];
                }];
                
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

- (void)configureFilesController:(BOOL)accountChanged storageOptionChangeHandler:(void (^)(void))storageOptionChangeHandler {
    
    if (accountChanged || self.filesController == nil) {
        if (!self.filesController) {
            MADFilesController *filesController = [self filesControllerForCurrentConfigurationWithPathExtension:self.delegate.fileExtention
                                                                                              firstQueryHandler:storageOptionChangeHandler];
            self.filesController = filesController;
            [self.delegate didConfigureFilesController: self.filesController];
            [self.filesController startSearching];
            
        } else if (accountChanged) {
            self.filesController.fileCoordinator = [self listsCoordinatorForCurrentConfigurationWithPathExtension:self.delegate.fileExtention
                                                                                                firstQueryHandler:storageOptionChangeHandler];
            [self.delegate didConfigureFilesController: self.filesController];
        }
    }
    
}

#pragma mark - Document Operations

- (id<MADFileCoordinator>)listsCoordinatorForCurrentConfigurationWithPathExtension:(NSString *)pathExtension firstQueryHandler:(void (^)(void))firstQueryHandler {
    if (self.storageOption != MADAppStorageCloud) {
        // This will be called if the storage option is either `AAPLAppStorageLocal` or `AAPLAppStorageNotSet`.
        return [[MADLocalFileCoordinator alloc] initWithPathExtension:pathExtension identifier:self.groupIdentifier firstQueryUpdateHandler:firstQueryHandler];
    }  else {
        return [[MADCloudFileCoordinator alloc] initWithPathExtension:pathExtension identifier:self.delegate.ubiquityIdentifier firstQueryUpdateHandler:firstQueryHandler];
    }
}

- (id<MADFileCoordinator>)listsCoordinatorForCurrentConfigurationWithLastPathComponent:(NSString *)lastPathComponent firstQueryHandler:(void (^)(void))firstQueryHandler {
    if (self.storageOption != MADAppStorageCloud) {
        // This will be called if the storage option is either `AAPLAppStorageLocal` or `AAPLAppStorageNotSet`.
        return [[MADLocalFileCoordinator alloc] initWithLastPathComponent:lastPathComponent identifier:self.groupIdentifier firstQueryUpdateHandler:firstQueryHandler];
    } else {
        return [[MADCloudFileCoordinator alloc] initWithLastPathComponent:lastPathComponent identifier:self.delegate.ubiquityIdentifier firstQueryUpdateHandler:firstQueryHandler];
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

@end
