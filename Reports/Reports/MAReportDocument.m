//
//  MNSDocumentReport.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
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
#import "RptqQueryCache+Extras.h"
#import "RptqQuery.h"
#import "RptqQuery+Extras.h"

#import "MTLog.h"
#import "MTQuery.h"
#import "MTCache.h"
#import "MTQueryReport.h"

#import "MTReportFormatter.h"

#import "UIDevice+Hack.h"

NSString * const MTReportSectionType = @"MTReportSectionType";
NSString * const MTReportSectionValues = @"MTReportSectionValues";
NSString * const MTReportGroupLevel = @"MTReportGroupLevel";

NSString * const MTPageDetail = @"MTPageDetail";
NSString * const MTPageHeader = @"MTPageHeader";
NSString * const MTPageFooter = @"MTPageFooter";
NSString * const MTReportHeader = @"MTReportHeader";
NSString * const MTReportFooter = @"MTReportFooter";
NSString * const MTReportGroupHeader = @"MTReportGroupHeader";
NSString * const MTReportGroupFooter = @"MTReportGroupFooter";

@interface MAReportDocument ()

@property (nonatomic, retain) NSManagedObjectModel *mom;
@property (nonatomic, retain) RptqDocument *document;

@property (nonatomic, retain) NSMutableDictionary *reportQueries;

@property (nonatomic, assign) BOOL didRefresh;

// Below this be page caching fu
/*

@property (nonatomic, assign) CGSize printableSize;
@property (nonatomic, assign) CGRect printableRect;

@property (nonatomic, assign) CGSize cachedPageSize;

@property (nonatomic, assign) NSUInteger temporaryCachedDetailCounter;

@property (nonatomic, assign) CGFloat printableSpaceUsedPageHeight;

@property (nonatomic, retain) NSArray *cachedDataByPage;
@property (nonatomic, retain) NSArray *cachedLayoutByPage;

@property (nonatomic, retain) NSArray *sortedQueryGroups;
@property (nonatomic, retain) NSArray *cachedSortedSortDescriptorsGroup;
@property (nonatomic, retain) NSArray *cachedDataByReport;
@property (nonatomic, retain) NSDictionary *cachedDataByGroup;

@property (nonatomic, retain) NSMutableArray *temporaryLayoutForPage;
@property (nonatomic, retain) NSMutableArray *temporaryDataForPage;
@property (nonatomic, retain) NSMutableArray *temporaryLayoutByPage;
@property (nonatomic, retain) NSMutableArray *temporaryDataByPage;
*/

@end

@implementation MAReportDocument

- (void)dealloc {
/*    [_cachedLayoutByPage release];
    [_cachedSortedSortDescriptorsGroup release];
    [_cachedDataByPage release];
    [_cachedDataByGroup release];
    [_cachedDataByReport release];
    [_temporaryLayoutByPage release]; _temporaryLayoutByPage = nil;
    [_temporaryLayoutForPage release]; _temporaryLayoutForPage = nil;
    [_temporaryDataByPage release]; _temporaryDataByPage = nil;
    [_temporaryDataForPage release]; _temporaryDataForPage = nil;
    [_sortedQueryGroups release]; _sortedQueryGroups = nil;*/
    [_reportQueries release];
    [_document release];
    [_mom release];
    [super dealloc];
}

- (id)initWithFileURL:(NSURL *)url {
    self = [super initWithFileURL:url];
    if (self) {

        NSMutableDictionary *reportQueries = [[NSMutableDictionary alloc] init];
        [self setReportQueries:reportQueries];
        [reportQueries release];
        
        [self setDidRefresh:NO];
        
    }
    return self;
}

- (NSManagedObjectModel *)managedObjectModel {
    NSManagedObjectModel *result = [self mom];
    if (result == nil) {
        NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"MAD" ofType:@"momd"];
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
        
        // FIXME: Only one query for a report at this time.
        RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
        RptqQuery *rquery = [[database hasQueries] anyObject];
        MTQuery *query = [[MTQuery queryFactory:rquery] retain];
        if (query) {
            [self reportQueries][@"defaultq"] = query;
        }
        [query release];

        if ([self reportFormatter] == nil) {
            MTReportFormatter *reportFormatter = [[MTReportFormatter reportFormatterWithQuery:[self defaultQuery]
                                                                                        andLayout:[self activeDocument]] retain];
            [self setReportFormatter:reportFormatter];
            [reportFormatter release];
        }
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

- (MTQueryReport *)defaultQuery {
    MTQueryReport *defaultQuery = [[self reportQueries][@"defaultq"] retain];
    return [defaultQuery autorelease];
}

- (void)refresh:(void (^)(BOOL success, NSError *error))completion {

    MTQuery *defaultQuery = [[self defaultQuery] retain];
    [[self defaultQuery] performQuery:^(BOOL success, NSError *error, id results) {
        [[defaultQuery cache] cacheData:results];
        [self setDidRefresh:success];
        completion(success, error);
    }];
    [defaultQuery release];
}

- (NSURL *)cachedDataUrl {
    return [[[[[self defaultQuery] cache] url] retain] autorelease];
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
            
            RptqDocument *rptqDocument = [[documentReport activeDocument] retain];
            MTDatabase *database = [[MTDatabase databaseFactory:databaseConnection] retain];
            
            if (database) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [RptqDocument addDatabase:database toDocument:rptqDocument completion:^(BOOL successAddingDatasource, NSError *error) {
                        
                        MTCompletionHandlerSuccess completeSuccess = ^(BOOL success) {
                            if ([NSThread isMainThread]) {
                                completion(YES);
                            } else {
                                dispatch_sync(dispatch_get_main_queue(), ^{
                                    completion(YES);
                                });
                            }
                        };
                        
                        MTCompletionHandlerSuccess completeFail = ^(BOOL success) {
                            if ([NSThread isMainThread]) {
                                completion(YES);
                            } else {
                                dispatch_sync(dispatch_get_main_queue(), ^{
                                    completion(YES);
                                });
                            }
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
            
            [rptqDocument release];
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

        MTReportViewerPrintPageRenderer *printPageRender = [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter:[self reportFormatter]];
        UIImage *thumbnail = [printPageRender thumbnail];
        NSData *pngImage = UIImagePNGRepresentation(thumbnail);
        [pngImage writeToURL:[self urlThumbnail] atomically:YES];
        [printPageRender release];
        
    }
    [document release];
}

@end
