//
//  RptqDocumentObject+Extras.m
//  Reports
//
//  Created by Michael Thomason on 2/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentObject+Extras.h"

NSString * const MTDocumentObjectDefinationType = @"MTDocumentObjectDefinationType";
NSString * const MTDocumentObjectDefinationObject = @"MTDocumentObjectDefinationObject";

NSString * const MTDocumentObjectDefinationAggregateType = @"MTDocumentObjectDefinationAggregateType";
NSString * const MTDocumentObjectDefinationAggregatePivotNumber = @"MTDocumentObjectDefinationAggregatePivotNumber";
NSString * const MTDocumentObjectDefinationAggregatePivotType = @"MTDocumentObjectDefinationAggregatePivotType";
NSString * const MTDocumentObjectDefinationAggregateObjectId = @"MTDocumentObjectDefinationAggregateObjectId";
NSString * const MTDocumentObjectDefinationAggregateFunctionInputType = @"MTDocumentObjectDefinationAggregateFunctionInputType";


@implementation RptqDocumentObject (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocumentObject class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqDocumentObject *lastObject = [fetchResults lastObject];
        identifier = [[lastObject identifier] integerValue] + 1;
    }
    [self setIdentifier:@(identifier)];
    
    // MARK: Default style.
    [self setFontname:[MTFont defaultFamily]];
    [self setFontsize:@([MTFont defaultSize])];
    [self setBold:@NO];
    [self setItalic:@NO];
    [self setUnderline:@NO];
    [self setStrike:@NO];
    [self setMarginBottom:@(CGSizeZero.height)];
    [self setMarginTop:@(CGSizeZero.height)];
    [self setMarginLeft:@(CGSizeZero.width)];
    [self setMarginRight:@(CGSizeZero.width)];
    [self setPaddingBottom:@(CGSizeZero.height)];
    [self setPaddingTop:@(CGSizeZero.height)];
    [self setPaddingLeft:@(CGSizeZero.width)];
    [self setPaddingRight:@(CGSizeZero.width)];
    [self setVerticalAlignment:@(MTVerticalAlignmentTop)];
    [self setHorizontalAlignment:@(MTHorizontalAlignmentLeft)];
    [self setSectionRowNumber:@(1)];
    [self setDropPointX:@(CGPointZero.x)];
    [self setDropPointY:@(CGPointZero.y)];

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

- (CGSize)elementViewSize {
    return CGSizeMake([[self sizewidth] floatValue], [[self sizeheight] floatValue]);
}

- (CGSize)paddingViewSize {
    CGSize elementSize = [self elementViewSize];
    return CGSizeMake(elementSize.width + [[self paddingLeft] floatValue] + [[self paddingRight] floatValue],
                      elementSize.height + [[self paddingTop] floatValue] + [[self paddingBottom] floatValue]);
}

- (CGSize)marginViewSize {
    CGSize paddingSize = [self paddingViewSize];
    return CGSizeMake(paddingSize.width + [[self marginLeft] floatValue] + [[self marginRight] floatValue],
                      paddingSize.height + [[self marginTop] floatValue] + [[self marginBottom] floatValue]);
}

- (CGSize)viewSize {
    return [self marginViewSize];
}

#pragma mark - Member

- (MTDocumentObjectType)getType {
    return [[self type] integerValue];
}

