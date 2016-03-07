//
//  RptqQueryCache+Extras.h
//  Reports
//
//  Created by Michael Thomason on 12/15/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqQueryCache_Extras_h
#define Reports_RptqQueryCache_Extras_h

#import "RptqQueryCache.h"
#import <MADDataStructures/MTProtocolCompare.h>

@interface RptqQueryCache (Extras) <MTProtocolCompare>

+ (instancetype)initObjectForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end

#endif
