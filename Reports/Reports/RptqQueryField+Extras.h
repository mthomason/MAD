//
//  RptqQueryField+Extras.h
//  Reports
//
//  Created by Michael Thomason on 5/13/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryField.h"
#import "MTProtocolLog.h"
#import "MTProtocolCompare.h"

@interface RptqQueryField (Extras) <MTProtocolLog, MTProtocolCompare>

- (NSString *)display;
- (NSString *)tableFieldKey;
+ (id)getQueryFieldForObjectID:(NSManagedObjectID *)objectID fromObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (RptqQueryField *)createNewQueryFieldForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
- (NSString *)toStringReverse;

@end
