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

#import "MTDocument.h"
#import "MTManagedDocumentReport.h"

#import "MTDatabase.h"
#import "MTDatabaseTable.h"
#import "MTDatabaseField.h"

#import "RptqDocument+Extras.h"
#import "RptqTable.h"
#import "RptqField.h"
#import "RptqTable+Extras.h"
#import "RptqField+Extras.h"
#import "RptqDatabase+Extras.h"
#import "RptqUserCredentals+Extras.h"
#import "RptqQueryResultFields+Extras.h"

@interface MTReportDocument : MTDocument

//Create a new file
- (id)initNewFileWithName: (NSString *)name
            completion: (void (^)(BOOL success))completion;

//Open an existing file
- (id)initExistingExistingFileWithUrl: (NSURL *)url
           completion: (void (^)(BOOL success, id document))completion;

//Save the currently opend UIManagedDocument
- (void)save:(void (^)(BOOL success))completion;

//Save the currently opend UIManagedDocument to a specific location
- (void)saveToUrl: (NSURL *)url
       completion: (void (^)(BOOL success))completion;

//Add a new connection to the report
- (void)addDatasourceToReport: (MTDatabase *)database
                   completion: (void (^)(BOOL success))completion;

//Refresh the data inside the currently opened managed document
- (void)refresh;

//Export the data inside the currently opened managed document
- (void)sendTo;

@end

#endif
