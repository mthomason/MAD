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
#import "NSFileManager+Reports.h"

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
#import "RptqQueryGroup.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryField.h"

#import "MTLog.h"
#import "MTQuery.h"
#import "MTReportFormatter.h"
#import "MTAlertView.h"
#import "UIDevice+Hack.h"

#import "NSError+UserInterface.h"
#import "NSError+Constructors.h"
#import "NSThread+Extras.h"
#import "MADocumentState.h"

#import "MTPaper.h"

#import "UIColor+EverydayApps.h"
#import "UIColor+Gradients.h"

#import "MTNotificationDidFormatPage.h"

#import "NSURL+Document.h"

#import "MTActivityIndicator.h"

//Keys stored in the cache.  Short and unique.
NSString * const MTReportSectionType = @"a";
NSString * const MTReportGroupLevel = @"b";
NSString * const MTReportDetailRowId = @"d";

@interface MAReportDocument ()
    <MTDatabaseProtocol>

@property (nonatomic, strong) NSManagedObjectModel *mom;
@property (nonatomic, strong) RptqDocument *document;

@property (nonatomic, strong) NSMutableDictionary *reportQueries;

@property (nonatomic, assign) BOOL didRefresh;

@property (nonatomic, strong) MTDatabase *mainDatabase;
@property (nonatomic, strong) MTQuery *mainQuery;
@property (nonatomic, strong, readwrite) MTDataTable *mainDataTable;

@property (nonatomic, strong) MTActivityIndicator *statusLabel;

@property (nonatomic, strong) MTReportFormatter *printingReportFormatter;   //Used only when printing

@property (nonatomic, strong) NSURL *madUrl;

@end

@implementation MAReportDocument

#pragma mark - Static

+ (NSString *)persistentStoreName {
    return MTPersistentStoreAliasMad;
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

+ (NSString *)fileType {
    return MTDocumentTypeUtiMad;
}

+ (NSURL *)thumbnailUrlForMadUrl:(NSURL *)madUrl {
    return [MAReportDocument thumbnailUrlForHandle:[[madUrl lastPathComponent] stringByDeletingPathExtension]
                                  andRetinaDisplay:[UIDevice isRetnaDisplay]];
}

+ (NSURL *)thumbnailUrlForHandle:(NSString *)handle andRetinaDisplay:(BOOL)retinaDisplay {
    NSString *extention = [UIDevice isRetnaDisplay] ? @"@2x.png": @".png";
    NSString *fileName = [handle stringByAppendingString:extention];
    
    NSString *fileNameId = [NSFileManager filenameId:[handle hash]];
    NSURL *cacheDirectory = [[NSFileManager defaultManager] cacheDirectoryNamed:fileNameId];
    return [cacheDirectory URLByAppendingPathComponent:fileName isDirectory:NO];
}

+ (NSURL *)thumbnailWithBorderUrlForMadUrl:(NSURL *)madUrl {
    return [self thumbnailUrlForMadUrl:madUrl];
}

+ (NSURL *)madFileCheck:(NSURL *)url {
    NSURL *urlToOpen = nil;
    if ([[url pathExtension] isEqualToString:MTDocumentExtentionMobleApplicationDocument]) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *destinationUrl = [fileManager archiveUrlForMadUrl:url];
        [fileManager deleteCoreDataFilesAtDirectory:destinationUrl];
        urlToOpen = [fileManager unpackMadFile:url toDestinationUrl:destinationUrl];
    } else if ([[url pathExtension] isEqualToString:MTDocumentExtentionMobleApplicationDocumentArchive]) {
        urlToOpen = url;
    } else {
        urlToOpen = url;
    }
    return urlToOpen;
}

#pragma mark - NSObject

- (id)initWithFileURL:(NSURL *)url {
    
    self = [super initWithFileURL:[MAReportDocument madFileCheck:url]];
    if (self) {
        
        NSMutableDictionary *reportQueries = [[NSMutableDictionary alloc] init];
        [self setReportQueries:reportQueries];
        [self setDidRefresh:NO];
        
        NSString *name = [self fileNameMinusExtention];
        [self initalizeMainDataTableWithName:name];
        
    }
    
    return self;
}

