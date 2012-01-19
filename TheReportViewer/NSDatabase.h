//
//  NSDatabase.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	NSDatabaseQueryTypeNone = 0,
	NSDatabaseQueryTypeGetTables,
	NSDatabaseQueryTypeGetFields,
	NSDatabaseQueryTypeVerify
} NSDatabaseQueryType;

@interface NSDatabase : NSObject

//- (id)initWithOptions:(NSDictionary *)optons;

@end