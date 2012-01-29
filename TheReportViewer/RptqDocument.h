//
//  RptqDocument.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/28/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDatabase, RptqQuery;

@interface RptqDocument : NSManagedObject

@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSNumber * override;
@property (nonatomic, retain) NSString * overrideText;
@property (nonatomic, retain) RptqDatabase *hasDatabaseSchema;
@property (nonatomic, retain) RptqQuery *hasQuery;

@end