- (void)dealloc {
    [[_mainQuery database] setDelegate:nil];
}

#pragma mark - Methods

- (void)open:(void (^)(id, BOOL))completionHandler {
    [MAReportDocument report:self open:completionHandler];
}

+ (void)report:(MAReportDocument *)report open:(void (^)(id, BOOL))completion {
    NSNumber *migratePersistentStoresAutomaticallyOption = @(YES);
    NSNumber *inferMappingModelAutomaticallyOption = @(YES);
    NSDictionary *options = @{
                              NSMigratePersistentStoresAutomaticallyOption : migratePersistentStoresAutomaticallyOption,
                              NSInferMappingModelAutomaticallyOption :inferMappingModelAutomaticallyOption,
                              };
    [report setPersistentStoreOptions: options];
    
    __weak MAReportDocument *weakself = report;
    MTCompletionHandlerSuccess handlerOpen = ^(BOOL success) {
        completion(weakself, success);
    };
    
    NSString *path = [report.fileURL path];
    BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:path];
    if (fileExist) {
        [report openWithCompletionHandler:handlerOpen];
    } else {
        [report saveToURL:report.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:handlerOpen];
    }
}

- (void)addDatabaseConnection:(MTDatabaseConnection *)connection
                       status:(void (^)(NSString *readStatus))status
                   completion:(void(^)(BOOL success, NSError *error))completion {
    [MAReportDocument report:self addDatabaseConnection:connection status:status completion:completion];
}

+ (void)report:(MAReportDocument *)report addDatabaseConnection:(MTDatabaseConnection *)connection
        status:(void (^)(NSString *readStatus))status
    completion:(void(^)(BOOL success, NSError *error))completion {
    MTDatabase *database = [MTDatabase databaseFactory:connection];
    
    if (database) {
        RptqDocument *document = [report activeDocument];
        __weak MAReportDocument *weakself = report;
        [document addDatabase:database status:^(NSString *readStatus) {
            status(readStatus);
        } completion:^(BOOL successAddingDatasource, NSError *error) {
            
            if (successAddingDatasource) {
                [weakself closeDocument:^(BOOL success, NSError *error) {
                    completion(success, error);
                }];
            } else {
                [weakself closeAndDeleteDocument:^(BOOL success, NSError *error) {
                    completion(success, error);
                }];
            }
        }];
    } else {
        NSString *title = NSLocalizedString(@"Error", @"Error");
        NSString *message = NSLocalizedString(@"Failed to attach database.", @"Failed to attach database.");
        NSError *error = [NSError errorWithDomain:@"MTReportDocument" code:36732 title:title andMessage:message];
        completion(NO, error);
    }
}

- (MTDataTable *)dataTableForQuery:(MTQuery *)query {
    switch (query.type) {
        case MTQueryTypeFull:
            [[self mainDataTable] setDataDelegate:self];
            return [self mainDataTable];
            break;
        default:
            return nil;
            break;
    }
}

- (NSManagedObjectModel *)managedObjectModel {
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"MAD" ofType:@"momd"];
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return mom;
}

- (RptqDocument *)activeDocument {
    if ([self document] == nil) {
        NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
        RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
        if (document == nil) {
            document = [RptqDocument documentFactoryWithManagedObjectContext:managedObjectContext];
        }
        [self setDocument:document];
        
        if (self.reportFormatter == nil) {
            [self initalizeReportFormatter];
        }
        
        if (self.mainDatabase == nil) {
            [self initalizeMainDatabase];
        }
    }
    return [self document];
}
/*
+ (RptqDocument *)reportActiveDocument:(MAReportDocument *)report {
    if ([report document] == nil) {
        NSManagedObjectContext *managedObjectContext = [report managedObjectContext];
        RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
        if (document == nil) {
            document = [RptqDocument documentFactoryWithManagedObjectContext:managedObjectContext];
        }
        [report setDocument:document];
        
        if (report.reportFormatter == nil) {
            [report initalizeReportFormatter];
        }
        
        if (report.mainDatabase == nil) {
            [report initalizeMainDatabase];
        }
    }
    return [report document];
}
*/
- (MTDatabase *)database {
    return [self mainDatabase];
}

