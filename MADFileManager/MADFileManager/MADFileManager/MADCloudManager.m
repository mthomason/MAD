//
//  MADCloudManager.m
//  MADFileManager
//
//  Created by Michael Thomason on 5/29/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADCloudManager.h"
#import <dispatch/dispatch.h>
#import <Foundation/NSUbiquitousKeyValueStore.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSNotificationQueue.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSTimer.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSThread.h>

// FIXME: Don't import NSException.h on release builds.
#import <Foundation/NSException.h>

#import "MADFileUtilities.h"

// UserDefaults/Preferences Used by this Singleton

//BOOL value
static NSString * const MADAppConfigurationUserDefaultsStorageOptionSet
                            = @"MADAppConfigurationUserDefaultsStorageOptionSet";

//short MADCloudPreference value
static NSString * const MADAppConfigurationUserDefaultsStorageOption
                            = @"MADAppConfigurationUserDefaultsStorageOption";

static const char * MADQueueCloudSerial
                            = "com.everydayapps.mad.cloud.serial";

@interface MADCloudManager() {
    BOOL _completedStepOne;

    BOOL _cloudReadilyAvailable;
    MADAppStorage _userPreference;
    
}

    @property (nonatomic, copy) NSString *ubiquityIdentifier;
    @property (nonatomic, copy) NSString *groupIdentifier;
    
    @property (nonatomic, strong) dispatch_queue_t queue_background_serial;

@end

@implementation MADCloudManager

+ (instancetype)sharedManager {
    static id _sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] initPrivate];
    });
    return _sharedManager;
}

- (void)dealloc {

    NSString *name;
    name = NSUbiquitousKeyValueStoreDidChangeExternallyNotification;
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: name
                                                  object: nil];
    name = NSUbiquityIdentityDidChangeNotification;
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: name
                                                  object: nil];
}

- (instancetype)init {
    return [[self class] sharedManager];
}


- (instancetype)initPrivate {
    if (self = [super init]) {
        
        _ubiquityIdentifier = nil;
        _groupIdentifier =  nil;
        
        _userPreference = MADAppStorageStateUnknown;
        _completedStepOne = NO;
        
        @autoreleasepool {
            [self addNotifications];
        }
        
    }
    return self;
}

- (dispatch_queue_t)queue_background_serial {
    return _queue_background_serial == nil ?
        (_queue_background_serial =
            dispatch_queue_create(MADQueueCloudSerial, DISPATCH_QUEUE_SERIAL)) :
        _queue_background_serial;
}

- (void)initalizeWithGroupIdentifier:(NSString *)groupIdentifier
                  ubiquityIdentifier:(NSString *)ubiquityIdentifier {
    _groupIdentifier = groupIdentifier.copy;
    _ubiquityIdentifier = ubiquityIdentifier.copy;
}

- (void)startCloud {
    NSAssert(_ubiquityIdentifier != nil && _groupIdentifier != nil, @"Call initalize function.");

     if ([self stepOneCheckUbiquityIdentifierAndRegisterForNotifcations]) {
         [self stepTwoGetStorageInformationCloudAvailable:^(BOOL success) {
             
         }];
     } else {
         
     }
}


/*! Cloud setup step one.
 
 The first time this is called, it will check if the cloud is available and register for
     notifications about changes in cloud status.
     
     Subsiquent calls return if cloud is available.
     
     This does not give any information on the users preferences.
 
 Some more text.
 @brief Returns if logged in.
 @author Michael Thomason
 @return If cloud is available. */

- (BOOL)stepOneCheckUbiquityIdentifierAndRegisterForNotifcations {          // Returns if logged.

    if (_completedStepOne) return _cloudReadilyAvailable;
    
    _cloudReadilyAvailable = [MADCloudManager isCloudReadilyAvailable];     // Check if signed in
    [self addNotifications];                                                // Add notifications
    _completedStepOne = YES;
    return _cloudReadilyAvailable;                                          //  for change in
}                                                                           //  status.

