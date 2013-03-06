//
//  RptqQueryResult+Extras.h
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqQueryResult_Extras_h
#define Reports_RptqQueryResult_Extras_h

#import "RptqQueryResult.h"

@interface RptqQueryResult (Extras)

+ (id)initObjectForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end

#endif