- (void)initalizeMainQuery {
    RptqDatabase *database = [[[self document] hasDatabaseSchemas] anyObject];
    if (database) {
        RptqQuery *rquery = [[database hasQueries] anyObject];
        
        NSDictionary *parameters = [MTQuery queryDefinitionFull:rquery];
        MTQuery *defaultQuery = [[MTQuery alloc] initWithQueryType:MTQueryTypeFull object:parameters];
        [defaultQuery setDataDelegate:self];
        
        [[self mainDataTable] sortUsingDescriptors:[self sortDescriptors]];
        [self setMainQuery:defaultQuery];
    }
}

- (void)initalizeMainDataTableWithName:(NSString *)name {
    NSUInteger hash = [name hash];
    NSNumber *typeKey = @(MTDataTableTypeOfTable);
    NSNumber *type = @(MTDataTableTypePhysical);
    NSNumber *objectIdKey = @(MTDataTableObjectId);
    NSNumber *objectIdV =  @(hash);
    NSDictionary *parameters = @{typeKey : type, objectIdKey : objectIdV};
    MTDataTable *datatable = [MTDataTable dataTableFactory:parameters];
    [datatable setCacheDelegate:self];
    [self setMainDataTable:datatable];
}

- (void)initalizeReportFormatter {
    MTReportFormatter *reportFormatter = [MTReportFormatter reportFormatterFactoryWithQuery: [self defaultQuery]
                                                                              layout: [self activeDocument]
                                                                             options: MTReportFormatterOptionsNone];
    [reportFormatter setDataDelegate:self];
    [reportFormatter setCachedDelegate:self];
    [reportFormatter setDatasource:self];
    [self setReportFormatter:reportFormatter];
}

- (void)initalizeMainDatabase {
    RptqDatabase *database = [[[self document] hasDatabaseSchemas] anyObject];
    RptqQuery *queryObject = [[database hasQueries] anyObject];
    RptqUserCredentals *userCredentals = [[queryObject inDatabase] ownedByUser];
    MTDatabaseConnection *databaseConnection = [MTDatabaseConnection databaseConnectionFactory:userCredentals];
    MTDatabase *db = [MTDatabase databaseFactory:databaseConnection];
    [db setDelegate:self];
    [self setMainDatabase:db];
}

- (void)prepareForQuery {
    [[self mainDataTable] sortUsingDescriptors:[self sortDescriptors]];
}

- (NSEnumerator *)enumeratorForReportData {
    return [[self mainDataTable] enumeratorForKeyObjectsSorted];
}

- (BOOL)cacheExist {
    NSURL *url = [[self mainDataTable] url];
    return [[NSFileManager defaultManager] fileExistsAtPath:[url path]];
}

- (NSDictionary *)dataForCacheId:(NSNumber *)cachedID {
    return  [[self mainDataTable] dataForCacheId:cachedID];
}

- (void)disableUserInteraction:(UIView *)view {
    for (UIView *subview in [view subviews]) {
        if ([subview isKindOfClass:[UILabel class]]) {
            [(UILabel *)subview performSelectorOnMainThread:@selector(setTextColor:) withObject:[UIColor lightGrayColor] waitUntilDone:NO];
        } else if ([subview isKindOfClass:[UIImageView class]]) {
            dispatch_queue_t dipatchQueueMain = dispatch_get_main_queue();
            dispatch_sync(dipatchQueueMain, ^{
                [(UIImageView *)subview setAlpha:0.3333f];
            });
        }
        [self disableUserInteraction:subview];
    }
}

- (void)reportFormatterDidFormatPage:(NSNotification *)sender {
    NSDictionary *parameters = [sender userInfo];
    NSNumber *pageNumber = [parameters objectForKey:MTDatabaseNumberOfPagesFormattedKey];
    NSString *decimalString = [NSNumberFormatter localizedStringFromNumber:pageNumber numberStyle:NSNumberFormatterDecimalStyle];
    NSString *formatString = NSLocalizedString(@"Formatted page %@.", @"Formatted page %@.");
    NSString *readRecords = [NSString stringWithFormat:formatString, decimalString];
    [[self statusLabel].status performSelectorOnMainThread:@selector(setText:) withObject:readRecords waitUntilDone:NO];
}