- (void)stepTwoGetStorageInformationCloudAvailable:(void(^)(BOOL success))completion {
    
    [self stepTwoPartTwoGetUrlForUbiquityIdentifier: _ubiquityIdentifier
                                    groupIdentifier: _groupIdentifier
                                         completion: ^(BOOL success) {
                                            completion(success);
                                         }];
    [self stepTwoPartOneGetUserCloudPreferences:[MADCloudManager getSavedUserStorageOption]
                                     completion:^(BOOL success) {
        
    }];
}


- (void)stepTwoPartOneGetUserCloudPreferences:(MADAppStorage)storageOption
                                   completion:(void(^)(BOOL success))completion {
    switch (storageOption) {
            
        case MADAppStorageCloud:
            _userPreference = MADAppStorageCloud;
            completion(YES);
            break;

        case MADAppStorageLocal:
            _userPreference = MADAppStorageLocal;
            completion(YES);
            break;

        case MADAppStorageCloudButSignedOut:
            _userPreference = MADAppStorageCloudButSignedOut;
            completion(YES);
            break;

        case MADAppStorageNotSet:
        case MADAppStorageStateUnknown:
        default: {
            MADCloudManager *__unsafe_unretained scaryself = self;
            [self.delegate promptUserForCloudPreference:^(MADAppStorage preference) {
                scaryself->_userPreference = preference;
                if (completion) completion(YES);
            }];
            break;
        }
    }
}

- (void)stepTwoPartTwoGetUrlForUbiquityIdentifier: (NSString *)ubiquityIdentifier
                                  groupIdentifier: (NSString *)groupIdentifier
                                  completion:(void(^)(BOOL success))completion {
 
    [NSTimer timerWithTimeInterval: (NSTimeInterval)0.5000
                            target: self
                          selector: @selector(handleLongRunningCloudUrlLookup:)
                          userInfo: nil
                           repeats: NO];
    
    
    MADCloudManager * __unsafe_unretained scarySelf = self;
    
    
    dispatch_async(_queue_background_serial, ^{
        NSURL *ubiquityContainer;
        ubiquityContainer = [MADCloudManager copyURLToCloudUbiquityContainerForUbiquityID:ubiquityIdentifier];
        scarySelf->_ubiquityContainer = ubiquityContainer.copy;
        if (completion) completion(scarySelf->_ubiquityContainer != nil);
    });
    
    dispatch_async(_queue_background_serial, ^{
        
        [MADCloudManager createDirectory: @"Documents"
                               atLoction: scarySelf->_ubiquityContainer];
        [MADCloudManager createDirectory: @"Data"
                               atLoction: scarySelf->_ubiquityContainer];
        
        
    });
    

}

+ (NSURL *)copyURLToCloudUbiquityContainerForUbiquityID:(NSString *)ubiquityID {
    NSURL *cloudDirectoryURL;
    NSAssert(![NSThread isMainThread], @"Get off my thread!");
    cloudDirectoryURL = [[NSFileManager defaultManager]
                                                URLForUbiquityContainerIdentifier:ubiquityID].copy;
    return cloudDirectoryURL;
}

- (void)promptUserForStorageChoice {
    [self.delegate promptUserForCloudPreference:^(MADAppStorage preference) {
        switch (preference) {
            case MADAppStorageCloud:
                break;
            case MADAppStorageLocal:
                break;
            default:
                break;
        }
    }];
}

+ (void)createDirectory:(NSString *)directoryName atLoction:(NSURL *)location {
    id documentDirectory = [location URLByAppendingPathComponent:directoryName];
    [MADFileUtilities coordinateCreateDirectoryIfDoesNotExist:documentDirectory];
}

+ (MADAppStorage)getSavedUserStorageOption {
    return [[NSUserDefaults standardUserDefaults]
                boolForKey:MADAppConfigurationUserDefaultsStorageOptionSet] ?
                    (MADAppStorage)[[NSUserDefaults standardUserDefaults]
                        integerForKey:MADAppConfigurationUserDefaultsStorageOption] :
                    MADAppStorageStateUnknown;
}

