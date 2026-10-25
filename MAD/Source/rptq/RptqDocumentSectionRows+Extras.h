//
//  RptqDocumentSectionRows+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/29/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_RptqDocumentSectionRows_Extras_h
#define Reports_RptqDocumentSectionRows_Extras_h

#import <MAD/RptqDocumentSectionRows.h>
#import <MAD/RptqStoreContext.h>

@interface RptqDocumentSectionRows (Extras)

	+ (instancetype)newDocumentSectionRowsForManagedObjectContext:(RptqStoreContext *)managedObjectContext;

	- (void)addHasObjectsObjectFixed:(RptqDocumentElement *)value;
	- (void)removeHasObjectsObjectFixed:(RptqDocumentElement *)value;

@end

#endif
