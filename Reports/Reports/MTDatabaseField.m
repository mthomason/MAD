//
//  MNSDatabaseField.m
//  Reports
//
//  Created by Michael Thomason on 11/18/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabaseField.h"

@implementation MTDatabaseField

- (void)dealloc {
    [_label release];
    [_name release];
    //[_datatype release];
    [super dealloc];
}

- (id)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        [self setLabel: name];
        [self setName: name];
    }
    return self;
}

- (BOOL)isNumeric {
    return [MTDatabaseField isNumeric:[self fieldType]];
}

+ (BOOL)isNumeric:(MTDataType)dataType {
    BOOL result;
    switch (dataType) {
        case MTDataTypeBit:
        case MTDataTypeFloat:
        case MTDataTypeInteger:
        case MTDataTypeNumber:
        case MTDataTypeDecimal:
        case MTDataTypeDouble:
        case MTDataTypeEnum:
        case MTDataTypeInt24:
        case MTDataTypeLong:
        case MTDataTypeLongLong:
        case MTDataTypeShort:
            result = YES;
            break;
        case MTDataTypeBlob:
        case MTDataTypeDate:
        case MTDataTypeDateTime:
        case MTDataTypeGeometry:
        case MTDataTypeImage:
        case MTDataTypeSet:
        case MTDataTypeString:
        case MTDataTypeTime:
        case MTDataTypeTimeStamp:
        case MTDataTypeYear:
        case MTDataTypeUnknown:
        case MTDataTypeVarChar:
        default:
            result = NO;
            break;
    }
    return result;
}

- (SEL)selectorForSorting {
    return [MTDatabaseField selectorForSorting:[self fieldType]];
}

+ (SEL)selectorForSorting:(MTDataType)dataType {
    SEL result;
    switch (dataType) {
        case MTDataTypeDate:
        case MTDataTypeDateTime:
        case MTDataTypeGeometry:
        case MTDataTypeImage:
        case MTDataTypeSet:
        case MTDataTypeTime:
        case MTDataTypeTimeStamp:
        case MTDataTypeYear:
        case MTDataTypeUnknown:
            @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                           reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MNSDtabase; don't use it directly.", NSStringFromSelector(_cmd)]
                                         userInfo: nil];
            
            break;
        case MTDataTypeBlob:
        case MTDataTypeBit:
        case MTDataTypeFloat:
        case MTDataTypeInteger:
        case MTDataTypeNumber:
            result = @selector(compare:);
            break;
        case MTDataTypeString:
            result = @selector(caseInsensitiveCompare:);
            break;
        default:
            result = @selector(compare:);
            break;
    }
    return result;
}

@end
