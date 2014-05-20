//
//  MNSDocumentReport.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

typedef void (^MTCompletionHandlerSuccess)(BOOL success);

#import "MAReportDocument.h"
#import <UIKit/UIKit.h>
#import "MTDatabaseSqlite3.h"
#import "MTReportViewerPrintPageRenderer.h"
#import "MTDatabaseTable.h"
#import "MTDatabaseField.h"
#import "MTDataTable.h"
#import "NSFileManager+Common.h"

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
#import "MTReportFormatter.h"
#import "MTAlertView.h"
#import "UIDevice+Hack.h"

#import "NSError+UserInterface.h"
#import "NSError+Constructors.h"


NSString * const MTReportSectionType = @"MTReportSectionType";
NSString * const MTReportSectionValues = @"MTReportSectionValues";
NSString * const MTReportGroupLevel = @"MTReportGroupLevel";
NSString * const MTReportGroupLevelKeys = @"MTReportGroupLevelKeys";
NSString * const MTReportDetailRowId = @"MTReportDetailRowId";
NSString * const MTPageDetail = @"MTPageDetail";
NSString * const MTPageHeader = @"MTPageHeader";
NSString * const MTPageFooter = @"MTPageFooter";
NSString * const MTReportHeader = @"MTReportHeader";
NSString * const MTReportFooter = @"MTReportFooter";
NSString * const MTReportGroupHeader = @"MTReportGroupHeader";
NSString * const MTReportGroupFooter = @"MTReportGroupFooter";

@interface MAReportDocument ()

@property (nonatomic, strong) NSManagedObjectModel *mom;
@property (nonatomic, strong) RptqDocument *document;

@property (nonatomic, strong) NSMutableDictionary *reportQueries;

@property (nonatomic, assign) BOOL didRefresh;

@end

@implementation MAReportDocument

- (id)initWithFileURL:(NSURL *)url {
    self = [super initWithFileURL:url];
    if (self) {

        NSMutableDictionary *reportQueries = [[NSMutableDictionary alloc] init];
        [self setReportQueries:reportQueries];
        [self setDidRefresh:NO];
        
    }
    return self;
}

- (NSManagedObjectModel *)managedObjectModel {
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"MAD" ofType:@"momd"];
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return mom;
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
        [self setDocument:document];
        
        // FIXME: Only one query for a report at this time.
        RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
        RptqQuery *rquery = [[database hasQueries] anyObject];
        if (rquery) {
            
            NSString *name = [[[[self urlThumbnail] path]lastPathComponent] stringByDeletingPathExtension];
            NSNumber *parameterName = @(MTQueryCacheFullReportName);
            NSNumber *parameterSchema = @(MTQueryCacheFullQuerySchema);
            NSDictionary *queryFullParameters = @{
                                                  parameterName : name,
                                                  parameterSchema : rquery
                                                  };
            
            MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeFull object:queryFullParameters];
            if (query) {
                [self reportQueries][@"defaultq"] = query;
            }
            
            if ([self reportFormatter] == nil) {
                MTQuery *defaultQuery = [self defaultQuery];
                RptqDocument *activeDocument = [self activeDocument];
                MTReportFormatter *reportFormatter = [MTReportFormatter reportFormatterWithQuery:defaultQuery
                                                                                       andLayout:activeDocument];
                [self setReportFormatter:reportFormatter];
            }
        }
    }
    return [self document];
}

//Add a new connection to the report
- (void)addDatasourceToReport: (MTDatabase *)database
                   completion: (void (^)(BOOL success, NSError *error))completion {

    RptqDocument *document = [self activeDocument];
    [RptqDocument addDatabase:database toDocument:document completion:^(BOOL success, NSError *error) {
        completion(success, error);
    }];
}

- (MTQueryFull *)defaultQuery {
    return [self reportQueries][@"defaultq"];
}

- (void)refresh:(void (^)(BOOL success, NSError *error))completion {

    [[self defaultQuery] performQuery:^(BOOL success, NSError *error) {
        [self setDidRefresh:success];
        completion(success, error);
    }];
}

