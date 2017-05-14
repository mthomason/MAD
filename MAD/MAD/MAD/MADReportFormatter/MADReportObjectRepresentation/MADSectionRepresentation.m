//
//  MADReportplist.m
//  MAD
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADSectionRepresentation.h"
#import <Foundation/NSValue.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSCoder.h>

@implementation MADSectionRepresentation {
    MADDocumentSectionType _sectionType;
    NSUInteger _groupLevel;
    NSUInteger _row;
}

+ (instancetype)newSectionRepresentation:(MADDocumentSectionType)sectionType
                              groupLevel:(NSUInteger)groupLevel
                                     row:(NSUInteger)row {
    id result = [[self alloc] initSectionRepresentation: sectionType
                                             groupLevel: groupLevel
                                                    row: row];
    return result;
}

+ (instancetype)newSectionRepresentation:(MADDocumentSectionType)sectionType
                                     row:(NSUInteger)row {
    id result = [[self alloc] initSectionRepresentation: sectionType
                                             groupLevel: NSUIntegerMax
                                                    row: row];
    return result;
}

- (instancetype)initSectionRepresentation:(MADDocumentSectionType)sectionType
                                      row:(NSUInteger)row {
    return [self initSectionRepresentation: sectionType
                                groupLevel: NSUIntegerMax
                                       row: row];
}

- (instancetype)initSectionRepresentation:(MADDocumentSectionType)sectionType
                              groupLevel:(NSUInteger)groupLevel
                                     row:(NSUInteger)row {
    if (self = [super init]) {
        _sectionType = sectionType;
        _groupLevel = groupLevel;
        _row = row;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        [decoder decodeValueOfObjCType:@encode(MADDocumentSectionType) at:&_sectionType];
        [decoder decodeValueOfObjCType:@encode(NSUInteger) at:&_groupLevel];
        [decoder decodeValueOfObjCType:@encode(NSUInteger) at:&_row];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeValueOfObjCType:@encode(MADDocumentSectionType) at:&_sectionType];
    [encoder encodeValueOfObjCType:@encode(NSUInteger) at:&_groupLevel];
    [encoder encodeValueOfObjCType:@encode(NSUInteger) at:&_row];
}

- (NSUInteger)groupLevel {
    return _groupLevel;
}

- (MADDocumentSectionType)sectionType {
    return _sectionType;
}

- (NSUInteger)detailRowId {
    return _row;
}

- (id)debugQuickLookObject {
    NSMutableString *debugString = [[NSMutableString alloc] init];
    [debugString appendString:@"MADReportplist\n"];
    [debugString appendString:@"-----------------------------\n"];
    [debugString appendFormat:@"Row ID:       %lu\n", (unsigned long)self.detailRowId];
    [debugString appendFormat:@"Section type: %lld\n", self.sectionType];
    [debugString appendFormat:@"Group level:  %lu\n", (unsigned long)self.groupLevel];
    [debugString appendString:@"-----------------------------\n"];
    [debugString appendString:@"\n"];
    return @"";
}

@end
