//
//  NSDatabase.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIManagedDocumentQuery.h"

typedef enum {
	NSDatabaseQueryTypeNone = 0,
	NSDatabaseQueryTypeGetTables,
	NSDatabaseQueryTypeGetFields,
	NSDatabaseQueryTypeVerify
} NSDatabaseQueryType;

@interface NSDatabase : NSObject

@property (strong, nonatomic) UIManagedDocumentQuery *managedDocumentQuery;

- (id)initWithFileName:(NSString *)name;
- (id)initWithUrl:(NSURL *)url;

- (void)openFile:(NSURL *)url;

@end