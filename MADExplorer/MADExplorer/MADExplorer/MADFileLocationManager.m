//
//  MADFileManagerViewController.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/12/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADFileLocationManager.h"
#import "madlog.h"

#import <MADFoundation/MADApplication.h>
#import <MADCocoaExtensions/MADAlertController.h>
#import <MADFileManager/MADFileLocationManagerDelegate.h>
#import <MADFileManager/MADFilesController.h>
#import <MADFileManager/MADFileUtilities.h>
#import <MADFileManager/MADFileCoordinator.h>
#import <MADFileManager/MADFileLocationManagerDelegate.h>
#import <MADFileManager/MADAppStorageOption.h>
#import <MADFileManager/MADStorageState.h>

#import <UIKit/UIViewController.h>
#import <UIKit/UIAlertController.h>

#import <os/log.h>

static NSString * const MADAppConfigurationUserDefaultsUbiquityToken      = @"MADAppConfigurationUserDefaultsUbiquityToken";
static NSString * const MADAppConfigurationUserDefaultsStorageOption      = @"MADAppConfigurationUserDefaultsStorageOption";
static NSString * const MADFirstLaunch                                    = @"MADFirstLaunch";
static NSString * const MADAppConfigurationUserDefaultsUbiquityTokenClass = @"UbiquityTokenClass";

static UIAlertController *MADCreateAlertControllerPromptStorage(void (^handlerLocal)(void), void (^handlerCloud)(void));
static UIAlertController *MADCreateAlertControllerPromptStorage(void (^handlerLocal)(void), void (^handlerCloud)(void)) {
	if (!handlerLocal && !handlerCloud) {
		return nil;
	}

	UIAlertController *storageController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Choose Storage Option", @"Choose Storage Option")
																			   message:NSLocalizedString(@"Do you want to store documents in iCloud or only on this device?", @"Do you want to store documents in iCloud or only on this device?")
																		preferredStyle:UIAlertControllerStyleAlert];
	if (handlerLocal) {
		
		UIAlertAction *localOption = [UIAlertAction actionWithTitle:NSLocalizedString(@"Local Only", @"Local Only")
															  style:UIAlertActionStyleDefault
															handler:^(UIAlertAction * _Nonnull action) {
			if (handlerLocal) handlerLocal();
		}];
		[storageController addAction:localOption];
	}
	
	if (handlerCloud) {
		UIAlertAction *cloudOption = [UIAlertAction actionWithTitle:NSLocalizedString(@"iCloud", @"iCloud")
															  style:UIAlertActionStyleDefault
															handler:^(UIAlertAction * _Nonnull action) {
			if (handlerCloud) handlerCloud();
		}];
		[storageController addAction:cloudOption];
	}
	return storageController;
}

@interface MADFileLocationManager ()

	@property (nonatomic, readwrite, strong) MADFilesController *filesController;
	@property (nonatomic, readwrite, assign) BOOL getUserCloudPrefsFirstCall;
	@property (nonatomic, readonly) BOOL isFirstLaunch;
	@property (nonatomic, copy) NSString *groupID;
	@property (nonatomic, copy) NSString *ubiquityID;
	@property (nonatomic, strong) dispatch_queue_t synchronizationQueue;

@end

@implementation MADFileLocationManager

- (instancetype)init {
	@throw NSInternalInconsistencyException;
}

- (instancetype)initWithUbiquityID:(NSString *)ubiquityID andGroupID:(NSString *)groupID {
	if (!ubiquityID || !groupID) {
		return nil;
	}
	if (self = [super init]) {
		_synchronizationQueue = dispatch_queue_create("com.madfilelocationmanager.sync", DISPATCH_QUEUE_SERIAL);
		self.groupID = [groupID copy];
		self.ubiquityID = [ubiquityID copy];
		NSDictionary *defaultValues = @{
			MADFirstLaunch: @YES,
			MADAppConfigurationUserDefaultsStorageOption: @(MADAppStorageNotSet)
		};
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
		self.getUserCloudPrefsFirstCall = YES;
	}
	return self;
}

#pragma mark - Ubiquity Identity Token Handling (Account Change)

// This function causes a login prompt
- (BOOL)hasUbiquityIdentityChanged {
	BOOL hasChanged = NO;
	
	id <NSObject, NSCopying, NSCoding> currentToken = [[NSFileManager defaultManager].ubiquityIdentityToken copyWithZone:nil];
	id <NSObject, NSCopying, NSCoding> storedToken = [self copyStoredUbiquityIdentityToken];
	
	// Compare tokens (handles all nil/non-nil combinations)
	if ((currentToken && !storedToken) ||
		(!currentToken && storedToken) ||
		(currentToken && storedToken && ![currentToken isEqual:storedToken])) {
		
		[self persistAccount];  // Update stored token
		hasChanged = YES;
	}
	
	return hasChanged;
}

