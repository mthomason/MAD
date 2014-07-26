//
//  NSObject+RptqDocument_Extras.h
//  Reports
//
//  Created by Michael Thomason on 2/12/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocument_Extras_h
#define Reports_RptqDocument_Extras_h

#import <Foundation/Foundation.h>
#import "RptqDocument.h"
#import "MTProtocolCompare.h"

@class NSManagedObjectContext, MTDatabase, RptqQuery;

@interface RptqDocument (Extras) <MTProtocolCompare>

- (RptqQuery *)defaultQuery;
- (RptqDatabase *)defaultDatabase;

+ (RptqDocument *)createMainDocumentForManagedObjectContext:(NSManagedObjectContext *)objectContext;
+ (RptqDocument *)getMainDocumentForManagedObjectContext:(NSManagedObjectContext *)objectContext;

- (void)addDatabase: (MTDatabase *)database
         completion: (void (^)(BOOL success, NSError *error))completion;

@end

#endif
