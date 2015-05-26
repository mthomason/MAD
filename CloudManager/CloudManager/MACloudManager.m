//
//  CloudManager.m
//  Reports
//
//  Created by Michael Thomason on 8/4/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MACloudManager.h"
#import <UIKit/UIKit.h>
#import "MADMetadataQueryManager.h"
#import "MADMetaData.h"
#import "NSFileManager+Common.h"

NSString * const MTICloudUbiquityToken                                  = @"com.everydayapps.mad.designer.cloud.ubiquityIdentityToken";
NSString * const MADPreferencesCloudOptionsSelected                     = @"com.everydayapps.mad.designer.cloud.options.selected";

NSString * const MADNotificationUbiquitousContainerFetchingDidEnd       = @"MADNotificationUbiquitousContainerFetchingDidEnd";

@interface MACloudManager ()

@property (nonatomic, strong, readwrite) NSURL *ubiquityContainer;
@property (nonatomic, strong, readwrite) id <NSObject, NSCopying, NSCoding> ubiquityIdentityToken;

@property (atomic, assign) BOOL checkingCloudPreferencesLock;

@end

@implementation MACloudManager

static MACloudManager *sharedSingleton;

- (id)debugQuickLookObject {
    NSMutableString *debuggingString = [NSMutableString new];
    
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(ubiquityContainer)), self.ubiquityContainer.path];
    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(ubiquityIdentityToken)), self.ubiquityIdentityToken];

    [debuggingString appendFormat:@"%@:\t%@\n", NSStringFromSelector(@selector(checkingCloudPreferencesLock)), self.checkingCloudPreferencesLock ? @"YES" : @"NO"];
    [debuggingString appendFormat:@"%@:\t%@\n", @"isCloudAvailable", [MACloudManager isCloudAvailable] ? @"YES" : @"NO"];
    
    return debuggingString;
}

- (id)init {
    if (self = [super init]) {
        self.searchString = @"";
    }
    return self;
}

+ (void)initialize {
    if (self == [MACloudManager self]) {
        MACloudManager *manager = [[MACloudManager alloc] init];
        sharedSingleton = manager;
    }
}

+ (void)load { }

+ (instancetype)allocWithZone:(NSZone *)zone {
    return [super allocWithZone:zone];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

+ (MACloudManager *)sharedManager {
    return sharedSingleton;
}

#pragma mark - Internal Methods

+ (void)handleLongRunningCloudUrlLookup:(NSTimer *)timer {
    if(timer.userInfo) {
        void (^block)() = (void (^)())timer.userInfo;
        block();
    }
}

+ (void)getFileStorageLocationsForUbiquityIdentifier: (NSString *)ubiquityIdentifier
                                     groupIdentifier: (NSString *)groupIdentifier
                                               delay: (void (^)())handleLongRunningCall
                                          completion: (MADBlockCompletionFileStorageLocation)handleCompletion {
    
        if ([MACloudManager isCloudAvailable]) {
            void (^longRunningCallBlock)() = [handleLongRunningCall copy];
            [NSTimer timerWithTimeInterval: (NSTimeInterval)0.5000
                                    target: self
                                  selector: @selector(handleLongRunningCloudUrlLookup:)
                                  userInfo: longRunningCallBlock
                                   repeats: NO];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                
                NSFileManager *fileManager = [[NSFileManager alloc] init];
                //This call may be SLOW, so only do on BACKGROUND thread.
                //NSString *ubiquityIdentifier = [self.delegateApplication ubiquityIdentifier];
                
                NSURL *ubiquityContainer = [fileManager URLForUbiquityContainerIdentifier: ubiquityIdentifier];
                
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                
                    NSURL *documentDirectory = [ubiquityContainer URLByAppendingPathComponent:@"Documents"];
                    NSURL *dataDirectory = [ubiquityContainer URLByAppendingPathComponent:@"Data"];
                    [fileManager coordinateCreateDirectoryIfDoesNotExist:documentDirectory];
                    [fileManager coordinateCreateDirectoryIfDoesNotExist:dataDirectory];

                    if (handleCompletion) handleCompletion(YES, documentDirectory, dataDirectory);
                    
                });
            });
        } else {
            NSURL *documents = [[NSFileManager defaultManager] localDataDirectoryForGroupIdentifier:groupIdentifier];
            NSURL *data = [[NSFileManager defaultManager] localDocumentsDirectoryForGroupIdentifier:groupIdentifier];
            if (handleCompletion) handleCompletion(NO, documents, data);
        }
 
}

#pragma Cloud

+ (BOOL)isCloudAvailable {
    return [[NSFileManager defaultManager] ubiquityIdentityToken] != nil;
}

#pragma mark - MADFileLocationManagerDelegate

- (void)fileCoordinatorDidFailRemovingFileAtURL:(NSURL *)URL withError:(NSError *)error { }

- (void)fileCoordinatorDidFailCreatingFileAtURL:(NSURL *)URL withError:(NSError *)error { }

#pragma mark File Helpers

+ (NSOperationQueue *)queue {
    static NSOperationQueue *queue;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[NSOperationQueue alloc] init];
    });
    
    return queue;
}

+ (NSURL *)uniqueURLForURL:(NSURL *)url {
    return [MACloudManager uniqueUrlInDirectory: url.URLByDeletingLastPathComponent
                              withDesiredHandle: url.lastPathComponent.stringByDeletingPathExtension
                                   andExtension: url.lastPathComponent.pathExtension];
}

+ (NSURL *)uniqueUrlInDirectory:(NSURL *)directory
              withDesiredHandle:(NSString *)desiredFileHandle
                   andExtension:(NSString *)extension {
    
    NSFileManager *defaultFileManager = [NSFileManager defaultManager];
    NSURL *baseUrl = [directory URLByAppendingPathComponent: desiredFileHandle];
    NSURL *fileUrl = extension.length > 0 ?
                        [baseUrl URLByAppendingPathExtension: extension] :
                        baseUrl;
    NSInteger ctr = 0;
    BOOL isDir1;
    while ([defaultFileManager fileExistsAtPath:fileUrl.path isDirectory:&isDir1] || [defaultFileManager isUbiquitousItemAtURL:fileUrl]) {
        
        NSString *maybe = [desiredFileHandle stringByAppendingFormat:@" %ld", (long)ctr];
        NSURL *baseUrlFormatted = [directory URLByAppendingPathComponent: maybe];
        fileUrl = [baseUrlFormatted URLByAppendingPathExtension: extension];
        ctr++;
    }
    return fileUrl;
    
}

#pragma mark File Name

+ (NSString *)filenameId:(NSUInteger)tag {
    return [NSString stringWithFormat:@"%lu", (unsigned long)tag];
}

@end
