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

- (MADSectionPlist *)initWithPlist:(MADSectionPlist *)plist {
    if (self = [self initWithDictionary:plist]) { }
    return self;
}

- (MADSectionPlist *)initWithSectionType:(MNSDocumentSectionType)sectionType
                              groupLevel:(NSUInteger)groupLevel {
    
    NSNumber *section = [[NSNumber alloc] initWithShort: sectionType];
    NSNumber *level = [[NSNumber alloc] initWithUnsignedInteger: groupLevel];
    self = [self initWithObjectsAndKeys: section,    MTReportSectionType,
                                         level,      MTReportGroupLevel, nil];
    return self;
    
}

- (MADSectionPlist *)initWithSectionType:(MNSDocumentSectionType)sectionType
                                     row:(NSNumber *)row {
    
    NSNumber *section = [[NSNumber alloc] initWithShort: sectionType];
    NSNumber *rowID = row.copy;
    self = [self initWithObjectsAndKeys: section,    MTReportSectionType,
                                         rowID,      MTReportDetailRowId, nil];
    return self;
    
}

- (MADSectionPlist *)initWithSectionType:(MNSDocumentSectionType)sectionType
                              groupLevel:(NSUInteger)groupLevel
                                     row:(NSNumber *)row {
    NSNumber *section = [[NSNumber alloc] initWithShort: sectionType];
    NSNumber *level = [[NSNumber alloc] initWithUnsignedInteger: groupLevel];
    NSNumber *rowID = row.copy;
    
    self = [self initWithObjectsAndKeys: section,    MTReportSectionType,
                                         level,      MTReportGroupLevel,
                                         rowID,      MTReportDetailRowId, nil];
    return self;

}

+ (MADSectionPlist *)newSectionRepresentationWithType:(MNSDocumentSectionType)sectionType
                                      groupLevel:(NSUInteger)groupLevel
                                             row:(NSNumber *)row {

    MADSectionPlist *result = [[MADSectionPlist alloc] initWithSectionType:sectionType
                                                                groupLevel:groupLevel row:row];
    return result;
    
}

+ (MADSectionPlist *)newSectionRepresentationWithType:(MNSDocumentSectionType)sectionType
                                                  row:(NSNumber *)row {
    MADSectionPlist *result = [[MADSectionPlist alloc] initWithSectionType:sectionType row:row];
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
