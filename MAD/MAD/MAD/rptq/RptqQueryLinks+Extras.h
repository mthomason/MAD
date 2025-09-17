//
//  RptqQueryLinks+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/13/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_RptqQueryLinks_Extras_h
#define Reports_RptqQueryLinks_Extras_h

#import <MAD/RptqQueryLinks.h>
#import <MAD/MADQueryLinkType.h>
#import <MADDataStructures/MTProtocolLog.h>

@class RptqDocument, RptqQueryTable;

@interface RptqQueryLinks (Extras) <MTProtocolLog>

	+ (instancetype)newQueryLinksWithLeftField:(RptqQueryField *)fieldLeft
									rightField:(RptqQueryField *)fieldRight
									  joinType:(MADLinkType)joinType
						  managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

	- (NSString *)linkDescription;

	+ (NSString *)ReuseIdForLinkType:(MADLinkType)type;
	+ (NSString *)newLocalizedNameForLinkType:(MADLinkType)type;
	+ (NSString *)SqlForLinkType:(MADLinkType)type;
	- (BOOL)isConnectedToTable:(RptqQueryTable *)table;

@end

#endif
