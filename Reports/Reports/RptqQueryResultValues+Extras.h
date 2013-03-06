//
//  RptqQueryResultValues+Extras.h
//  Reports
//
//  Created by Michael Thomason on 1/26/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqQueryResultValues_Extras_h
#define Reports_RptqQueryResultValues_Extras_h

#import "RptqQueryResultValues.h"

@interface RptqQueryResultValues (Extras)

+ (id)initObjectForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end

#endif
