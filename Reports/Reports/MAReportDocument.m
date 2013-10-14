//
//  MNSDocumentReport.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MAReportDocument.h"

@interface MAReportDocument ()

@property (nonatomic, retain) NSManagedObjectModel *mom;

@property (nonatomic, retain) RptqDocument *document;

@property (nonatomic, retain) NSManagedObjectContext *context;

@end

@implementation MAReportDocument

- (void)dealloc {
    [_document release];
    [_context release];
    [_mom release];
    [super dealloc];
}

- (NSManagedObjectModel *)managedObjectModel {
    NSManagedObjectModel *result = [self mom];
    if (result == nil) {
        NSString *modelPath = [[NSBundle mainBundle]
                               pathForResource:@"MAD" ofType:@"momd"];
        NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
        NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        [self setMom:mom];
        [mom release];
    }
    return [self mom];
}

+ (NSString *)persistentStoreName {
    return MTPersistentStoreAliasMad;
}

- (RptqDocument *)activeDocument {
    if ([self document] == nil) {
        NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
        RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
        if (document == nil) {
            document = [RptqDocument createMainDocumentForManagedObjectContext:managedObjectContext];
        }
        [document retain];
        [self setDocument:document];
        [document release];
    }
    return [[[self document] retain] autorelease];
}

//Add a new connection to the report
- (void)addDatasourceToReport: (MTDatabase *)database
                   completion: (void (^)(BOOL success, NSError *error))completion {

    RptqDocument *document = [self activeDocument];
    [RptqDocument addDatabase:database toDocument:document completion:^(BOOL success, NSError *error) {
        completion(success, error);
    }];
}

- (void)refresh:(void (^)(BOOL success))completion {
    RptqDocument *document = [self activeDocument];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    MTDatabase *mnsDatabase = [MTDatabase databaseForRptqDatabase: database];
    NSString *sqlSelect = [mnsDatabase getSqlForQuery:query];
    if ([sqlSelect length] > 0) {
        //sqlSelect = [NSString stringWithFormat:@"%@ LIMIT 100000", sqlSelect];
        [mnsDatabase cacheReportQueryForDocument: document completion: ^(MTDatabase *database, RptqQueryCache *cache) {
            if (database != nil && cache != nil) {
                completion(YES);
            } else {
                completion(NO);
            }
        }];
    } else {
        [self emptyCache];
        completion(YES);
    }
}

