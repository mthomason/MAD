//
//  MADSectionGroupLayout.m
//  MAD
//
//  Created by Michael on 5/28/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADSectionGroupLayout.h"
#import <CoreFoundation/CFNumber.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>
#import <Foundation/NSBundle.h>
#import <MADFoundation/MADDataType.h>
#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"

@implementation MADSectionGroupLayout {
    int64_t _dropIndex;
    NSString *_tableAlias;
    NSString *_fieldName;
}

- (instancetype)initWithObject:(NSDictionary *)object
          managedObjectContext:(NSManagedObjectContext *)managedObjectContext
                safeIdentifier:(NSString * (^)(NSString *))safeIdentifier {
    if (self = [super initWithObject: object managedObjectContext: managedObjectContext]) {
        
        if (self.type == MADDocumentSectionTypeGroupHeader || self.type == MADDocumentSectionTypeGroupFooter) {
            NSString *keyPathInGroupWeight = [RptqDocumentSection keyPathInGroupWeight],
                     *keyPathInGroupSort = [RptqDocumentSection keyPathInGroupSort],
                     *keyPathInGroupHasFieldDatabaseSchemaFieldDataType = [RptqDocumentSection keyPathInGroupHasFieldDatabaseSchemaFieldDataType],
                     *keyPathInGroupHasFieldInQueryTableAlias = [RptqDocumentSection keyPathInGroupHasFieldInQueryTableAlias],
                     *keyPathInGroupHasFieldDatabaseSchemaFieldName = [RptqDocumentSection keyPathInGroupHasFieldDatabaseSchemaFieldName],
                     *keyPathInGroupHasFieldInQueryTableDropIndex = [RptqDocumentSection keyPathInGroupHasFieldInQueryTableDropIndex];
        
            NSNumber *number = object[keyPathInGroupSort];
            CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)number, kCFNumberSInt16Type, &_sort);

            number = object[keyPathInGroupWeight];
            CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)number, kCFNumberSInt16Type, &_weight);
            
            number = object[keyPathInGroupHasFieldDatabaseSchemaFieldDataType];
            CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)number, kCFNumberSInt16Type, &_dataType);
            
            NSString *tableAlias = object[keyPathInGroupHasFieldInQueryTableAlias];
            _tableAlias = tableAlias.copy;

            NSString *fieldName = object[keyPathInGroupHasFieldDatabaseSchemaFieldName];
            _fieldName = fieldName.copy;

            number = object[keyPathInGroupHasFieldInQueryTableDropIndex];
            CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)number, kCFNumberSInt64Type, &_dropIndex);

            self.safeIdentifier = safeIdentifier;
        }
    
    }
    return self;
}

- (BOOL)sortAscending {
    return _sort == MADSortOrderAccending;
}

- (NSString *)safeSortKey {
    NSString *queryTableAlias = [RptqQueryTable queryAliasForSchemaTableName:_tableAlias dropIndex:_dropIndex];
    NSString *safeTableAlias = self.safeIdentifier(queryTableAlias);
    NSString *safeFieldName = self.safeIdentifier(_fieldName);
    NSString *sortKey = [safeTableAlias stringByAppendingString:@"."];
    return [sortKey stringByAppendingString:safeFieldName];
}

- (NSSortDescriptor *)sortDescriptor {
    SEL sel = MADDataTypeSelectorForSorting(self.dataType);
    id result = [[NSSortDescriptor alloc] initWithKey: [self safeSortKey]
                                            ascending: [self sortAscending]
                                             selector: sel];
    return result;
}

- (NSString *)localizedDisplay {
    NSString *result, *format;
    switch (self.type) {
                        
        case MADDocumentSectionTypeGroupHeader:
            format = NSLocalizedString(@"Group Header (%@)", @"\"Group Header\"");
            result = [self safeSortKey];
            result = [[NSString alloc] initWithFormat: format, result];
            break;
            
        case MADDocumentSectionTypeGroupFooter:
            format = NSLocalizedString(@"Group Footer (%@)", @"\"Group Footer\"");
            result = [self safeSortKey];
            result = [[NSString alloc] initWithFormat: format, result];
            break;
            
        default:
            break;
            
    }
    return result;
}

@end
