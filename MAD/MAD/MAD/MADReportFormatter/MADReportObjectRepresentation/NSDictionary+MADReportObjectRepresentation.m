//
//  MADReportObjectRepresentation.m
//  MAD
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "NSDictionary+MADReportObjectRepresentation.h"
#import <Foundation/NSValue.h>
#import <Foundation/NSString.h>

//Keys stored in the cache.  Short and unique.
NSString * const MTReportSectionType                    = @"a";
NSString * const MTReportGroupLevel                     = @"b";
NSString * const MTReportDetailRowId                    = @"d";

static NSString * const MADIdentifierReportObject       = @"o";

@implementation NSDictionary (MADReportObjectRepresentation)

+ (instancetype)newObjectRepresentationWithSectionType:(MNSDocumentSectionType)sectionType
                                            groupLevel:(NSUInteger)groupLevel
                                                   row:(NSNumber *)row {
    NSNumber *section = @(sectionType);
    NSNumber *level = @(groupLevel);
    NSDictionary *result = [[NSDictionary alloc] initWithObjectsAndKeys:
                            section,    MTReportSectionType,
                            level,      MTReportGroupLevel,
                            row,        MTReportDetailRowId, nil];
    return result;
}

+ (instancetype)newObjectRepresentationWithSectionType:(MNSDocumentSectionType)sectionType
                                                   row:(NSNumber *)row {
    NSNumber *section = @(sectionType);
    NSDictionary *result = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                section,    MTReportSectionType,
                                                row,        MTReportDetailRowId, nil];
    return result;
}

- (NSUInteger)groupLevel {
    return ((NSNumber *)self[MTReportGroupLevel]).unsignedIntegerValue;
}

- (MNSDocumentSectionType)sectionType {
    return ((NSNumber *)self[MTReportSectionType]).shortValue;
}

- (NSNumber *)detailRowId {
    return self[MTReportDetailRowId];
}

- (id)debugQuickLookObject {
    NSMutableString *debugString = [[NSMutableString alloc] init];
    [debugString appendFormat:@"S:\t%lu", (unsigned long)self.sectionType];
    [debugString appendFormat:@"S:\t%lu", (unsigned long)self.groupLevel];
    [debugString appendFormat:@"S:\t%@", self.detailRowId];
    return @"";
}

@end