- (void)emptyCache {
    RptqDocument *document = [self document];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    RptqQueryCache *queryCache = [[RptqQueryCache initObjectForManagedObjectContext:[self managedObjectContext]] retain];
    NSError *error = nil;
    NSArray *emptyArray = @[];
    NSData *cachedData = [NSPropertyListSerialization dataWithPropertyList:emptyArray format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
    NSString *name = [[[MTActiveDocument sharedDocument] activeDocument] name];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesPath = [paths lastObject];
    NSURL *cachesUrl = [NSURL fileURLWithPath:cachesPath isDirectory:YES];
    NSURL *url = [cachesUrl URLByAppendingPathComponent:name isDirectory:NO];
    [cachedData writeToURL:url options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen error:&error];
    if (error) {
        error = nil;
        [cachedData writeToURL:url options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen error:&error];
    }
    
    [queryCache setCacheDate:[NSDate date]];
    [query setHasQueryCache:queryCache];
    [queryCache release];
}

- (BOOL)hasCachedData {
    RptqDocument *document = [self document];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    return [query hasQueryCache] != nil;
}

- (void)sendTo {
    [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (NSString *)fileNameExtensionForType:(NSString *)typeName saveOperation:(UIDocumentSaveOperation)saveOperation {
    return MTDocumentExtentionMobleApplicationDocumentArchive;
}

- (NSString *)fileType {
    return [MAReportDocument fileType];
}

+ (NSString *)fileType {
    return MTDocumentTypeUtiMad;
}

+ (NSURL *)thumbnailUrlForMadUrl:(NSURL *)madUrl {
    NSString *lastPathComponent = [madUrl lastPathComponent];
    NSString *fileName = [lastPathComponent stringByDeletingPathExtension];
    NSString *extention = [UIDevice isRetnaDisplay] ? @"@2x.png": @".png";
    fileName = [fileName stringByAppendingString:extention];
    
    NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [directoryPaths lastObject];
    NSURL *thumbnailPath = [NSURL fileURLWithPath: cacheDirectory];
    NSURL *result = [[thumbnailPath URLByAppendingPathComponent:fileName isDirectory:NO] retain];
    return [result autorelease];
}

+ (void)openManagedDocumentAtUrl:(NSURL *)url withCompletionHandler:(void (^)(id, BOOL))completionHandler {
    
    NSURL *urlToOpen = nil;
    if ([[url pathExtension] isEqualToString:MTDocumentExtentionMobleApplicationDocument]) {
        
        
        //Aquire the destination URL.
        NSString *destinationName = [[[[url lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:MTDocumentExtentionMobleApplicationDocumentArchive] retain];
        NSURL *destinationDirectoryUrl = [[NSFileManager localTemporaryDirectory] retain];
        NSArray *directories = NSSearchPathForDirectoriesInDomains(NSAutosavedInformationDirectory, NSUserDomainMask, YES);
        [directories lastObject];
        NSURL *destinationUrl = [[destinationDirectoryUrl URLByAppendingPathComponent:destinationName isDirectory:YES] retain];
        
        //Remove existing Core Data File.
        NSFileManager *fileManager = [[NSFileManager defaultManager] retain];
        BOOL isDirectory;
        BOOL exists = [fileManager fileExistsAtPath:[destinationUrl path] isDirectory:&isDirectory];
        if (exists) {
            NSError *deleteError = nil;
            if (isDirectory) {
                NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:destinationUrl includingPropertiesForKeys:@[NSURLIsDirectoryKey] options:-1 errorHandler:^BOOL(NSURL *url, NSError *error) {
                    MTLog(@"Error %@", error);
                    return YES;
                }];
                for (NSURL *file in enumerator) {
                    NSError *error = nil;
                    [fileManager removeItemAtURL:file error:&error];
                    if (error != nil) {
                        MTLog(@"Error %@", error);
                    }
                }
                [fileManager removeItemAtURL:destinationUrl error:&deleteError];
                if (deleteError != nil) {
                    MTLog(@"%@", deleteError);
                }
            } else {
                [fileManager removeItemAtURL:destinationUrl error:&deleteError];
            }
        }
        [fileManager release];
        
        //Load MAD File
        NSData *data = [[NSData alloc] initWithContentsOfURL:url];
        NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithSerializedRepresentation:data];
        
        NSFileWrapperWritingOptions writingOptions = NSFileWrapperWritingAtomic | NSFileWrapperWritingWithNameUpdating;
        NSError* fileWrittingError = nil;
        [fileWrapper writeToURL:destinationUrl options:writingOptions originalContentsURL:url error:&fileWrittingError];
        if (fileWrittingError) {
            fileWrittingError = nil;
            [fileWrapper writeToURL:destinationUrl options:writingOptions originalContentsURL:url error:&fileWrittingError];
        }
        if (fileWrittingError == nil) {
            urlToOpen = [destinationUrl retain];
        }
        [destinationName release];
        [destinationDirectoryUrl release];
        [data release];
        [fileWrapper release];
        [destinationUrl release];
    } else if ([[url pathExtension] isEqualToString:MTDocumentExtentionMobleApplicationDocumentArchive]) {
        urlToOpen = [url retain];
    }
    
    if (urlToOpen != nil) {

        MAReportDocument *managedDocumentAtUrl = [[MAReportDocument alloc] initWithFileURL:urlToOpen];
        
        NSNumber *migratePersistentStoresAutomaticallyOption = [[NSNumber alloc] initWithBool:YES];
        NSNumber *inferMappingModelAutomaticallyOption = [[NSNumber alloc] initWithBool:YES];
        NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:migratePersistentStoresAutomaticallyOption, NSMigratePersistentStoresAutomaticallyOption, inferMappingModelAutomaticallyOption, NSInferMappingModelAutomaticallyOption, nil];
        
        [managedDocumentAtUrl setPersistentStoreOptions: options];
        
        BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:[urlToOpen path]];
        if (fileExist) {
            
            [managedDocumentAtUrl openWithCompletionHandler:^(BOOL success) {
                NSURL *thumbnailUrl = [MAReportDocument thumbnailUrlForMadUrl:urlToOpen];
                [managedDocumentAtUrl setThumbnailUrl:thumbnailUrl];
                completionHandler(managedDocumentAtUrl, success);
            }];
        } else {
            [managedDocumentAtUrl saveToURL:url forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
                completionHandler(managedDocumentAtUrl, success);
            }];
        }
        [options release];
        [managedDocumentAtUrl release];
        [migratePersistentStoresAutomaticallyOption release];
        [inferMappingModelAutomaticallyOption release];
    }
    [urlToOpen release];
    
}

@end
