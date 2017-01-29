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

#import "RptqDocument+CoreDataClass.h"
#import "RptqDocument+Extras.h"
#import "RptqDatabase+CoreDataClass.h"
#import "RptqDatabaseSchemaField+CoreDataClass.h"
#import "RptqQueryField+CoreDataClass.h"
#import "RptqQueryField+CoreDataClass.h"
#import "RptqQueryTable+CoreDataClass.h"
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

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    int64_t identifier = [RptqDataHelper nextIdentifierForClass:[self class]
                                           managedObjectContext:self.managedObjectContext];
    CFNumberRef n = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt64Type, &identifier);
    self.identifier = (__bridge NSNumber * _Nullable)(n);
    CFRelease(n);
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
}

- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flag {
    [super awakeFromSnapshotEvents:flag];
    switch (flag) {
        case NSSnapshotEventMergePolicy:
            break;
        case NSSnapshotEventRefresh:
            break;
        case NSSnapshotEventRollback:
            break;
        case NSSnapshotEventUndoDeletion:
            break;
        case NSSnapshotEventUndoInsertion:
            break;
        case NSSnapshotEventUndoUpdate:
            break;
        default:
            break;
    }
}

#pragma mark - Static

+ (instancetype)newQueryLinksWithLeftField:(RptqQueryField *)fieldLeft
                                rightField:(RptqQueryField *)fieldRight
                                  joinType:(MNSLinkType)joinType
                      managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    NSEntityDescription *rqtEd = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryLinks class]) inManagedObjectContext:managedObjectContext];
    
    RptqQueryLinks *queryLinks = [[self alloc] initWithEntity: rqtEd insertIntoManagedObjectContext: managedObjectContext];
    
    queryLinks.hasLeftField     = fieldLeft;
    queryLinks.hasRightField    = fieldRight;
    queryLinks.tableleft        = fieldLeft.inQueryTable.alias;
    queryLinks.fieldleft        = fieldLeft.databaseSchemaField.name;
    queryLinks.tableright       = fieldRight.inQueryTable.alias;
    queryLinks.fieldright       = fieldRight.databaseSchemaField.name;
    queryLinks.jointype         = [RptqQueryLinks ReuseIdForLinkType:joinType];

    NSNumber *jointypeenum      = [[NSNumber alloc] initWithShort: joinType];
    queryLinks.jointypeenum     = jointypeenum;

    return queryLinks;
}

- (NSString *)copyLinkDescription {
    NSString *localizedName = [RptqQueryLinks newLocalizedNameForLinkType:self.jointypeenum.shortValue];
    return localizedName;
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

// MARK: MTProtocolLog

- (NSString *)toStringHumanReadable {
    NSMutableString *result = [[NSMutableString alloc] initWithString:self.hasLeftField.databaseSchemaField.name];
    NSString *linkDescription = [self copyLinkDescription];
    [result appendFormat:@" %@ ", linkDescription];
    [result appendString:self.hasRightField.databaseSchemaField.name];
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
    [description appendFormat:@"Identifier:             %@\n", self.identifier];
    [description appendFormat:@"Inital layout:          %@\n", self.designerInitalLayout];
    [description appendFormat:@"Field left:             %@\n", self.fieldleft];
    [description appendFormat:@"Field right:            %@\n", self.fieldright];
    [description appendFormat:@"Table left:             %@\n", self.tableleft];
    [description appendFormat:@"Table right:            %@\n", self.tableright];
    [description appendFormat:@"Join type:              %@\n", self.jointype];
    [description appendFormat:@"Join type enum:         %@\n", self.jointypeenum];
    [description appendFormat:@"Frame:                  (%f, %f, %f, %f)\n", self.designerOriginX.floatValue, self.designerOriginY.floatValue, self.designerSizeWidth.floatValue, self.designerSizeHeight.floatValue];
    [description appendFormat:@"***********   RptqQueryLinks  ***********"];
    return description;
}

@end
