//
//  RptqField+Extras.h
//  Reports
//
//  Created by Michael Thomason on 11/11/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqField.h"
#import "MNSDatabaseField.h"

@interface RptqField (Extras)

+ (RptqField *)createNewFieldForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                               label:(NSString *)label
                                                name:(NSString *)name
                                         andDatatype:(NSString *)dataType;

+ (RptqField *)createNewFieldForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                            andField:(MNSDatabaseField *)field;

- (NSString *)display;

@end