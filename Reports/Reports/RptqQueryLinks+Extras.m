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
#import "RptqQuery.h"
#import "RptqQueryField.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"

NSString * const MNSJoinTypeInnerJoin           = @"MNSJoinTypeInnerJoin";
NSString * const MNSJoinTypeEquiJoin            = @"MNSJoinTypeEquiJoin";
NSString * const MNSJoinTypeNaturalJoin         = @"MNSJoinTypeNaturalJoin";
NSString * const MNSJoinTypeCrossJoin           = @"MNSJoinTypeCrossJoin";
NSString * const MNSJoinTypeLeftOuterJoin       = @"MNSJoinTypeLeftOuterJoin";
NSString * const MNSJoinTypeRightOuterJoin      = @"MNSJoinTypeRightOuterJoin";
NSString * const MNSJoinTypeFullOuterJoin       = @"MNSJoinTypeFullOuterJoin";

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
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryLinks class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: @[sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqQueryLinks *lastObject = [fetchResults lastObject];
        identifier = lastObject.identifier.integerValue + 1;
    }
    
    NSNumber *identifierWrapper = @(identifier);
    self.identifier = identifierWrapper;
    
    NSNumber *designerOriginX = @(CGPointZero.x);
    self.designerOriginX = designerOriginX;
    
    NSNumber *designerOriginY = @(CGPointZero.y);
    self.designerOriginY = designerOriginY;
    
    NSNumber *designerSizeHeight = @(CGSizeZero.height);
    self.designerSizeHeight = designerSizeHeight;

    NSNumber *designerSizeWidth = @(CGSizeZero.width);
    self.designerSizeWidth = designerSizeWidth;
    
    NSNumber *designerInitalLayout = @(YES);
    self.designerInitalLayout = designerInitalLayout;
    
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

+ (instancetype)queryLinkFactoryWithLeftField:(RptqQueryField *)fieldLeft
                                   rightField:(RptqQueryField *)fieldRight
                                     joinType:(MNSLinkType)joinType {
    
    NSManagedObjectContext *managedObjectContext = [fieldLeft managedObjectContext];
    NSEntityDescription *rqtEd = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryLinks class]) inManagedObjectContext:managedObjectContext];
    
    RptqQueryLinks *queryLinks = [[RptqQueryLinks alloc] initWithEntity: rqtEd
                                         insertIntoManagedObjectContext: managedObjectContext];
    
    queryLinks.hasLeftField     = fieldLeft;
    queryLinks.hasRightField    = fieldRight;
    queryLinks.tableleft        = fieldLeft.inQueryTable.alias;
    queryLinks.fieldleft        = fieldLeft.databaseSchemaField.name;
    queryLinks.tableright       = fieldRight.inQueryTable.alias;
    queryLinks.fieldright       = fieldRight.databaseSchemaField.name;
    queryLinks.jointype         = [RptqQueryLinks ReuseIdForLinkType:joinType];
    NSNumber *joinTypeSafe      = @(joinType);
    queryLinks.jointypeenum     = joinTypeSafe;

    return queryLinks;
}

- (NSString *)linkDescription {
    return [RptqQueryLinks LocalizedNamesForLinkType:self.jointypeenum.integerValue];
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

+ (NSString *)LocalizedNamesForLinkType:(MNSLinkType)type {
    NSString *name = [self NamesForLinkType:type];
    return NSLocalizedString(name, name);
}

// MARK: MTProtocolLog

- (NSString *)toStringHumanReadable {
    NSMutableString *result = [[NSMutableString alloc] initWithString:[[[self hasLeftField] databaseSchemaField] name]];
    [result appendFormat:@" %@ ", [self linkDescription]];
    [result appendString:[[[self hasRightField] databaseSchemaField] name]];
    return result;
}

- (NSString *)toString {
    return [self toStringHumanReadable];
}

- (NSString *)toStringDebug {
    return [self toStringHumanReadable];
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self isEqual:sender]) {
        result = YES;
    } else {
        RptqQueryLinks *s = sender;
        result = [[self identifier] isEqualToNumber:[s identifier]];
    }
    return result;
}

@end
