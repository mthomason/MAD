//
//  MNSDocumentReport.h
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportDocument_h
#define Reports_MTReportDocument_h

#import <Foundation/Foundation.h>

#import "MTDatabase.h"
#import "MTDatabaseTable.h"
#import "MTDatabaseField.h"

#import "RptqDocument+Extras.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaTable+Extras.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqDatabase+Extras.h"
#import "RptqUserCredentals+Extras.h"
#import "MADocument.h"

@interface MAReportDocument : MADocument

//Add a new connection to the report
- (void)addDatasourceToReport: (MTDatabase *)database
                   completion: (void (^)(BOOL success, NSError *error))completion;
//- (void)refresh;
- (void)refresh:(void (^)(BOOL success))completion;
- (BOOL)hasCachedData;
- (void)sendTo;
+ (NSString *)fileType;

@end

#endif
