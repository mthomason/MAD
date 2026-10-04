//
//  RptqQueryLinks+Extras.m
//  Reports
//
//  Created by Michael Thomason on 3/13/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqStoreContext.h"
#import "RptqQueryLinks+Extras.h"

#import "RptqDocument.h"
#import "RptqDatabase.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqQueryField.h"
#import "RptqQueryField.h"
#import "RptqQueryTable.h"
#import "RptqDataHelper.h"
#import "RptqDocument+Extras.h"
#import "RptqQueryTable+Extras.h"
#import "MADSQLJoinType.h"

@implementation RptqQueryLinks (Extras)

#pragma mark -
#pragma mark Static

+ (instancetype)newQueryLinksWithLeftField:(RptqQueryField *)fieldLeft
								rightField:(RptqQueryField *)fieldRight
								  joinType:(MADLinkType)joinType
					  managedObjectContext:(RptqStoreContext *)managedObjectContext {
	
	NSString *entityName = NSStringFromClass([RptqQueryLinks class]);
	RptqQueryLinks *queryLinks = (RptqQueryLinks *)[managedObjectContext insertObjectForEntity:entityName identifier:0];
	
	queryLinks.hasLeftField     = fieldLeft;
	queryLinks.hasRightField    = fieldRight;
	queryLinks.tableLeftID      = fieldLeft.inQueryTable.alias.copy;
	queryLinks.fieldLeftID      = fieldLeft.databaseSchemaField.name.copy;
	queryLinks.tableRightID     = fieldRight.inQueryTable.alias.copy;
	queryLinks.fieldRightID     = fieldRight.databaseSchemaField.name.copy;
	queryLinks.type             = joinType;
	
	return queryLinks;
}

+ (NSString *)ReuseIdForLinkType:(MADLinkType)type {
	switch (type) {
		case MADLinkTypeInnerJoin: return MNSJoinTypeInnerJoin;
		case MADLinkTypeEquiJoin: return MNSJoinTypeEquiJoin;
		case MADLinkTypeNaturalJoin: return MNSJoinTypeNaturalJoin;
		case MADLinkTypeCrossJoin: return MNSJoinTypeCrossJoin;
		case MADLinkTypeLeftOuterJoin: return MNSJoinTypeLeftOuterJoin;
		case MADLinkTypeRightOuterJoin: return MNSJoinTypeRightOuterJoin;
		case MADLinkTypeFullOuterJoin: return MNSJoinTypeFullOuterJoin;
		default: return MNSJoinTypeLeftOuterJoin;
	}
}

+ (NSString *)NamesForLinkType:(MADLinkType)type {
	switch (type) {
		case MADLinkTypeInnerJoin: return NSLocalizedString(@"Inner-Join", @"Inner-Join");
		case MADLinkTypeEquiJoin: return NSLocalizedString(@"Equi-Join", @"Equi-Join");
		case MADLinkTypeNaturalJoin: return NSLocalizedString(@"Natural Join", @"Natural Join");
		case MADLinkTypeCrossJoin: return NSLocalizedString(@"Cross Join", @"Cross Join");
		case MADLinkTypeRightOuterJoin: return NSLocalizedString(@"Right Outer Join", @"Right Outer Join");
		case MADLinkTypeFullOuterJoin: return NSLocalizedString(@"Full Outer Join", @"Full Outer Join");
		case MADLinkTypeLeftOuterJoin: default: return NSLocalizedString(@"Left Outer Join", @"Left Outer Join");
	}
}

+ (NSString *)SqlForLinkType:(MADLinkType)type {
	switch (type) {
		case MADLinkTypeInnerJoin: return @"INNER JOIN";
		case MADLinkTypeEquiJoin: return @"JOIN";
		case MADLinkTypeNaturalJoin: return @"NATURAL JOIN";
		case MADLinkTypeCrossJoin: return @"CROSS JOIN";
		case MADLinkTypeRightOuterJoin: return @"RIGHT OUTER JOIN";
		case MADLinkTypeFullOuterJoin: return @"FULL OUTER JOIN";
		case MADLinkTypeLeftOuterJoin: default: return @"LEFT OUTER JOIN";
	}
}

+ (NSString *)newLocalizedNameForLinkType:(MADLinkType)type {
	NSString *name = [self NamesForLinkType:type];
	return NSLocalizedString(name, name);
}


#pragma mark -
#pragma mark Overrides

- (BOOL)isConnectedToTable:(RptqQueryTable *)table {
	return (self.hasLeftField.inQueryTable.identifier == table.identifier ||
			self.hasRightField.inQueryTable.identifier == table.identifier);
}

- (NSString *)linkDescription {
	NSString *localizedName = [RptqQueryLinks newLocalizedNameForLinkType:self.type];
	return localizedName;
}

// MARK: MTProtocolLog

- (NSString *)toStringHumanReadable {
	NSString *name = self.hasLeftField.databaseSchemaField.name;
	NSString *nameRight = self.hasRightField.databaseSchemaField.name;
	NSMutableString *result = [name mutableCopy];
	NSString *linkDescription = [self linkDescription];
	[result appendFormat:@" %@ ", linkDescription];
	[result appendString:nameRight];
	return result;
}

- (NSString *)toString {
	return [self toStringHumanReadable];
}

- (NSString *)toStringDebug {
	return [self toStringHumanReadable];
}

- (id)debugQuickLookObject {
	NSMutableString *description = [[NSMutableString alloc] init];
	[description appendFormat:@"***********   RptqQueryLinks  ***********\n"];
	[description appendFormat:@"Identifier:             %lld\n", self.identifier];
	[description appendFormat:@"Field left:             %@\n", self.fieldLeftID];
	[description appendFormat:@"Field right:            %@\n", self.fieldRightID];
	[description appendFormat:@"Table left:             %@\n", self.tableLeftID];
	[description appendFormat:@"Table right:            %@\n", self.tableRightID];
	[description appendFormat:@"Join type enum:         %hd\n", self.type];
	[description appendFormat:@"***********   RptqQueryLinks  ***********"];
	return description;
}

@end
