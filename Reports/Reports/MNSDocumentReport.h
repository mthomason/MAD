//
//  MNSDocumentReport.h
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MNSDocument.h"
#import "UIManagedDocumentReport.h"

#import "MNSDatabase.h"
#import "MNSDatabaseTable.h"
#import "MNSDatabaseField.h"

#import "RptqDocument+Extras.h"
#import "RptqTable.h"
#import "RptqField.h"
#import "RptqTable+Extras.h"
#import "RptqField+Extras.h"
#import "RptqDatabase+Extras.h"
#import "RptqUserCredentals+Extras.h"

@interface MNSDocumentReport : MNSDocument

//Create a new file
- (id)initFileWithName: (NSString *)name
            completion: (void (^)(BOOL success))completion;

//Open an existing file
- (id)initFileWithUrl: (NSURL *)url
           completion: (void (^)(BOOL success))completion;

//Save the currently opend UIManagedDocument
- (void)save:(void (^)(BOOL success))completion;

//Save the currently opend UIManagedDocument to a specific location
- (void)saveToUrl: (NSURL *)url
       completion: (void (^)(BOOL success))completion;

//Add a new connection to the report
- (void)addDatasourceToReport: (MNSDatabase *)database
                   completion: (void (^)(BOOL success))completion;

//Refresh the data inside the currently opened managed document
- (void)refresh;

//Export the data inside the currently opened managed document
- (void)sendTo;

@end