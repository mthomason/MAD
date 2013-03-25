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
    [self setMarginBottom:@(0.0000f)];
    [self setMarginTop:@(0.0000f)];
    [self setMarginLeft:@(0.0000f)];
    [self setMarginRight:@(0.0000f)];
    [self setPaddingBottom:@(0.0000f)];
    [self setPaddingTop:@(0.0000f)];
    [self setPaddingLeft:@(0.0000f)];
    [self setPaddingRight:@(0.0000f)];
    [self setVerticalAlignment:@(MTVerticalAlignmentTop)];
    [self setHorizontalAlignment:@(MTHorizontalAlignmentLeft)];
    
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
            NSInteger groupNumber = [[[self isGroupKey] groupNumber] integerValue];
            NSString *groupNumberText = [NSNumberFormatter localizedStringFromNumber: groupNumber
                                                                         numberStyle: NSNumberFormatterSpellOutStyle];
            
            MTAggregateGroupType groupType = [[[self isAggregate] groupType] integerValue];
            switch (groupType) {
                case MTAggregateGroupTypeField: {
                    NSString *aggregateFormatString = NSLocalizedString(@"Group on section %@ with field %@.", @"Group on section section-number with field field-name.");
                    result = [NSString stringWithFormat:aggregateFormatString, [groupNumberText lowercaseString], [[[self isAggregate] aggregateField] toStringHumanReadable]];
                    break;
                }
                case MTAggregateGroupTypeFormula: {
                    NSString *aggregateFormatString = NSLocalizedString(@"Group on section %@ with formula %@.", @"Group on section section-number with formula formula-name.");
                    result = [NSString stringWithFormat:aggregateFormatString, [groupNumberText lowercaseString], [[[self isAggregate] aggregateFunction] toStringHumanReadable]];
                    break;
                }
                default:
                    break;
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

    RptqDocumentObject *result = nil;
    MTDocumentObjectType objectType = [[documentObjectDefination objectForKey:MTDocumentObjectDefinationType] integerValue];
    //id object = [documentObjectDefination objectForKey:MTDocumentObjectDefinationObject];
    
    switch (objectType) {
        case MTDocumentObjectTypeLabelDynamic:
            result = [RptqDocumentObjectLabelDataField addDocumentObject:documentObjectDefination toDocument:document];
            break;
        case MTDocumentObjectTypeLabelStatic:
            result = [RptqDocumentObjectLabel addDocumentObject:documentObjectDefination toDocument:document];
            break;
        default:
            break;
    }

    [result setOriginx: @(CGPointZero.x)];
    [result setOriginy: @(CGPointZero.y)];
    [result setSizewidth: @(200.0000f)];
    [result setSizeheight: @(44.0000f)];

    return result;
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
