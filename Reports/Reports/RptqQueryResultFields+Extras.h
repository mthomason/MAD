//
//  RptqQueryResultFields+Extras.h
//  Reports
//
//  Created by Michael Thomason on 1/26/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqQueryResultFields_Extras_h
#define Reports_RptqQueryResultFields_Extras_h

#import "RptqQueryResultFields.h"

@interface RptqQueryResultFields (Extras)

+ (id)initObjectForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end

#endif