+ (void)handleLongRunningCloudUrlLookup:(id)sender {
    
}


    /*
    NSLog(@"Getting file storage locations for ubiquity identifier: %@", ubiquityIdentifier);
    
    if ([self isCloudReadilyAvailable]) {
        
        NSLog(@"Going to background thread to get ubiquity url: %@", ubiquityIdentifier);
        
        void (^longRunningCallBlock)() = [handleLongRunningCall copy];
        
        [NSTimer timerWithTimeInterval: (NSTimeInterval)0.5000
                                target: self
                              selector: @selector(handleLongRunningCloudUrlLookup:)
                              userInfo: longRunningCallBlock
                               repeats: NO];
        
        dispatch_queue_t global_queue;
        global_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(global_queue, ^(void) {
            
            NSURL *ubiquityContainer;
            
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            //This call may be SLOW, so only do on BACKGROUND thread.
            
            ubiquityContainer = [fileManager URLForUbiquityContainerIdentifier: ubiquityIdentifier];
            
            NSLog(@"Got ubiquity container: %@.", ubiquityContainer);
            
            dispatch_queue_t main_queue = dispatch_get_main_queue();
            dispatch_sync(main_queue, ^{
                
                NSURL *documentDirectory;
                documentDirectory = [ubiquityContainer URLByAppendingPathComponent:@"Documents"];
                [MADFileUtilities coordinateCreateDirectoryIfDoesNotExist:documentDirectory];
                
                NSURL *dataDirectory = [ubiquityContainer URLByAppendingPathComponent:@"Data"];
                [MADFileUtilities coordinateCreateDirectoryIfDoesNotExist:dataDirectory];
                
                NSLog(@"Back on main thread with directories:\n\t%@\n\t%@", documentDirectory,
                      dataDirectory);
                if (handleCompletion) handleCompletion(YES, documentDirectory, dataDirectory);
                
            });
        });
        
    } else {
        
        NSURL *documents = [NSURL newURLForLocalDataDirectoryForGroupIdentifier:groupIdentifier];
        NSURL *data = [MADFileUtilities localDocumentsDirectoryForGroupIdentifier:groupIdentifier];
        if (handleCompletion) handleCompletion(NO, documents, data);
        
    }*/
    

+ (BOOL)isCloudReadilyAvailable {
    return [NSFileManager defaultManager].ubiquityIdentityToken != nil;
}

- (void)addNotifications {
    SEL handler;
    handler = @selector(handleNotificationKeyValueStoreDidChange:);
    NSString *name;
    name = NSUbiquitousKeyValueStoreDidChangeExternallyNotification;
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: handler
                                                 name: name
                                               object: nil];
    
    handler = @selector(handleNotificationKeyValueStoreDidChange:);
    name = NSUbiquityIdentityDidChangeNotification;
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: handler
                                                 name: NSUbiquityIdentityDidChangeNotification
                                               object: nil];
    
    dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0);
    dispatch_async(queue, ^{
        [[NSUbiquitousKeyValueStore defaultStore] synchronize];
    });
}



#pragma mark - Notification Handlers

- (void)handleNotificationKeyValueStoreDidChange:(NSNotification *)notification {
    // One or more keys changed.
    
}

- (void)handleNotificationUbiquityIdentityDidChange:(NSNotification *)notification {
    // Identity changed, so assume all keys changed.    
    /*
     [[NSOperationQueue mainQueue] addOperationWithBlock:^ {

        NSLog(@"%s", __PRETTY_FUNCTION__);
    
        UINavigationController *navController;
        navController = (UINavigationController *)[UIApplication sharedApplication].windows.firstObject.rootViewController;
        [navController popToRootViewControllerAnimated:YES];
        
        AppDelegate * __unsafe_unretained appDelegate = self;
        UIAlertController *signedOutController;
        signedOutController = [UIAlertController newAlertControlerNotifyCloudSignOut:^(UIAlertAction *action) {
            [appDelegate.openFileViewController getUserCloudPrefs];
        }];

        [self.openFileViewController presentViewController:signedOutController
                                                  animated:YES completion:nil];
    }];
    */
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
/*    [description appendFormat:@"*********\n"];
    [description appendFormat:@"Identifier:             %@\n", self.identifier];
    [description appendFormat:@"Function:               %@\n", self.function];
    [description appendFormat:@"Group number:           %@\n", self.groupNumber];
    [description appendFormat:@"Group type:             %@\n", self.groupType];*/
    [description appendFormat:@"*********"];
    return description;
}

@end