- (NSURL *)cachedDataUrl {
    return [[[self defaultQuery] datatable] url];
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
    NSString *destinationName = [[[madUrl lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:MTDocumentExtentionMobleApplicationDocumentArchive];
    NSURL *destinationDirectoryUrl = [NSFileManager localTemporaryDirectory];
    NSArray *directories = NSSearchPathForDirectoriesInDomains(NSAutosavedInformationDirectory, NSUserDomainMask, YES);
    [directories lastObject];
    return [destinationDirectoryUrl URLByAppendingPathComponent:destinationName isDirectory:YES];
}

+ (NSURL *)thumbnailUrlForMadUrl:(NSURL *)madUrl {
    NSString *lastPathComponent = [madUrl lastPathComponent];
    NSString *fileName = [lastPathComponent stringByDeletingPathExtension];
    NSString *extention = [UIDevice isRetnaDisplay] ? @"@2x.png": @".png";
    fileName = [fileName stringByAppendingString:extention];
    
    NSURL *cacheDirectory = [NSFileManager cacheDirectory];
    return [cacheDirectory URLByAppendingPathComponent:fileName isDirectory:NO];
}

+ (NSURL *)thumbnailWithBorderUrlForMadUrl:(NSURL *)madUrl {
    return [self thumbnailUrlForMadUrl:madUrl];
}

+ (void)deleteCoreDataFilesAtDirectory:(NSURL *)destinationUrl {
    NSFileManager *fileManager = [NSFileManager defaultManager];
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
            urlToOpen = destinationUrl;
        }
    } else {
        urlToOpen = url;
    }
    return urlToOpen;
}

+ (MAReportDocument *)openManagedDocumentAtUrl:(NSURL *)url withCompletionHandler:(void (^)(id, BOOL))completionHandler {
    MAReportDocument *managedDocumentAtUrl = nil;
    NSURL *urlToOpen = nil;
    if ([[url pathExtension] isEqualToString:MTDocumentExtentionMobleApplicationDocument]) {
        
        NSURL *destinationUrl = [MAReportDocument archiveUrlForMadUrl:url];
        [MAReportDocument deleteCoreDataFilesAtDirectory:destinationUrl];
        urlToOpen = [MAReportDocument unpackMadFile:url toDestinationUrl:destinationUrl];
        
    } else if ([[url pathExtension] isEqualToString:MTDocumentExtentionMobleApplicationDocumentArchive]) {
        urlToOpen = url;
    }
    
    if (urlToOpen != nil) {
        managedDocumentAtUrl = [[MAReportDocument alloc] initWithFileURL:urlToOpen];
        NSDictionary *options = @{
                                  NSMigratePersistentStoresAutomaticallyOption : @(YES),
                                  NSInferMappingModelAutomaticallyOption : @(YES),
                                  };
        [managedDocumentAtUrl setPersistentStoreOptions: options];
        
        __block __weak MAReportDocument *blockManagedDocumentAtUrl = managedDocumentAtUrl;
        MTCompletionHandlerSuccess handlerOpen = ^(BOOL success) {
                completionHandler(blockManagedDocumentAtUrl, success);
        };

        BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:[urlToOpen path]];
        if (fileExist) {
            [blockManagedDocumentAtUrl openWithCompletionHandler:handlerOpen];
        } else {
            [blockManagedDocumentAtUrl saveToURL:url forSaveOperation:UIDocumentSaveForCreating completionHandler:handlerOpen];
        }
        
        options = nil;

    }
    return managedDocumentAtUrl;
}

