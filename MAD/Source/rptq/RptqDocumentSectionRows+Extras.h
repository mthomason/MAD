//
//  RptqDocumentSectionRows+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/29/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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
