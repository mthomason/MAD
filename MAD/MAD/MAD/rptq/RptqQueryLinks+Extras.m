//
//  RptqQueryLinks+Extras.m
//  Reports
//
//  Created by Michael Thomason on 3/13/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
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
                                  joinType:(MNSLinkType)joinType
                      managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    NSEntityDescription *rqtEd = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryLinks class]) inManagedObjectContext:managedObjectContext];
    
    RptqQueryLinks *queryLinks = [[self alloc] initWithEntity: rqtEd insertIntoManagedObjectContext: managedObjectContext];
    
    queryLinks.hasLeftField     = fieldLeft;
    queryLinks.hasRightField    = fieldRight;
    queryLinks.tableLeftID      = fieldLeft.inQueryTable.alias.copy;
    queryLinks.fieldLeftID      = fieldLeft.databaseSchemaField.name.copy;
    queryLinks.tableRightID     = fieldRight.inQueryTable.alias.copy;
    queryLinks.fieldRightID     = fieldRight.databaseSchemaField.name.copy;
    queryLinks.type             = joinType;
    
    return queryLinks;
}

+ (NSString *)ReuseIdForLinkType:(MNSLinkType)type {
    switch (type) {
        case MNSLinkTypeInnerJoin:
            return MNSJoinTypeInnerJoin;
            break;
        case MNSLinkTypeEquiJoin:
            return MNSJoinTypeEquiJoin;
            break;
        case MNSLinkTypeNaturalJoin:
            return MNSJoinTypeNaturalJoin;
            break;
        case MNSLinkTypeCrossJoin:
            return MNSJoinTypeCrossJoin;
            break;
        case MNSLinkTypeLeftOuterJoin:
            return MNSJoinTypeLeftOuterJoin;
            break;
        case MNSLinkTypeRightOuterJoin:
            return MNSJoinTypeRightOuterJoin;
            break;
        case MNSLinkTypeFullOuterJoin:
            return MNSJoinTypeFullOuterJoin;
            break;
        default:
            return MNSJoinTypeLeftOuterJoin;
            break;
    }
}

+ (NSString *)NamesForLinkType:(MNSLinkType)type {
    NSString *reuseId;
    switch (type) {
        case MNSLinkTypeInnerJoin:
            reuseId = MTLinkTypeNameInnerJoin;
            break;
        case MNSLinkTypeEquiJoin:
            reuseId = MTLinkTypeNameEquiJoin;
            break;
        case MNSLinkTypeNaturalJoin:
            reuseId = MTLinkTypeNameNaturalJoin;
            break;
        case MNSLinkTypeCrossJoin:
            reuseId = MTLinkTypeNameCrossJoin;
            break;
        case MNSLinkTypeLeftOuterJoin:
            reuseId = MTLinkTypeNameLeftOuterJoin;
            break;
        case MNSLinkTypeRightOuterJoin:
            reuseId = MTLinkTypeNameRightOuterJoin;
            break;
        case MNSLinkTypeFullOuterJoin:
            reuseId = MTLinkTypeNameFullOuterJoin;
            break;
        default:
            reuseId = MTLinkTypeNameLeftOuterJoin;
            break;
    }
    return NSLocalizedString(reuseId, reuseId);
}

+ (NSString *)SqlForLinkType:(MNSLinkType)type {
    NSString *sql;
    switch (type) {
        case MNSLinkTypeInnerJoin:
            sql = MTLinkSqlInnerJoin;
            break;
        case MNSLinkTypeEquiJoin:
            sql = MTLinkSqlEquiJoin;
            break;
        case MNSLinkTypeNaturalJoin:
            sql = MTLinkSqlNaturalJoin;
            break;
        case MNSLinkTypeCrossJoin:
            sql = MTLinkSqlCrossJoin;
            break;
        case MNSLinkTypeLeftOuterJoin:
            sql = MTLinkSqlLeftOuterJoin;
            break;
        case MNSLinkTypeRightOuterJoin:
            sql = MTLinkSqlRightOuterJoin;
            break;
        case MNSLinkTypeFullOuterJoin:
            sql = MTLinkSqlFullOuterJoin;
            break;
        default:
            sql = MTLinkSqlLeftOuterJoin;
            break;
    }
    return sql;
}

+ (NSString *)newLocalizedNameForLinkType:(MNSLinkType)type {
    NSString *name = [self NamesForLinkType:type];
    return NSLocalizedString(name, name);
}


#pragma mark -
#pragma mark Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    self.identifier = [RptqDataHelper nextIdentifierForClass:[self class]
                                        managedObjectContext:self.managedObjectContext];
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
