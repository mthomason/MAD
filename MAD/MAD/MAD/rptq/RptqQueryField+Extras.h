//
//  RptqQueryField+Extras.h
//  Reports
//
//  Created by Michael Thomason on 5/13/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqQueryField_Extras_h
#define Reports_RptqQueryField_Extras_h

#import "RptqQueryField.h"
#import <MADDataStructures/MADDataStructures.h>

@interface RptqQueryField (Extras) <MTProtocolLog, MTProtocolCompare>

+ (instancetype)queryFieldFactory:(NSManagedObjectContext *)managedObjectContext NS_RETURNS_RETAINED;
+ (instancetype)queryFieldForObjectID:(NSManagedObjectID *)objectID managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (NSString *)display;
- (NSString *)tableFieldKey;
- (NSString *)toStringReverse;

@end

#endif