- (NSString *)fileNameMinusExtention {
    return [[self fileURL] filenameMinusExtention];
}

- (NSUInteger)fileNameHash {
    return [[self fileNameMinusExtention] hash];
}

- (MTQuery *)defaultQuery {
    if ([self mainQuery] == nil) {
        [self initalizeMainQuery];
    }
    return [self mainQuery];
}

- (void)refresh:(void (^)(BOOL success, NSError *error))completion {
    dispatch_queue_t bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(bgQueue, ^{
        NSString *name = [self fileNameMinusExtention];
        [self initalizeMainDataTableWithName:name];
        [self initalizeMainQuery];
        [self initalizeReportFormatter];
        MTQuery *fullQuery = [self defaultQuery];
        [[fullQuery database] setDelegate:self];
        __weak MAReportDocument *weakself = self;
        
        @autoreleasepool {
            [[self database] executeQuery:fullQuery completion:^(BOOL success, NSError *error) {
                [[weakself mainDataTable] cache];
                [weakself setDidRefresh:success];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    completion(success, error);
                });
            }];
        }
    });
}

- (NSURL *)mcacheUrl {
    NSString *fileName = [[NSString stringWithFormat:@"%ld", (unsigned long)[self fileNameHash]] stringByAppendingPathExtension:@"mdcache"];
    return [[self cachedFilesDirectory] URLByAppendingPathComponent:fileName isDirectory:NO];
}

- (NSURL *)maddbUrl {
    NSString *fileName = [[NSString stringWithFormat:@"%ld", (unsigned long)[self fileNameHash]] stringByAppendingPathExtension:@"maddb"];
    return [[self cachedFilesDirectory] URLByAppendingPathComponent:fileName isDirectory:NO];
}

+ (NSURL *)mcacheUrlForFileHandle:(NSString *)filehandle {
    return [MAReportDocument cachedUrlForHash:[filehandle hash] andExtension:@"mcache"];
}

+ (NSURL *)maddbUrlForFileHandle:(NSString *)filehandle {
    return [MAReportDocument cachedUrlForHash:[filehandle hash] andExtension:@"maddb"];
}

+ (NSURL *)cachedUrlForHash:(NSUInteger)hash andExtension:(NSString *)extension {
    NSString *fileName = [NSFileManager filenameId:hash extention:extension];
    NSURL *cachedDirectory = [[NSFileManager defaultManager] cacheDirectoryNamed:fileName];
    return [cachedDirectory URLByAppendingPathComponent:fileName isDirectory:NO];
}

- (NSURL *)thumbnailUrl {
    return [MAReportDocument thumbnailUrlForHandle:[self fileNameMinusExtention] andRetinaDisplay:NO];
}

- (NSURL *)thumbnailRetniaUrl {
    return [MAReportDocument thumbnailUrlForHandle:[self fileNameMinusExtention] andRetinaDisplay:YES];
}

- (NSURL *)cachedDataUrl {
    return [[self mainDataTable] url];
}

- (NSString *)fileHandle {
    return [[[self urlThumbnail] path] lastPathComponent];
}

- (NSString *)fileNameExtensionForType:(NSString *)typeName saveOperation:(UIDocumentSaveOperation)saveOperation {
    return MTDocumentExtentionMobleApplicationDocumentArchive;
}

- (NSString *)fileType {
    return [MAReportDocument fileType];
}

- (void)closeDocument:(void(^)(BOOL success, NSError *error))completion {
    [self closeWithCompletionHandler:^(BOOL success) {
        if (success) {
            [[self documentStatus] setSuspended:YES];
            [[self managedObjectContext] lock];
            [self wrapFileOverwrite:NO completion:^(BOOL success, NSURL *resultUrl) {
                [self deleteFromDiskCompletion:^(BOOL success) {
                    [NSThread completeOnMainThread:completion withObject:nil andSuccess:YES];
                }];
            }];
        }
    }];
}