- (id<NSObject, NSCopying, NSCoding>)copyStoredUbiquityIdentityToken {
	NSData *ubiquityIdentityTokenArchive = [[NSUserDefaults standardUserDefaults] objectForKey:MADAppConfigurationUserDefaultsUbiquityToken];
	if (!ubiquityIdentityTokenArchive) {
		return nil;
	}
	
	// Retrieve the class name
	NSString *className = [[NSUserDefaults standardUserDefaults] stringForKey:MADAppConfigurationUserDefaultsUbiquityTokenClass];
	Class tokenClass = className ? NSClassFromString(className) : nil;
		
	if (!tokenClass) {
		os_log_error(OS_LOG_DEFAULT, "%s: Unknown class for ubiquity token. Treating as changed account.", __PRETTY_FUNCTION__);
		return nil;
	}
	
	NSSet *allowedClasses = [NSSet setWithObjects:tokenClass, [NSData class], nil];
	
	NSError *error = nil;
	id storedToken = [NSKeyedUnarchiver unarchivedObjectOfClasses:allowedClasses
														 fromData:ubiquityIdentityTokenArchive
															error:&error];
	
	if (error) {
		os_log_error(OS_LOG_DEFAULT, "%s: Error unarchiving ubiquity token: %@", __PRETTY_FUNCTION__, error);
		return nil;
	}
	
	return storedToken;
}

- (void)persistAccount {
	id<NSObject, NSCopying, NSCoding> token = [[NSFileManager defaultManager].ubiquityIdentityToken copyWithZone:nil];
	if (token) {
		
		NSError *error = nil;
		NSData *ubiquityIdentityTokenArchive = [NSKeyedArchiver archivedDataWithRootObject:token requiringSecureCoding:YES error:&error];

		if (ubiquityIdentityTokenArchive && !error) {
			[[NSUserDefaults standardUserDefaults] setObject:ubiquityIdentityTokenArchive forKey:MADAppConfigurationUserDefaultsUbiquityToken];
			[[NSUserDefaults standardUserDefaults] setObject:NSStringFromClass([token class]) forKey:MADAppConfigurationUserDefaultsUbiquityTokenClass];
		} else {
			os_log_error(OS_LOG_DEFAULT, "%s: Error archiving ubiquity token: %@", __PRETTY_FUNCTION__, error);
			// Clear invalid token on failure
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:MADAppConfigurationUserDefaultsUbiquityToken];
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:MADAppConfigurationUserDefaultsUbiquityTokenClass];
		}
	} else {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults removeObjectForKey:MADAppConfigurationUserDefaultsUbiquityToken];
		[defaults removeObjectForKey:MADAppConfigurationUserDefaultsUbiquityTokenClass];
	}
}

#pragma mark - Overrides

+ (BOOL)StorageOptionsInitialized {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"MADAppConfigurationUserDefaultsStorageOptionSet"];
}

+ (NSInteger)StorageOptionUserDefaults {
	return [[NSUserDefaults standardUserDefaults] integerForKey:MADAppConfigurationUserDefaultsStorageOption];
}

+ (MADAppStorage)StorageOption {
	return [self StorageOptionsInitialized] ? [self StorageOptionUserDefaults] : MADAppStorageStateUnknown;
}

+ (void)setStorageOption:(MADAppStorage)storageOption {
	[[NSUserDefaults standardUserDefaults] setInteger: storageOption
											   forKey: MADAppConfigurationUserDefaultsStorageOption];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Convenience

- (BOOL)isFirstLaunch {
	BOOL isFirstLaunch = [[NSUserDefaults standardUserDefaults] boolForKey:MADFirstLaunch];
	if (isFirstLaunch) {
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:MADFirstLaunch];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	return isFirstLaunch;
}

- (void)setupFileStorageLocationsForCloud {
	NSString *ubiquityIdentifier = [MADApplication ubiquityIdentifier];
	NSString *groupIdentifier = [MADApplication groupIdentifier];
	
	UIViewController <MADFileLocationManagerDelegate> *safeDelegate;
	safeDelegate = (UIViewController <MADFileLocationManagerDelegate> *)_delegate;

	UIViewController <MADFileLocationManagerDelegate> * __weak weakDelegate = safeDelegate;
	MADFileLocationManager * __weak weakself = self;
	
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
		[sself.class setStorageOption: storageOption];
		
		[sself configureFilesController: NO storageOptionChangeHandler: nil];
		
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			
			UIViewController <MADFileLocationManagerDelegate> * __strong sdelegate = weakDelegate;
			if (sdelegate) {
				[sdelegate completedLongRunningActivity];
			}
			
		}];
		
	}];
}

