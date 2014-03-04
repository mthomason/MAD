//
//  MNSDocumentReport.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

typedef void (^MTCompletionHandlerSuccess)(BOOL success);

#import "MAReportDocument.h"
#import "MTDatabaseSqlite3.h"
#import "MTReportViewerPrintPageRenderer.h"
#import "MTDatabaseTable.h"
#import "MTDatabaseField.h"

#import "RptqDocument+Extras.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaTable+Extras.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqDatabase+Extras.h"
#import "RptqUserCredentals+Extras.h"

#import "MTLog.h"
#import "UIDevice+Hack.h"

@interface MAReportDocument ()

@property (nonatomic, retain) NSManagedObjectModel *mom;
@property (nonatomic, retain) RptqDocument *document;

@end

@implementation MAReportDocument

- (void)dealloc {
    [_document release];
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

- (void)cacheQueryResult:(id)queryResult {
    [[self delegateCacheData] cacheQueryResult:queryResult];
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
    [mnsDatabase setDelegateCacheData:self];
    
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

+ (NSURL *)cachedDataFileUrlForFileUrl:(NSURL *)fileUrl {
    NSString *name = [[[fileUrl lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"cache"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesPath = [paths objectAtIndex:0];
    NSURL *cachesUrl = [NSURL fileURLWithPath:cachesPath isDirectory:YES];
    NSURL *url = [[cachesUrl URLByAppendingPathComponent:name isDirectory:NO] retain];
    return [url autorelease];
}

- (NSURL *)cachedDataUrl {
    NSURL *fileUrl = [self fileURL];
    NSURL *result = [[MAReportDocument cachedDataFileUrlForFileUrl:fileUrl] retain];
    return [result autorelease];
}

- (void)emptyCache {
    RptqDocument *document = [self document];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    RptqQueryCache *queryCache = [[RptqQueryCache initObjectForManagedObjectContext:[self managedObjectContext]] retain];
    NSError *error = nil;
    NSArray *emptyArray = @[];
    NSData *cachedData = [NSPropertyListSerialization dataWithPropertyList:emptyArray format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
    NSURL *url = [[self cachedDataUrl] retain];
    [cachedData writeToURL:url options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen error:&error];
    if (error) {
        error = nil;
        [cachedData writeToURL:url options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen error:&error];
    }
    [url release];
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

+ (NSURL *)archiveUrlForMadUrl:(NSURL *)madUrl {
    NSString *destinationName = [[[[madUrl lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:MTDocumentExtentionMobleApplicationDocumentArchive] retain];
    NSURL *destinationDirectoryUrl = [[NSFileManager localTemporaryDirectory] retain];
    NSArray *directories = NSSearchPathForDirectoriesInDomains(NSAutosavedInformationDirectory, NSUserDomainMask, YES);
    [directories lastObject];
    NSURL *destinationUrl = [[destinationDirectoryUrl URLByAppendingPathComponent:destinationName isDirectory:YES] retain];
    [destinationName release];
    [destinationDirectoryUrl release];
    return [destinationUrl autorelease];
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

+ (NSURL *)thumbnailWithBorderUrlForMadUrl:(NSURL *)madUrl {
    return [[[self thumbnailUrlForMadUrl:madUrl] retain] autorelease];
/*
    NSString *lastPathComponent = [madUrl lastPathComponent];
    NSString *fileName = [lastPathComponent stringByDeletingPathExtension];
    NSString *fileNameWithBorder = [fileName stringByAppendingString:@"WithBorder"];
    NSString *extention = [UIDevice isRetnaDisplay] ? @"@2x.png": @".png";
    fileNameWithBorder = [fileNameWithBorder stringByAppendingString:extention];
    NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [directoryPaths lastObject];
    NSURL *thumbnailPath = [NSURL fileURLWithPath: cacheDirectory];
    NSURL *result = [[thumbnailPath URLByAppendingPathComponent:fileNameWithBorder isDirectory:NO] retain];
    return [result autorelease];
 */
}

+ (void)deleteCoreDataFilesAtDirectory:(NSURL *)destinationUrl {
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
}

+ (NSURL *)unpackMadFile:(NSURL *)url toDestinationUrl:(NSURL *)destinationUrl {
    NSURL *urlToOpen = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL fileexist = [fileManager fileExistsAtPath:[url path]];
    if (fileexist) {
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
        [fileWrapper release];
        [data release];
    } else {
        urlToOpen = [url retain];
    }
    return [urlToOpen autorelease];
}

+ (NSDictionary *)optionsPersistentStore{
    NSNumber *migratePersistentStoresAutomaticallyOption = @YES;
    NSNumber *inferMappingModelAutomaticallyOption = @YES;
    return @{
             NSMigratePersistentStoresAutomaticallyOption : migratePersistentStoresAutomaticallyOption,
             NSInferMappingModelAutomaticallyOption : inferMappingModelAutomaticallyOption,
             };
}

+ (void)openManagedDocumentAtUrl:(NSURL *)url withCompletionHandler:(void (^)(id, BOOL))completionHandler {
    
    NSURL *urlToOpen = nil;
    if ([[url pathExtension] isEqualToString:MTDocumentExtentionMobleApplicationDocument]) {
        
        NSURL *destinationUrl = [[MAReportDocument archiveUrlForMadUrl:url] retain];
        [MAReportDocument deleteCoreDataFilesAtDirectory:destinationUrl];
        urlToOpen = [[MAReportDocument unpackMadFile:url toDestinationUrl:destinationUrl] retain];
        [destinationUrl release];
        
    } else if ([[url pathExtension] isEqualToString:MTDocumentExtentionMobleApplicationDocumentArchive]) {
        urlToOpen = [url retain];
    }
    
    if (urlToOpen != nil) {

        NSDictionary *options = [MAReportDocument optionsPersistentStore];
        MAReportDocument *managedDocumentAtUrl = [[[MAReportDocument alloc] initWithFileURL:urlToOpen] retain];
        [managedDocumentAtUrl setPersistentStoreOptions: options];
        
        __block MAReportDocument *blockManagedDocumentAtUrl = managedDocumentAtUrl;
        MTCompletionHandlerSuccess handlerOpen = ^(BOOL success) {
            MAReportDocument *activeDocument = [blockManagedDocumentAtUrl retain];
            completionHandler(activeDocument, success);
            [activeDocument release];
        };

        BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:[urlToOpen path]];
        if (fileExist) {
            [blockManagedDocumentAtUrl openWithCompletionHandler:handlerOpen];
        } else {
            [blockManagedDocumentAtUrl saveToURL:url forSaveOperation:UIDocumentSaveForCreating completionHandler:handlerOpen];
        }

        [managedDocumentAtUrl release];
    }
    [urlToOpen release];
    
}

+ (void)initalSaveUsingUrl:(NSURL *)applicationFileUrlWithExtention andConnection:(MTDatabaseConnection *)databaseConnection completion:(void(^)(BOOL success))completion {
    
    [MAReportDocument openManagedDocumentAtUrl:applicationFileUrlWithExtention withCompletionHandler:^(id managedDocument, BOOL success) {
        
        if (success) {
            
            __block MAReportDocument *documentReport = managedDocument;
            [databaseConnection retain];
            
            id database = nil;
            NSString *databaseId = [databaseConnection databaseTypeIdentifier];
            
            if ([databaseId isEqualToString:MTSegueShowSetUpDatasourceMySqlIdentifier]) {
                
                database = [[MTDatabaseMySql alloc] initWithConnectionSettings:databaseConnection];
                
            } else if ([databaseId isEqualToString:MTSegueShowSetUpDatasourceSqlServerIdentifier]) {
                
                database = [[MTDatabaseSqlServer alloc] initWithConnectionSettings:databaseConnection];
                
            } else if ([databaseId isEqualToString:[MTDatabaseSqlite3 identifier]]) {
                
                database = [[MTDatabaseSqlite3 alloc] initWithConnectionSettings:databaseConnection];
            }
            
            if (database) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [RptqDocument addDatabase:database toDocument:[documentReport activeDocument] completion:^(BOOL successAddingDatasource, NSError *error) {
                        
                        MTCompletionHandlerSuccess completeSuccess = ^(BOOL success) {
                            dispatch_sync(dispatch_get_main_queue(), ^{
                                completion(YES);
                            });
                        };
                        
                        MTCompletionHandlerSuccess completeFail = ^(BOOL success) {
                            dispatch_sync(dispatch_get_main_queue(), ^{
                                completion(YES);
                            });
                        };

                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (successAddingDatasource) {
                                
                                MTCompletionHandlerSuccess handlerClose = ^(BOOL success) {
                                    if (success) {
                                        [documentReport setSuspended:YES];
                                        [[documentReport managedObjectContext] lock];
                                        [NSFileManager wrapFile:[documentReport fileURL] withExtention:MTDocumentExtentionMobleApplicationDocument overwrite:NO completion:^(BOOL success, NSURL *resultUrl) {
                                            [documentReport deleteFromDiskCompletion:completeSuccess];
                                        }];
                                    }
                                };
                                
                                [documentReport closeWithCompletionHandler:handlerClose];
                                
                            } else {
                                [documentReport closeWithCompletionHandler:^(BOOL successClosingReport) {
                                    if (successClosingReport) {
                                        
                                        [documentReport deleteFromDiskCompletion:^(BOOL successDeletingFromDisk) { }];
                                        
                                        if (error) {
                                            
                                            [error presentErrorToUserWithCompletion:completeFail];
                                            
                                        } else {
                                            
                                            NSString *connectionProblem = NSLocalizedString(@"Connection Problem", @"Connection Problem");
                                            NSString *connectionMessage = NSLocalizedString(@"Could not connect to database.", @"Could not connect to database.");
                                            NSString *connectionCancel = NSLocalizedString(@"Cancel", @"Cancel");
                                            
                                            MTAlertView *alertView = [[MTAlertView alloc] initWithTitle: connectionProblem message: connectionMessage cancelButtonTitle: connectionCancel otherButtonTitle:nil onDismiss:^(NSInteger buttonIndex) {
                                                completion(NO);
                                            } onCancel:^{
                                                completion(NO);
                                            }];
                                            [alertView show];
                                            [alertView autorelease];
                                            
                                        }
                                    }
                                }];
                                
                            }
                        });
                    }];
                });
            }
            
            [databaseConnection release];
            [database release];
            
        } else {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                MTAlertView *alertView = [[MTAlertView alloc] initWithTitle: NSLocalizedString(MNSInterfaceTitleProblem, MNSInterfaceTitleProblem)
                                                                    message: NSLocalizedString(MNSInterfaceMessageErrorFailedToCreateReport, MNSInterfaceMessageErrorFailedToCreateReport)
                                                          cancelButtonTitle: NSLocalizedString(MNSInterfaceButtonDismiss, MNSInterfaceButtonDismiss)
                                                           otherButtonTitle: nil onDismiss:^(NSInteger buttonIndex) {
                                                               
                                                           } onCancel:^{
                                                               
                                                           }];
                [alertView show];
                [alertView autorelease];
            });
        }
    }];
    
}

- (void)regenThumbnail {
    RptqDocument *document = [[self activeDocument] retain];
    if (document != nil) {
        MTReportViewerPrintPageRenderer *printPageRender = [[MTReportViewerPrintPageRenderer alloc] initWithDocument:self];
        UIImage *thumbnail = [printPageRender thumbnail];
        NSData *pngImage = UIImagePNGRepresentation(thumbnail);
        [pngImage writeToURL:[self urlThumbnail] atomically:YES];
        [printPageRender release];
    }
    [document release];
}

@end