- (NSString *)designerRepresentationText {

    NSString *result = nil;
    
    switch ([[self type] integerValue]) {
    
        case MTDocumentObjectTypeAggregate: {
            //NSInteger groupNumber = [[[self isGroupKey] groupNumber] integerValue];
            //NSString *groupNumberText = [NSNumberFormatter localizedStringFromNumber: groupNumber
            //                                                             numberStyle: NSNumberFormatterSpellOutStyle];
            
            RptqDocumentObjectAggregate *aggregateObject = [self isAggregate];
            //MTGroupByType groupType = [[aggregateObject groupType] integerValue];
            if ([aggregateObject aggregateField] != nil) {
                result = [NSString stringWithFormat:@"Aggregate: %@", [[aggregateObject aggregateField] toStringHumanReadable]];
            } else if ([aggregateObject aggregateFunction] != nil) {
                result = @"Aggregate function";
            }
            
            break;
        }

        case MTDocumentObjectTypeChart:
            result = @"chart";
            break;

        case MTDocumentObjectTypeFormula:
            result = [[self isFormula] source];
            break;
        
        case MTDocumentObjectTypeGroupKey: {
            NSInteger groupNumber = [[[self isGroupKey] groupNumber] integerValue];
            NSString *groupNumberText = [NSNumberFormatter localizedStringFromNumber: groupNumber
                                                                         numberStyle: NSNumberFormatterSpellOutStyle];
            NSString *gorupFormatString = NSLocalizedString(@"Group %@", @"Like 'Group Three.'");
            result = [NSString stringWithFormat:gorupFormatString, [groupNumberText uppercaseString]];
            break;
        }
        
        case MTDocumentObjectTypeImage:
            result = @"image";
            break;
        
        case MTDocumentObjectTypeLabelDynamic:
            result = [[self isLabelDataField] text];
            break;
        
        case MTDocumentObjectTypeLabelStatic:
            result = [[self isLabel] text];
            break;
        
        default:
            break;
    
    }

    return result;
}

#pragma mark - RptqDocumentObjectFactory

