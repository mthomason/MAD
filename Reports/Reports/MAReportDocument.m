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

@end

@implementation MAReportDocument

- (void)dealloc {
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

//Add a new connection to the report
- (void)addDatasourceToReport: (MTDatabase *)database
                   completion: (void (^)(BOOL success, NSError *error))completion {
    
    [RptqDocument addDatabase:database toManagedObjectContext:[self managedObjectContext] completion:^(BOOL success, NSError *error) {
        //if (success) {
        //    [self saveToURL:[self fileURL] forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
                completion(success, error);
        //    }];
        //}
    }];
}

- (void)refresh:(void (^)(BOOL success))completion {
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    MTDatabase *mnsDatabase = [MTDatabase databaseForRptqDatabase: database];
    NSString *sqlSelect = [mnsDatabase getSqlForQuery:query];
    if ([sqlSelect length] > 0) {
        //sqlSelect = [NSString stringWithFormat:@"%@ LIMIT 100000", sqlSelect];
        [mnsDatabase cacheReportQueryForManagedObjectContext: managedObjectContext completion: ^(MTDatabase *database, RptqQueryCache *cache) {
            if (database != nil && cache != nil) {
                completion(YES);
            } else {
                completion(NO);
            }
        }];
    } else {
        [mnsDatabase emptyCacheWithManagedObjectContext:managedObjectContext];
        completion(YES);
    }
}

- (BOOL)hasCachedData {
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
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
    NSString *tempPath = NSTemporaryDirectory();
    NSURL *thumbnailPath = [NSURL fileURLWithPath: tempPath];
    NSURL *result = [[thumbnailPath URLByAppendingPathComponent:fileName isDirectory:NO] retain];
    return [result autorelease];
}

+ (void)openManagedDocumentAtUrl:(NSURL *)url withCompletionHandler:(void (^)(id, BOOL))completionHandler {
    
    NSURL *urlToOpen = nil;
    if ([[url pathExtension] isEqualToString:MTDocumentExtentionMobleApplicationDocument]) {
        
        
        //Aquire the destination URL.
        NSString *destinationName = [[[[url lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:MTDocumentExtentionMobleApplicationDocumentArchive] retain];
//        NSURL *destinationDirectoryUrl = [[url URLByDeletingLastPathComponent] retain];
        NSURL *destinationDirectoryUrl = [[NSFileManager localTemporaryDirectory] retain];
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

        __block MAReportDocument *managedDocumentAtUrl = [[MAReportDocument alloc] initWithFileURL:urlToOpen];
        
        NSNumber *migratePersistentStoresAutomaticallyOption = @YES;
        NSNumber *inferMappingModelAutomaticallyOption = @YES;
        NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption : migratePersistentStoresAutomaticallyOption,
                                  NSInferMappingModelAutomaticallyOption : inferMappingModelAutomaticallyOption};
        
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
        [managedDocumentAtUrl release];
        
    }
    [urlToOpen release];
    
}

@end
