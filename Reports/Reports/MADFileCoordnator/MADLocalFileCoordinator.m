//
//  MADLocalListCoordinator.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADLocalFileCoordinator.h"
#import "MADDirectoryMonitor.h"
#import "MADFileUtilities.h"
#import "MADConstants.h"

@interface MADLocalFileCoordinator () <MADDirectoryMonitorDelegate>

@property (nonatomic, strong) NSPredicate *predicate;

/// Closure executed after the first update provided by the coordinator regarding tracked URLs.
@property (nonatomic, strong) void (^firstQueryUpdateHandler)(void);

/// A GCD based monitor used to observe changes to the local documents directory.
@property (nonatomic, strong) MADDirectoryMonitor *directoryMonitor;

@property (nonatomic, copy) NSArray *currentLocalContents;

@end

@implementation MADLocalFileCoordinator
@synthesize delegate = _delegate;

#pragma mark - Initialization

- (instancetype)initWithPredicate:(NSPredicate *)predicate firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler {
    self = [super init];
    
    if (self) {
        _predicate = predicate;
        _firstQueryUpdateHandler = firstQueryUpdateHandler;
        
        _directoryMonitor = [[MADDirectoryMonitor alloc] initWithURL:[MADFileUtilities localDocumentsDirectory:MADIdentifierGroup]];
        _directoryMonitor.delegate = self;
        
        _currentLocalContents = [NSArray array];
    }
    
    return self;
}

- (instancetype)initWithPathExtension:(NSString *)pathExtension firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(pathExtension = %@)", pathExtension];
    
    self = [self initWithPredicate:predicate firstQueryUpdateHandler:firstQueryUpdateHandler];
    
    if (self) {
        // No need for additional initialization.
    }
    
    return self;
}

- (instancetype)initWithLastPathComponent:(NSString *)lastPathComponent firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(lastPathComponent = %@)", lastPathComponent];
    
    self = [self initWithPredicate:predicate firstQueryUpdateHandler:firstQueryUpdateHandler];
    
    if (self) {
        // No need for additional initialization.
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
    [MADFileUtilities removeListAtURL:URL withCompletionHandler:^(NSError *error) {
        if (error) {
            [self.delegate fileCoordinatorDidFailRemovingFileAtURL:URL withError:error];
        }
        else {
            [self.delegate fileCoordinatorDidUpdateContentsWithInsertedURLs:@[] removedURLs:@[URL] updatedURLs:@[]];
        }
    }];
}

- (void)createURLForFile:(MADList *)list withName:(NSString *)name {
    NSURL *documentURL = [self documentURLForName:name];
    
    [MADFileUtilities createList:list atURL:documentURL withCompletionHandler:^(NSError *error) {
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

- (BOOL)canCreateFileWithName:(NSString *)name {
    if (name.length <= 0) {
        return NO;
    }
    
    NSURL *documentURL = [self documentURLForName:name];
    
    return ![[NSFileManager defaultManager] fileExistsAtPath:documentURL.path];
}

#pragma mark - MADDirectoryMonitorDelegate

- (void)directoryMonitorDidObserveChange:(MADDirectoryMonitor *)directoryMonitor {
    [self processChangeToLocalDocumentsDirectory];
}

#pragma mark - Convenience

- (void)processChangeToLocalDocumentsDirectory {
    dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    
    dispatch_async(defaultQueue, ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        // Fetch the list documents from container documents directory.
        NSArray *localDocumentURLs = [fileManager contentsOfDirectoryAtURL: [MADFileUtilities localDocumentsDirectory:MADIdentifierGroup]
                                                includingPropertiesForKeys: nil
                                                                   options: NSDirectoryEnumerationSkipsPackageDescendants
                                                                     error: nil];
        
        NSArray *localListURLs = [localDocumentURLs filteredArrayUsingPredicate:self.predicate];
        
        if (localListURLs.count > 0) {
            NSPredicate *containPredicate = [NSPredicate predicateWithFormat:@"self in %@", self.currentLocalContents];
            NSPredicate *doesntContainPredicate = [NSCompoundPredicate notPredicateWithSubpredicate:containPredicate];
            
            NSArray *insertedURLs = [localListURLs filteredArrayUsingPredicate:doesntContainPredicate];
            
            containPredicate = [NSPredicate predicateWithFormat:@"self in %@", localListURLs];
            doesntContainPredicate = [NSCompoundPredicate notPredicateWithSubpredicate:containPredicate];
            
            NSArray *removedURLs = [self.currentLocalContents filteredArrayUsingPredicate:doesntContainPredicate];
            
            [self.delegate fileCoordinatorDidUpdateContentsWithInsertedURLs:insertedURLs
                                                                removedURLs:removedURLs
                                                                updatedURLs:@[]];
            
            self.currentLocalContents = localListURLs;
        }
        
        if (self.firstQueryUpdateHandler) {
            // Execute the `firstQueryUpdateHandler`, it will contain the closure from initialization on first update.
            self.firstQueryUpdateHandler();
            // Set `firstQueryUpdateHandler` to an empty closure so that the handler provided is only run on first update.
            self.firstQueryUpdateHandler = nil;
        }
    });
}

- (NSURL *)documentURLForName:(NSString *)name {
    NSURL *documentURLWithoutExtension = [[MADFileUtilities localDocumentsDirectory:MADIdentifierGroup] URLByAppendingPathComponent:name];
    
    return [documentURLWithoutExtension URLByAppendingPathExtension:MADFileExtentionMobleApplicationDocument];
}

@end
