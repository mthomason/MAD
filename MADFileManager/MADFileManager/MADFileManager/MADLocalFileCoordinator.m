//
//  MADLocalFileCoordinator.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADLocalFileCoordinator.h"
#import <Foundation/NSPredicate.h>
#import <Foundation/NSCompoundPredicate.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSFileManager.h>
#import "MADDirectoryMonitor.h"
#import "MADFileUtilities.h"
#import <dispatch/queue.h>

NSString * const MADPredicateFormatSelfInObject                 = @"self in %@";
NSString * const MADPredicateFormatComparsonPathExtension       = @"(pathExtension = %@)";
NSString * const MADPredicateFormatComparsonLastPathComponent   = @"(lastPathComponent = %@)";

@interface MADLocalFileCoordinator () <MADDirectoryMonitorDelegate>

@property (nonatomic, strong) NSPredicate *predicate;
@property (nonatomic, strong) void (^firstQueryUpdateHandler)(void);
@property (nonatomic, strong) MADDirectoryMonitor *directoryMonitor;
@property (nonatomic, copy) NSArray *currentLocalContents;

@property (nonatomic, strong) NSString *fileGroup;

@end

@implementation MADLocalFileCoordinator

@synthesize delegate = _delegate;

#pragma mark - Initialization

- (instancetype)initWithPredicate:(NSPredicate *)predicate identifier:(NSString *)fileGroup firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler {

    if (self = [super init]) {
        self.fileGroup = fileGroup;
        self.predicate = predicate;
        self.firstQueryUpdateHandler = firstQueryUpdateHandler;
        
        NSURL *url = [MADFileUtilities localDocumentsDirectoryForGroupIdentifier:fileGroup];
        
        MADDirectoryMonitor *directoryMonitor = [[MADDirectoryMonitor alloc] initWithURL:url];
        self.directoryMonitor = directoryMonitor;
        self.directoryMonitor.delegate = self;
        
        NSArray *currentLocalContents = [NSArray array];
        self.currentLocalContents = currentLocalContents;

    }
    
    return self;
}

- (instancetype)initWithPathExtension:(NSString *)pathExtension identifier:(NSString *)fileGroup firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler {

    NSPredicate *predicate = [NSPredicate predicateWithFormat:MADPredicateFormatComparsonPathExtension, pathExtension];
    
    if (self = [self initWithPredicate:predicate identifier:fileGroup firstQueryUpdateHandler:firstQueryUpdateHandler]) {
        self.fileGroup = fileGroup;
    }
    
    return self;
}

- (instancetype)initWithLastPathComponent:(NSString *)lastPathComponent identifier:(NSString *)fileGroup firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:MADPredicateFormatComparsonLastPathComponent, lastPathComponent];
    
    if (self = [self initWithPredicate:predicate identifier:fileGroup firstQueryUpdateHandler:firstQueryUpdateHandler]) {
        self.fileGroup = fileGroup;
    }
    
    return self;
}

#pragma mark - MADFileCoordinator

- (void)startQuery {
    [self processChangeToLocalDocumentsDirectory];
    
    [self.directoryMonitor startMonitoring];
}

- (void)stopQuery {
    [self.directoryMonitor stopMonitoring];
}

- (void)removeFileAtURL:(NSURL *)URL {
    [MADFileUtilities removeFileAtURL:URL withCompletionHandler:^(NSError *error) {
        if (error) {
            [self.delegate fileCoordinatorDidFailRemovingFileAtURL:URL withError:error];
        }
        else {
            [self.delegate fileCoordinatorDidUpdateContentsWithInsertedURLs:@[]
                                                                removedURLs:@[URL]
                                                                updatedURLs:@[]];
        }
    }];
}

- (void)duplicateFileAtURL:(NSURL *)URL {
    [MADFileUtilities duplicateFileAtURL:URL withCompletionHandler:^(NSURL *newURL, NSError *error) {
        if (error) {
            [self.delegate fileCoordinatorDidFailDuplicatingFileAtURL:URL withError:error];
        } else {
            [self.delegate fileCoordinatorDidUpdateContentsWithInsertedURLs:@[newURL]
                                                                removedURLs:@[]
                                                                updatedURLs:@[]];
        }
    }];
}