- (void)closeAndDeleteDocument:(void(^)(BOOL successAddingDatasource, NSError *error))completion {
    [self closeWithCompletionHandler:^(BOOL successClosingReport) {
        if (successClosingReport) {
            [self deleteFromDiskCompletion:^(BOOL successDeletingFromDisk) { }];
            NSError *error = [MAReportDocument errorConnectionProblem];
            [NSThread completeOnMainThread:completion withObject:error andSuccess:NO];
        }
    }];
}

- (void)regenThumbnail {
    [[NSFileManager defaultManager] fileExistsAtPath:[[self urlThumbnail] path]];
    BOOL contentChanged = [self activeDocument] != nil && ([[self documentStatus] contextChagned] == YES || [self didRefresh]) && [[self reportFormatter] numberOfPages] > 0;
    if (contentChanged || [[NSFileManager defaultManager] fileExistsAtPath:[[self urlThumbnail] path]] == NO) {
        MTReportViewerPrintPageRenderer *printPageRender = [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter:[self reportFormatter]
                                                                                                                  dataTable:[self mainDataTable]];
        UIImage *thumbnail = [printPageRender thumbnail];
        NSData *pngImage = UIImagePNGRepresentation(thumbnail);
        [pngImage writeToURL:[self urlThumbnail] atomically:YES];
    }
}

- (NSArray *)sortDescriptors {
    
    if (self.mainDatabase == nil) {
        [self initalizeMainDatabase];
    }
    
    RptqDatabase *database = [[[self document] hasDatabaseSchemas] anyObject];
    RptqQuery *rquery = [[database hasQueries] anyObject];

    NSMutableArray *sortedSortDescriptorsGroup = [[NSMutableArray alloc] init];
    
    for (RptqQueryGroup *queryGroup in [rquery sortedQueryGroups]) {
        @autoreleasepool {
            BOOL sortAscending = ([[queryGroup sort] integerValue] == MNSSortOrderAccending);
            RptqQueryField *groupField = [queryGroup hasField];
            
            NSString *queryTable = [[groupField inQueryTable] queryAlias];
            NSString *safeQueryTable = [[self mainDatabase] safeIdentifier:queryTable];
            NSString *fieldName = [[groupField databaseSchemaField] name];
            NSString *safeFieldName = [[self mainDatabase] safeIdentifier:fieldName];
            NSString *keyFirstPart = [safeQueryTable stringByAppendingString:@"."];
            NSString *key = [keyFirstPart stringByAppendingString: safeFieldName];
            
            SEL sel = [MTDatabaseField selectorForSorting:[[[groupField databaseSchemaField] dataType] integerValue]];
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: key
                                                                           ascending: sortAscending
                                                                            selector: sel];
            [sortedSortDescriptorsGroup addObject:sortDescriptor];
        }
    }
    
    return sortedSortDescriptorsGroup;
}

- (UIPrintPageRenderer *)printerPrintPageRender {
    MTReportFormatter *reportFormatter = [MTReportFormatter reportFormatterFactoryWithQuery: [self defaultQuery]
                                                                              layout: [self activeDocument]
                                                                             options: MTReportFormatterOptionsMargin];
    
    [reportFormatter setCachedDelegate:self];
    [reportFormatter setOverrideIdentifier:@"madprinter"];
    [reportFormatter setDatasource:self];
    
    MTReportViewerPrintPageRenderer *printPageRender = [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter:reportFormatter
                                                                                                              dataTable:[self mainDataTable]];
    [self setPrintingReportFormatter:reportFormatter];
    return printPageRender;

}

- (CGRect)statusViewRect {
    return CGRectMake(CGPointZero.x, CGPointZero.y, 230.0000f, 200.0000f);
}

