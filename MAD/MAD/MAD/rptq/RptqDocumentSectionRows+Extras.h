//
//  RptqDocumentSectionRows+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/29/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocumentSectionRows_Extras_h
#define Reports_RptqDocumentSectionRows_Extras_h

#import "RptqDocumentSectionRows.h"

@interface RptqDocumentSectionRows (Extras)

    + (instancetype)newDocumentSectionRowsForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

    - (void)addHasObjectsObjectFixed:(RptqDocumentObject *)value;
    - (void)removeHasObjectsObjectFixed:(RptqDocumentObject *)value;

@end

#endif