- (void)renameFileAtURL:(NSURL *)URL toName:(NSString *)name {
    [MADFileUtilities renameFileAtURL:URL toName:name withCompletionHandler:^(NSURL *sourceURL, NSURL *newURL, NSError *error) {
        if (error) {
            [self.delegate fileCoordinatorDidFailRenamingFileAtURL:URL withError:error];
        } else {
            [self.delegate fileCoordinatorDidUpdateContentsWithInsertedURLs:@[newURL]
                                                                removedURLs:@[sourceURL]
                                                                updatedURLs:@[]];
        }
    }];
}

- (void)createURLForFile:(MADFile *)list withName:(NSString *)name extention:(NSString *)extention fileGroup:(NSString *)fileGroup {
    NSURL *documentURL = [self documentURLForName:name extention:extention fileGroup:fileGroup];
    
    [MADFileUtilities createFile:list atURL:documentURL withCompletionHandler:^(NSError *error) {
        if (error) {
            [self.delegate fileCoordinatorDidFailCreatingFileAtURL:documentURL withError:error];
        }
        else {
            [self.delegate fileCoordinatorDidUpdateContentsWithInsertedURLs: @[documentURL]
                                                                removedURLs: @[]
                                                                updatedURLs: @[]];
        }
    }];
}

- (BOOL)canCreateFileWithName:(NSString *)name extention:(NSString *)extention fileGroup:(NSString *)fileGroup {
    if (name.length <= 0) {
        return NO;
    }
    NSURL *documentURL = [self documentURLForName:name extention:extention fileGroup:fileGroup];
    return ![[NSFileManager defaultManager] fileExistsAtPath:documentURL.path];

}

#pragma mark - MADDirectoryMonitorDelegate

- (void)directoryMonitorDidObserveChange:(MADDirectoryMonitor *)directoryMonitor {
    [self processChangeToLocalDocumentsDirectory];
}

- (NSURL *)documentsDirectory {
    NSURL *url = [MADFileUtilities localDocumentsDirectoryForGroupIdentifier:self.fileGroup];
    return url;
}

#pragma mark - Convenience

- (void)processChangeToLocalDocumentsDirectory {
    dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    
    dispatch_async(defaultQueue, ^{

        NSURL *url = [MADFileUtilities localDocumentsDirectoryForGroupIdentifier:self.fileGroup];
        NSArray *localDocumentURLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL: url
                                                includingPropertiesForKeys: nil
                                                                   options: NSDirectoryEnumerationSkipsPackageDescendants
                                                                     error: nil];
        
        NSArray *localListURLs = [localDocumentURLs filteredArrayUsingPredicate:self.predicate];
        
        if (localListURLs.count > 0) {
            NSPredicate *containPredicate = [NSPredicate predicateWithFormat:MADPredicateFormatSelfInObject, self.currentLocalContents];
            NSPredicate *doesntContainPredicate = [NSCompoundPredicate notPredicateWithSubpredicate:containPredicate];
            
            NSArray *insertedURLs = [localListURLs filteredArrayUsingPredicate:doesntContainPredicate];
            
            containPredicate = [NSPredicate predicateWithFormat:MADPredicateFormatSelfInObject, localListURLs];
            doesntContainPredicate = [NSCompoundPredicate notPredicateWithSubpredicate:containPredicate];
            
            NSArray *removedURLs = [self.currentLocalContents filteredArrayUsingPredicate:doesntContainPredicate];
            
            [self.delegate fileCoordinatorDidUpdateContentsWithInsertedURLs:insertedURLs
                                                                removedURLs:removedURLs
                                                                updatedURLs:@[]];
            
            self.currentLocalContents = localListURLs;
        }
        
        if (self.firstQueryUpdateHandler) {
            self.firstQueryUpdateHandler();
            self.firstQueryUpdateHandler = nil;
        }
    });
}

- (NSURL *)documentURLForName:(NSString *)name extention:(NSString *)extention fileGroup:(NSString *)fileGroup {
    NSURL *url = [MADFileUtilities localDocumentsDirectoryForGroupIdentifier:fileGroup];
    NSURL *documentURLWithoutExtension = [url URLByAppendingPathComponent:name];
    return [documentURLWithoutExtension URLByAppendingPathExtension:extention];
}

@end
