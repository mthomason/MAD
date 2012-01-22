//
//  NSDatabase.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIManagedDocumentQuery.h"

typedef enum {
	NSDatabaseQueryTypeNone = 0,
	NSDatabaseQueryTypeGetTables,
	NSDatabaseQueryTypeGetFields,
	NSDatabaseQueryTypeVerify
} NSDatabaseQueryType;

typedef void (^rsltBlk_filePath)(BOOL success);

@interface NSDatabase : NSObject

@property (strong, nonatomic) UIManagedDocumentQuery *managedDocumentQuery;

- (id)initNewFileWithName:(NSString *)name completion:(void (^)(BOOL success))completion;
- (id)initExistingFileWithUrl:(NSURL *)url;

- (void)openFile:(NSURL *)url completion:(void (^)(BOOL success))completion;

@end