+ (void)initalSaveUsingUrl:(NSURL *)applicationFileUrlWithExtention andConnection:(MTDatabaseConnection *)databaseConnection completion:(void(^)(BOOL success, NSError *error))completion {
    
    
    MTQuery *queryTest = [[MTQuery alloc] initWithQueryType:MTQueryTypeConnectionTest object:databaseConnection];
    [queryTest performQuery:^(BOOL success, NSError *error) {
        
        if (!success) {
            completion(NO, error);
        } else {
            
            [MAReportDocument openManagedDocumentAtUrl:applicationFileUrlWithExtention withCompletionHandler:^(id managedDocument, BOOL success) {
                
                if (success) {
                    
                    __block __weak MAReportDocument *documentReport = managedDocument;

                    RptqDocument *rptqDocument = [documentReport activeDocument];
                    MTDatabase *database = [MTDatabase databaseFactory:databaseConnection];
                    
                    if (database) {
                        
                        [self addDatabase:database toDocument:rptqDocument ofDocumentReport:documentReport completion:^(BOOL success, NSError *error){
                            completion(success, error);
                        }];
                        
                    }
                    
                } else {
                    NSError *error = [MAReportDocument errorFailedToCreateReport];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(NO, error);
                    });
                }
            }];

        }
    }];

}

+ (void)addDatabase:(MTDatabase *)database toDocument:(RptqDocument *)document ofDocumentReport:(MAReportDocument *)documentReport completion:(void(^)(BOOL successAddingDatasource, NSError *error))completion {

    [RptqDocument addDatabase:database toDocument:document completion:^(BOOL successAddingDatasource, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (successAddingDatasource) {

                [self closeReportDocument:documentReport withCompletion:^(BOOL success, NSError *error) {
                    completion(success, error);
                }];
                
            } else {
                [self discardReportDocument:documentReport withCompletion:^(BOOL success, NSError *error) {
                    completion(success, error);
                }];
            }
        });
    }];

}


+ (void)closeReportDocument:(MAReportDocument *)documentReport withCompletion:(void(^)(BOOL success, NSError *error))completion {

    [documentReport closeWithCompletionHandler:^(BOOL success) {
        if (success) {
            [documentReport setSuspended:YES];
            [[documentReport managedObjectContext] lock];
            [NSFileManager wrapFile:[documentReport fileURL] withExtention:MTDocumentExtentionMobleApplicationDocument overwrite:NO completion:^(BOOL success, NSURL *resultUrl) {
                [documentReport deleteFromDiskCompletion:^(BOOL success) {
                    if ([NSThread isMainThread]) {
                        completion(YES, nil);
                    } else {
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            completion(YES, nil);
                        });
                    }
                }];
            }];
        }
    }];
}

+ (void)discardReportDocument:(MAReportDocument *)documentReport withCompletion:(void(^)(BOOL successAddingDatasource, NSError *error))completion {
    [documentReport closeWithCompletionHandler:^(BOOL successClosingReport) {
        if (successClosingReport) {
            [documentReport deleteFromDiskCompletion:^(BOOL successDeletingFromDisk) { }];
            NSError *error = [MAReportDocument errorConnectionProblem];
            if ([NSThread isMainThread]) {
                completion(NO, error);
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO, error);
                });
            }
            
        }
    }];

}

+ (NSError *)errorConnectionProblem {
    NSString *title = NSLocalizedString(@"Connection Problem", @"Connection Problem");
    NSString *message = NSLocalizedString(@"Could not connect to database.", @"Could not connect to database.");
    return [NSError errorWithDomain:@"MTReportDocument" code:36732 title:title andMessage:message];
}

+ (NSError *)errorFailedToCreateReport {
    NSString *title = NSLocalizedString(MNSInterfaceTitleProblem, MNSInterfaceTitleProblem);
    NSString *message = NSLocalizedString(MNSInterfaceMessageErrorFailedToCreateReport, MNSInterfaceMessageErrorFailedToCreateReport);
    return [NSError errorWithDomain:@"MTReportDocument" code:36732 title:title andMessage:message];
}

- (void)regenThumbnail {

    if ([self activeDocument] != nil) {
        MTReportViewerPrintPageRenderer *printPageRender = [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter:[self reportFormatter]];
        UIImage *thumbnail = [printPageRender thumbnail];
        NSData *pngImage = UIImagePNGRepresentation(thumbnail);
        [pngImage writeToURL:[self urlThumbnail] atomically:YES];
    }
    
}

@end
