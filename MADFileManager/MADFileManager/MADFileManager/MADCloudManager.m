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

#import "MADFileUtilities.h"

@interface MADCloudManager() {
    BOOL _completedStepOne;

    BOOL _cloudReadilyAvailable;
    MADCloudPreference _userPreference;
}

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
        
        _userPreference = MADCloudPreferenceUnknown;
        _completedStepOne = NO;
        
        @autoreleasepool {
            [self addNotifications];
        }
        
    }
    return self;
}

- (void)startCloud {
     if ([self stepOneCheckUbiquityIdentifierAndRegisterForNotifcations]) {
         [self stepTwoGetStorageInformationCloudAvailable];
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
    return _cloudReadilyAvailable;                                          //  for change in
}                                                                           //  status.

- (void)stepTwoGetStorageInformationCloudAvailable {
    
    
}

+ (void)stepThreePartOneGetUserICloudPreferences {

}

+ (void)stepThreePartTwoGetUrlForUbiquityIdentifier: (NSString *)ubiquityIdentifier
                                       groupIdentifier: (NSString *)groupIdentifier {
    //void (^longRunningCallBlock)() = [handleLongRunningCall copy];
    
    [NSTimer timerWithTimeInterval: (NSTimeInterval)0.5000
                            target: self
                          selector: @selector(handleLongRunningCloudUrlLookup:)
                          userInfo: nil
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
            
            [self createDirectory: @"Documents"
                        atLoction: ubiquityContainer];
            [self createDirectory: @"Data"
                        atLoction: ubiquityContainer];
            
            
        });
    });
}

+ (void)createDirectory:(NSString *)directoryName atLoction:(NSURL *)location {
    id documentDirectory = [location URLByAppendingPathComponent:directoryName];
    [MADFileUtilities coordinateCreateDirectoryIfDoesNotExist:documentDirectory];
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
        
        NSURL *documents = [MADFileUtilities localDataDirectoryForGroupIdentifier:groupIdentifier];
        NSURL *data = [MADFileUtilities localDocumentsDirectoryForGroupIdentifier:groupIdentifier];
        if (handleCompletion) handleCompletion(NO, documents, data);
        
    }*/
    

+ (BOOL)isCloudReadilyAvailable {
    return [[NSFileManager defaultManager] ubiquityIdentityToken] != nil;
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