- (void)setupFileStorageLocationsForLocal {
	id <MADFileLocationManagerDelegate> safedelegate = _delegate;
	NSString *groupIdentifier = [[[safedelegate class] groupIdentifier] copy];
	NSString *ubiquityIdentifier = [[[safedelegate class] ubiquityIdentifier] copy];
	NSString *fileExtention = [[safedelegate fileExtention] copy];

	id <MADFileLocationManagerDelegate> __weak wdelegate = safedelegate;
	
	MADFileLocationManager * __weak weakself = self;

	[[NSOperationQueue mainQueue] addOperationWithBlock:^ {
		id <MADFileLocationManagerDelegate> delegate = wdelegate;
		MADFileLocationManager *strongself = weakself;
		if (delegate == nil || strongself == nil) return;
		
		MADFileLocationManager __weak *wself = strongself;
				
		void (^handlerLocal)(void) = ^ {
			MADFileLocationManager *sself = wself;
			if (sself) {
				[MADFileLocationManager setStorageOption:MADAppStorageLocal];
				[sself configureFilesController: NO storageOptionChangeHandler: nil];
			}
		};

		void (^handlerCloud)(void) = ^{
			
			MADFileLocationManager *sself = wself;
			if (!sself) return;
			
			[MADFileLocationManager setStorageOption:MADAppStorageCloud];
			
			void (^handleStorageOptionChanged)(void) = ^{
				[MADFileUtilities migrateLocalFiles: groupIdentifier
											toCloud: ubiquityIdentifier
										  extension: fileExtention];
			};
			
			[sself configureFilesController: NO
				 storageOptionChangeHandler: handleStorageOptionChanged];
		};
		
		UIAlertController *prompt = MADCreateAlertControllerPromptStorage(handlerLocal, handlerCloud);
		[delegate.presentingController presentViewController:prompt animated:YES completion:nil];
		
	}];
}

- (void)getUserCloudPrefs {
	// Use a serial queue to prevent race conditions
	dispatch_async(self.synchronizationQueue, ^{
		
		// Make sure this only runs once
		if (self.isFirstLaunch || !self.getUserCloudPrefsFirstCall) {
			self.getUserCloudPrefsFirstCall = NO;
			
			
			__block BOOL isCloudReadilyAvailable = [MADFilesController isCloudReadilyAvailable];

			BOOL hasUbiquityIdentityChanged = [self hasUbiquityIdentityChanged];
			MADStorageState *storageState = [[MADStorageState alloc] init];
			storageState.storageOption = [self.class StorageOption];
			storageState.accountDidChange = hasUbiquityIdentityChanged;
			storageState.cloudAvailable = isCloudReadilyAvailable;

			os_log_debug(GetExplorerLog(), "storageState: %@ cloudAvailable: %@: storageOption: %ld", storageState, storageState.cloudAvailable ? @"YES" : @"NO", (long)storageState.storageOption);
			if (storageState.cloudAvailable) {
				if (storageState.storageOption == MADAppStorageCloud) {
					os_log_debug(GetExplorerLog(), "Calling setupFileStorageLocationsForCloud");
					[self setupFileStorageLocationsForCloud];
				} else if (storageState.storageOption == MADAppStorageLocal || storageState.storageOption == MADAppStorageNotSet || storageState.storageOption == MADAppStorageStateUnknown) {
					os_log_debug(GetExplorerLog(), "Calling setupFileStorageLocationsForLocal");
					[self setupFileStorageLocationsForLocal];
				}
			} else {
				os_log_debug(GetExplorerLog(), "Cloud not available.");
				if (storageState.storageOption == MADAppStorageCloud) {
					[self.class setStorageOption:MADAppStorageNotSet];
				}
				[self configureFilesController:NO storageOptionChangeHandler:nil];
			}
		} else {
			self.getUserCloudPrefsFirstCall = NO;
			[self getUserCloudPrefsSubsquient];
		}
	});
}

- (void)getUserCloudPrefsSubsquient {
	MADStorageState *storageState = [[MADStorageState alloc] init];
	storageState.storageOption = [self.class StorageOption];
	storageState.accountDidChange = [self hasUbiquityIdentityChanged];
	storageState.cloudAvailable = [MADFilesController isCloudReadilyAvailable];

	if (storageState.accountDidChange) {
		
		switch (storageState.storageOption) {
		
			case MADAppStorageCloud: {
			
				[self.class setStorageOption: MADAppStorageNotSet];
				id <MADFileLocationManagerDelegate> delegate = _delegate;
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
			// Generally MADAppStorageStateUnknown
			[self configureFilesController: NO storageOptionChangeHandler: nil];
		}
	}
}

- (void)configureFilesController: (BOOL)accountChanged
	  storageOptionChangeHandler: (void (^)(void))storageChangedHandler {

	if (self.filesController != nil && !accountChanged) return;

	id <MADFileLocationManagerDelegate> delegate = _delegate;
	
	if (!_filesController) {
		
		MADFilesController *filesController = [MADFilesController newFilesControllerWithPathExtension: [delegate fileExtention]
																						storageOption: [self.class StorageOption]
																						   identifier: [self identifierForStorageOption]
																					firstQueryHandler: storageChangedHandler];
		[delegate didConfigureFilesController: filesController];
		[filesController startSearching];
		_filesController = filesController;
		
	} else if (accountChanged) {
		MADFileCoordinator *fc = [MADFileCoordinator newFileCoordinatorWithPathExtension: [delegate fileExtention]
																		   storageOption: [self.class StorageOption]
																			  identifier: [self identifierForStorageOption]
																	   firstQueryHandler: storageChangedHandler];
		_filesController.fileCoordinator = fc;
		[delegate didConfigureFilesController: _filesController];
	}

}

- (NSString *)identifierForStorageOption {
	return [self.class StorageOption] != MADAppStorageCloud ? self.groupID : self.ubiquityID;
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