+ (RptqDocumentObject *)addDocumentObject:(NSDictionary *)documentObjectDefination toDocument:(RptqDocument *)document {

    NSManagedObjectContext *mangedObjectContext = [document managedObjectContext];
    
    MTDocumentObjectType objectType = [[documentObjectDefination objectForKey:MTDocumentObjectDefinationType] integerValue];

    NSEntityDescription *entityDescriptionDocumentObject = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObject class])
                                                                       inManagedObjectContext: mangedObjectContext];
    
    RptqDocumentObject *documentObject = [[RptqDocumentObject alloc] initWithEntity: entityDescriptionDocumentObject
                                 insertIntoManagedObjectContext: mangedObjectContext];

    [documentObject setOriginx: @(CGPointZero.x)];
    [documentObject setOriginy: @(CGPointZero.y)];
    [documentObject setSizewidth: @(200.0000f)];
    [documentObject setSizeheight: @(44.0000f)];

    NSEntityDescription *entityDescriptionDocumentObjectSubtype = nil;
    
    switch (objectType) {
        case MTDocumentObjectTypeLabelDynamic: {
            
            entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObjectLabelDataField class])
                                                                 inManagedObjectContext: mangedObjectContext];

            NSManagedObjectID *fieldObjectId = [documentObjectDefination objectForKey: MTDocumentObjectDefinationObject];
            RptqDatabaseSchemaField *field = [RptqDatabaseSchemaField getFieldForObjectID: fieldObjectId
                                                                        fromObjectContext: mangedObjectContext];
            
            
            RptqDocumentObjectLabelDataField *reportObject = [[RptqDocumentObjectLabelDataField alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
                                                                                       insertIntoManagedObjectContext: mangedObjectContext];
            
            [documentObject setIsLabelDataField: reportObject];
            
            [[documentObject isLabelDataField] setText: [NSString stringWithFormat:@"%@.%@", [[field inTable] name], [field name]]];
            [[documentObject isLabelDataField] setReferencesField: field];
            
            [reportObject setReferencesField: field];

            [documentObject setType: @(MTDocumentObjectTypeLabelDynamic)];
            
            [reportObject release];
            
            break;
        }
        case MTDocumentObjectTypeLabelStatic: {

            entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObjectLabel class])
                                                                 inManagedObjectContext: mangedObjectContext];

            NSString *labelText = [documentObjectDefination objectForKey:MTDocumentObjectDefinationObject];
            
            RptqDocumentObjectLabel *reportObject = [[RptqDocumentObjectLabel alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
                                                                     insertIntoManagedObjectContext: mangedObjectContext];
            
            [documentObject setIsLabel: reportObject];
            [[documentObject isLabel] setText: labelText];
            
            [documentObject setType: @(MTDocumentObjectTypeLabelStatic)];
            
            [reportObject release];
            
            break;
        }
        case MTDocumentObjectTypeAggregate: {

            entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObjectAggregate class])
                                                                 inManagedObjectContext: mangedObjectContext];
            
            NSDictionary *aggregateOptions = [documentObjectDefination objectForKey:MTDocumentObjectDefinationObject];
            
            RptqDocumentObjectAggregate *reportObject = [[RptqDocumentObjectAggregate alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
                                                                             insertIntoManagedObjectContext: [document managedObjectContext]];
            [documentObject setIsAggregate: reportObject];
            [documentObject setType: @(MTDocumentObjectTypeAggregate)];

            NSNumber *groupTypeContainer = [aggregateOptions objectForKey: MTDocumentObjectDefinationAggregatePivotType];
            NSNumber *functionInputType = [aggregateOptions objectForKey:MTDocumentObjectDefinationAggregateFunctionInputType];

            MTAggregateFunctionInputType functionType = [functionInputType integerValue];
            [[documentObject isAggregate] setGroupNumber:   [aggregateOptions objectForKey: MTDocumentObjectDefinationAggregatePivotNumber]];
            [[documentObject isAggregate] setGroupType:     groupTypeContainer];
            [[documentObject isAggregate] setFunction:      [aggregateOptions objectForKey: MTDocumentObjectDefinationAggregateType]];

            NSManagedObjectID *objectId = [aggregateOptions objectForKey:MTDocumentObjectDefinationAggregateObjectId];

            switch (functionType) {
                case MTAggregateFunctionInputTypeField: {
                    RptqDatabaseSchemaField *field = [RptqDatabaseSchemaField getFieldForObjectID:objectId fromObjectContext:mangedObjectContext];
                    [[documentObject isAggregate] setAggregateField:field];
                    [[documentObject isAggregate] setAggregateFunction:nil];
                    break;
                }
                case MTAggregateFunctionInputTypeFormula: {
                    RptqDocumentObjectFormula *formula = [RptqDocumentObjectFormula getElementForObjectID:objectId fromObjectContext:mangedObjectContext];
                    [[documentObject isAggregate] setAggregateField:nil];
                    [[documentObject isAggregate] setAggregateFunction:formula];
                    break;
                }
                default:
                    break;
            }
            
            [reportObject release];

            break;
        }
        case MTDocumentObjectTypeImage: {
            
            entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObjectImage class])
                                                                 inManagedObjectContext: mangedObjectContext];
            
            UIImage *image = [documentObjectDefination objectForKey:MTDocumentObjectDefinationObject];
            
            RptqDocumentObjectImage *reportObject = [[RptqDocumentObjectImage alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
                                                                     insertIntoManagedObjectContext: mangedObjectContext];
            
            [documentObject setIsImage: reportObject];
            [[documentObject isImage] setImage: image];
            [documentObject setSizeheight:@([image size].height)];
            [documentObject setSizewidth:@([image size].width)];
            [documentObject setType: @(MTDocumentObjectTypeImage)];
            
            [reportObject release];

            break;
        }
        default:
            break;
    }
    
    NSMutableOrderedSet *hasObjects = [[NSMutableOrderedSet alloc] initWithOrderedSet:[[[[document hasDetailSection] hasRows] objectAtIndex:0] hasObjects]];
    [hasObjects insertObject:documentObject atIndex:0];
    [[[[document hasDetailSection] hasRows] objectAtIndex:0] setHasObjects:hasObjects];
    [hasObjects release];
    
    if ([[[document hasDetailSection] height] floatValue] < [[documentObject sizeheight] floatValue]) {
        [[document hasDetailSection] setHeight:@([[documentObject sizeheight] floatValue] + 10.0000f)];
    }

    return [documentObject autorelease];
}

+ (id)getElementForObjectID:(NSManagedObjectID *)objid fromObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocumentObject class])];
    [request setPredicate: [NSPredicate predicateWithFormat:@"self == %@", objid]];
    
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:request error:&error];
    RptqDocumentObject *result = nil;
    if (results) result = [results lastObject];
    return result;
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self isEqualTo:sender]) {
        result = YES;
    } else {
        RptqDocumentObject *s = sender;
        result = [[self identifier] isEqualToNumber:[s identifier]];
    }
    return result;
}

#pragma mark - MTProtocolLog

- (NSString *)toString {
    NSString *result = nil;
    return result;
}

- (NSString *)toStringDebug {
    return nil;
}

- (NSString *)toStringHumanReadable {
    return nil;
}

- (NSAttributedString *)toAttributedString {
    return nil;
}

@end
