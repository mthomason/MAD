//
//  NSDatabase.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Constants.h"
#import "UIManagedDocumentQuery.h"
#import "RptqQueryLinks+Extras.h"
#import "NSFileManager+Common.h"

typedef enum {
	NSDatabaseQueryTypeNone = 0,
	NSDatabaseQueryTypeGetTables,
	NSDatabaseQueryTypeGetFields,
	NSDatabaseQueryTypeGetResults,
	NSDatabaseQueryTypeVerify
} NSDatabaseQueryType;

typedef void (^rsltBlk_filePath)(BOOL success);

@interface NSDatabase : NSObject

@property (retain, nonatomic) UIManagedDocumentQuery *managedDocumentQuery;

- (id)initNewFileWithName:(NSString *)name completion:(void (^)(BOOL success))completion;
- (id)initExistingFileWithUrl:(NSURL *)url;

- (void)queryDatabaseForManagedObjectContext: (NSManagedObjectContext *)moc
                       withCompletionHandler: (void (^)(NSArray *results, BOOL success))completion;

- (void)openFile:(NSURL *)url completion:(void (^)(BOOL success))completion;

- (void)save;

@end