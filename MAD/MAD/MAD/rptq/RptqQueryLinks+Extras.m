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

#import "RptqQueryLinks+Extras.h"
#import <CoreData/CoreData.h>

#import "RptqDocument.h"
#import "RptqDocument+Extras.h"
#import "RptqDatabase.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqQueryField.h"
#import "RptqQueryField.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"

#import "MADSQLJoinType.h"
#import "RptqDataHelper.h"

NSString * const MTLinkTypeNameInnerJoin        = @"Inner-Join";
NSString * const MTLinkTypeNameEquiJoin         = @"Equi-Join";
NSString * const MTLinkTypeNameNaturalJoin      = @"Natural Join";
NSString * const MTLinkTypeNameCrossJoin        = @"Cross Join";
NSString * const MTLinkTypeNameLeftOuterJoin    = @"Left Outer Join";
NSString * const MTLinkTypeNameRightOuterJoin   = @"Right Outer Join";
NSString * const MTLinkTypeNameFullOuterJoin    = @"Full Outer Join";

NSString * const MTLinkSqlInnerJoin             = @"INNER JOIN";
NSString * const MTLinkSqlEquiJoin              = @"JOIN";
NSString * const MTLinkSqlNaturalJoin           = @"NATURAL JOIN";
NSString * const MTLinkSqlCrossJoin             = @"CROSS JOIN";
NSString * const MTLinkSqlLeftOuterJoin         = @"LEFT OUTER JOIN";
NSString * const MTLinkSqlRightOuterJoin        = @"RIGHT OUTER JOIN";
NSString * const MTLinkSqlFullOuterJoin         = @"FULL OUTER JOIN";

@implementation RptqQueryLinks (Extras)

#pragma mark -
#pragma mark Static

+ (instancetype)newQueryLinksWithLeftField:(RptqQueryField *)fieldLeft
                                rightField:(RptqQueryField *)fieldRight
                                  joinType:(MADLinkType)joinType
                      managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    NSString *entityName = NSStringFromClass([RptqQueryLinks class]);
    NSEntityDescription *rqtEd = [NSEntityDescription entityForName: entityName
                                             inManagedObjectContext: managedObjectContext];
    
    RptqQueryLinks *queryLinks = [[self alloc] initWithEntity: rqtEd
                               insertIntoManagedObjectContext: managedObjectContext];
    
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
        case MADLinkTypeInnerJoin:
            return MNSJoinTypeInnerJoin;
            break;
        case MADLinkTypeEquiJoin:
            return MNSJoinTypeEquiJoin;
            break;
        case MADLinkTypeNaturalJoin:
            return MNSJoinTypeNaturalJoin;
            break;
        case MADLinkTypeCrossJoin:
            return MNSJoinTypeCrossJoin;
            break;
        case MADLinkTypeLeftOuterJoin:
            return MNSJoinTypeLeftOuterJoin;
            break;
        case MADLinkTypeRightOuterJoin:
            return MNSJoinTypeRightOuterJoin;
            break;
        case MADLinkTypeFullOuterJoin:
            return MNSJoinTypeFullOuterJoin;
            break;
        default:
            return MNSJoinTypeLeftOuterJoin;
            break;
    }
}

+ (NSString *)NamesForLinkType:(MADLinkType)type {
    NSString *reuseId;
    switch (type) {
        case MADLinkTypeInnerJoin:
            reuseId = MTLinkTypeNameInnerJoin;
            break;
        case MADLinkTypeEquiJoin:
            reuseId = MTLinkTypeNameEquiJoin;
            break;
        case MADLinkTypeNaturalJoin:
            reuseId = MTLinkTypeNameNaturalJoin;
            break;
        case MADLinkTypeCrossJoin:
            reuseId = MTLinkTypeNameCrossJoin;
            break;
        case MADLinkTypeLeftOuterJoin:
            reuseId = MTLinkTypeNameLeftOuterJoin;
            break;
        case MADLinkTypeRightOuterJoin:
            reuseId = MTLinkTypeNameRightOuterJoin;
            break;
        case MADLinkTypeFullOuterJoin:
            reuseId = MTLinkTypeNameFullOuterJoin;
            break;
        default:
            reuseId = MTLinkTypeNameLeftOuterJoin;
            break;
    }
    return NSLocalizedString(reuseId, reuseId);
}

+ (NSString *)SqlForLinkType:(MADLinkType)type {
    NSString *sql;
    switch (type) {
        case MADLinkTypeInnerJoin:
            sql = MTLinkSqlInnerJoin;
            break;
        case MADLinkTypeEquiJoin:
            sql = MTLinkSqlEquiJoin;
            break;
        case MADLinkTypeNaturalJoin:
            sql = MTLinkSqlNaturalJoin;
            break;
        case MADLinkTypeCrossJoin:
            sql = MTLinkSqlCrossJoin;
            break;
        case MADLinkTypeLeftOuterJoin:
            sql = MTLinkSqlLeftOuterJoin;
            break;
        case MADLinkTypeRightOuterJoin:
            sql = MTLinkSqlRightOuterJoin;
            break;
        case MADLinkTypeFullOuterJoin:
            sql = MTLinkSqlFullOuterJoin;
            break;
        default:
            sql = MTLinkSqlLeftOuterJoin;
            break;
    }
    return sql;
}

+ (NSString *)newLocalizedNameForLinkType:(MADLinkType)type {
    NSString *name = [self NamesForLinkType:type];
    return NSLocalizedString(name, name);
}


#pragma mark -
#pragma mark Overrides

- (BOOL)isConnectedToTable:(RptqQueryTable *)table {
    return ([self.hasLeftField.inQueryTable.objectID isEqual: table.objectID] ||
            [self.hasRightField.inQueryTable.objectID isEqual: table.objectID]);
}

- (void)awakeFromInsert {
    [super awakeFromInsert];
    if (self.managedObjectContext.parentContext && self.identifier <= 0) {
        [[NSNotificationCenter defaultCenter] willChangeValueForKey:NSStringFromSelector(@selector(identifier))];
        self.identifier = [RptqDataHelper nextIdentifierForClass:[self class]
                                            managedObjectContext:self.managedObjectContext];
        [[NSNotificationCenter defaultCenter] didChangeValueForKey:NSStringFromSelector(@selector(identifier))];
    }
}

- (NSString *)linkDescription {
    NSString *localizedName = [RptqQueryLinks newLocalizedNameForLinkType:self.type];
    return localizedName;
}

// MARK: MTProtocolLog

- (NSString *)toStringHumanReadable {
    NSString *name = self.hasLeftField.databaseSchemaField.name;
    NSString *nameRight = self.hasRightField.databaseSchemaField.name;
    NSMutableString *result = name.mutableCopy;
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
