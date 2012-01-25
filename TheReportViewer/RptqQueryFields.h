//
//  RptqQueryFields.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/25/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqQueryTables;

@interface RptqQueryFields : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) RptqQueryTables *inTable;

@end