- (void)writeToPdf:(NSURL *)filepath withViewController:(UIViewController *)window {
    [self disableUserInteraction:window.view];

    MTActivityIndicator *activityView = [[MTActivityIndicator alloc] initWithFrame:[self statusViewRect]];
    activityView.center = window.view.center;
    
    [window.view performSelectorOnMainThread:@selector(addSubview:) withObject:activityView waitUntilDone:YES];
    [self setStatusLabel:activityView];
    
    
    __weak MAReportDocument *weakself = self;
    
    dispatch_semaphore_t s1 = dispatch_semaphore_create(0);
    
    dispatch_queue_t dipatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(dipatchQueue, ^{
        
        
        NSDictionary *options = @{(NSString *)kCGPDFContextCreator :  @"MAD® Designer"};
        CGRect letterRect = [MTPaper rectLetter];
        [[weakself mainDataTable] sortUsingDescriptors:[weakself sortDescriptors]];
        MTReportFormatter *rf = [MTReportFormatter reportFormatterFactoryWithQuery:weakself.mainQuery
                                                                     layout:weakself.document
                                                                    options:MTReportFormatterOptionsMargin];
        [rf setCachedDelegate:weakself];
        [rf setDataDelegate:weakself];
        [rf setOverrideIdentifier:@"madpreview"];
        
        [[NSNotificationCenter defaultCenter] addObserver: weakself
                                                 selector: @selector(reportFormatterDidFormatPage:)
                                                     name: MTNotificationDidFormatPagesName
                                                   object: rf];
        
        
        [rf setDatasource:weakself];
        [rf reformatForSize:letterRect.size];
        
        
        [[NSNotificationCenter defaultCenter] removeObserver: weakself
                                                        name: MTNotificationDidFormatPagesName
                                                      object: rf];
        
        MTReportViewerPrintPageRenderer *printPageRender = [[MTReportViewerPrintPageRenderer alloc] initWithReportFormatter:rf
                                                                                                                  dataTable:[weakself mainDataTable]];
        NSUInteger numberOfPages = [rf numberOfPages];
        UIGraphicsBeginPDFContextToFile([filepath path], letterRect, options);
        
        
        NSDictionary *boxInfo = @{(__bridge NSString *)kCGPDFContextTrimBox: [NSValue valueWithCGRect:letterRect]};
        NSString *numberOfPagesString = [NSNumberFormatter localizedStringFromNumber:@(numberOfPages) numberStyle:NSNumberFormatterDecimalStyle];
        for (NSUInteger i=0; i<numberOfPages; i++) {
            @autoreleasepool {
                UIGraphicsBeginPDFPageWithInfo(letterRect, boxInfo);
                [printPageRender drawPageAtIndex:i inRect:letterRect];
                NSString *iString = [NSNumberFormatter localizedStringFromNumber:@(i) numberStyle:NSNumberFormatterDecimalStyle];
                NSString *text = [NSString stringWithFormat:@"Drawing page %@ of %@.", iString, numberOfPagesString];
                [activityView.status performSelectorOnMainThread:@selector(setText:) withObject:text waitUntilDone:NO];
            }
        }
        UIGraphicsEndPDFContext();
        
        dispatch_semaphore_signal(s1);
        
    });
    dispatch_semaphore_wait(s1, DISPATCH_TIME_FOREVER);
    [activityView removeFromSuperview];
    
}

#pragma mark - UIPrintInteractionControllerDelegate

- (void)printInteractionControllerWillPresentPrinterOptions:(UIPrintInteractionController *)printInteractionController { }
- (void)printInteractionControllerWillDismissPrinterOptions:(UIPrintInteractionController *)printInteractionController { }
- (void)printInteractionControllerDidPresentPrinterOptions:(UIPrintInteractionController *)printInteractionController {}
- (void)printInteractionControllerDidDismissPrinterOptions:(UIPrintInteractionController *)printInteractionController {}

- (void)printInteractionControllerWillStartJob:(UIPrintInteractionController *)printInteractionController {
    UIPrintPaper *printPaper = printInteractionController.printPaper;
    [self.printingReportFormatter setDataDelegate:self];
    [self.printingReportFormatter setLayoutSize:printPaper.paperSize];
    [self.printingReportFormatter setMarginUsingPrintableRect:printPaper.printableRect];
    [self.printingReportFormatter setDidRefresh:YES];   //Force formatting
    [self.printingReportFormatter reformatForSize:printPaper.paperSize];
}
- (void)printInteractionControllerDidFinishJob:(UIPrintInteractionController *)printInteractionController {
    [self setPrintingReportFormatter:nil];
}

@end
