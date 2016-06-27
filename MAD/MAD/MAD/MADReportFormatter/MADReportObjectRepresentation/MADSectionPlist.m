//
//  MADReportplist.m
//  MAD
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADSectionPlist.h"
#import <Foundation/NSValue.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSCoder.h>

//Keys stored in the cache.  Short and unique.

NSString * const MTReportSectionType                    = @"a";
NSString * const MTReportGroupLevel                     = @"b";
NSString * const MTReportDetailRowId                    = @"d";

static NSString * const MADIdentifierReportObject       = @"o";

@implementation NSDictionary (MADSectionPlist)

+ (MADSectionPlist *)newSectionRepresentationWithType:(MADDocumentSectionType)sectionType
                                           groupLevel:(NSUInteger)groupLevel
                                                  row:(NSNumber *)row {
    
    NSNumber *section = [[NSNumber alloc] initWithShort:sectionType];
    NSNumber *level = [[NSNumber alloc] initWithUnsignedInteger:groupLevel];
    NSNumber *rowID = row.copy;
    MADSectionPlist *result = [[MADSectionPlist alloc] initWithObjectsAndKeys:
                                                            section,    MTReportSectionType,
                                                            level,      MTReportGroupLevel,
                                                            rowID,      MTReportDetailRowId, nil];
    return result;
    
}

+ (MADSectionPlist *)newSectionRepresentationWithType:(MADDocumentSectionType)sectionType
                                                  row:(NSNumber *)row {
    NSNumber *section = [[NSNumber alloc] initWithShort:sectionType];
    NSNumber *rowID = row.copy;
    MADSectionPlist *result = [[MADSectionPlist alloc] initWithObjectsAndKeys:
                                                            section,    MTReportSectionType,
                                                            rowID,      MTReportDetailRowId, nil];
    return result;
}

- (NSUInteger)groupLevel {
    return ((NSNumber *)self[MTReportGroupLevel]).unsignedIntegerValue;
}

- (MADDocumentSectionType)sectionType {
    return ((NSNumber *)self[MTReportSectionType]).shortValue;
}

- (NSNumber *)detailRowId {
    return self[MTReportDetailRowId];
}

- (id)debugQuickLookObject {
    NSMutableString *debugString = [[NSMutableString alloc] init];
    [debugString appendString:@"MADReportplist\n"];
    [debugString appendString:@"-----------------------------\n"];
    [debugString appendFormat:@"Row ID:       %lu\n", (unsigned long)self.detailRowId.unsignedIntegerValue];
    [debugString appendFormat:@"Section type: %lu\n", (unsigned long)self.sectionType];
    [debugString appendFormat:@"Group level:  %lu\n", (unsigned long)self.groupLevel];
    [debugString appendString:@"-----------------------------\n"];
    [debugString appendString:@"\n"];
    return @"";
}

@end
