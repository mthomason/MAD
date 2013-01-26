//
//  RptqQueryResultValues.h
//  Reports
//
//  Created by Michael Thomason on 1/26/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface RptqQueryResultValues : NSManagedObject

@property (nonatomic, retain) NSNumber * rowId;
@property (nonatomic, retain) id value;
@property (nonatomic, retain) NSManagedObject *valuesForField;

@end
