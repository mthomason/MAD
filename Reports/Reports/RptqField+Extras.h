//
//  RptqField+Extras.h
//  Reports
//
//  Created by Michael Thomason on 11/11/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqField_Extras_h
#define Reports_RptqField_Extras_h

#import "RptqField.h"
#import "MTDatabaseField.h"
#import "MTProtocolLog.h"
#import "MTProtocolCompare.h"

@interface RptqField (Extras) <MTProtocolCompare, MTProtocolLog>

+ (RptqField *)createNewFieldForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                               label:(NSString *)label
                                                name:(NSString *)name
                                         andDatatype:(NSString *)dataType;

+ (RptqField *)createNewFieldForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                            andField:(MTDatabaseField *)field;

+ (id)getFieldForObjectID:(NSManagedObjectID *)objectID
        fromObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (NSString *)display;

@end

#endif
