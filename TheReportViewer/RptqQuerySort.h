//
//  RptqQuerySort.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/29/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqQuery;

@interface RptqQuerySort : NSManagedObject

@property (nonatomic, retain) NSNumber * ascending;
@property (nonatomic, retain) NSString * fields;
@property (nonatomic, retain) RptqQuery *inQuery;

@end
