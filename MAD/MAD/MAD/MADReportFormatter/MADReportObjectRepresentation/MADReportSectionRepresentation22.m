//
//  MADReportplist.m
//  MAD
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADReportSectionRepresentation22.h"
#import <Foundation/NSValue.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSCoder.h>

//Keys stored in the cache.  Short and unique.

NSString * const MTReportSectionType                    = @"a";
NSString * const MTReportGroupLevel                     = @"b";
NSString * const MTReportDetailRowId                    = @"d";

static NSString * const MADIdentifierReportObject       = @"o";

@interface MADReportSectionRepresentation22 ()
    //@property (nonatomic, strong, readwrite) MADSectionPlist *plist;
@end

@implementation MADReportSectionRepresentation22

/*
- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_plist];
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        //NSDictionary *plist = [[NSDictionary alloc] initWithDictionary: [decoder decodeObject]];
        self.plist = [decoder decodeObject];
    }
    
    return self;
}
*/

- (instancetype)initWithPlist:(MADSectionPlist *)plist {
    if (self = [super initWithDictionary:plist]) { }
    return self;
    
}

- (instancetype)initWithSectionType:(MNSDocumentSectionType)sectionType
                         groupLevel:(NSUInteger)groupLevel {
    
    NSNumber *section = [[NSNumber alloc] initWithShort: sectionType];
    NSNumber *level = [[NSNumber alloc] initWithUnsignedInteger: groupLevel];
    self = [super initWithObjectsAndKeys: section,    MTReportSectionType,
                                          level,      MTReportGroupLevel, nil];
    return self;
    
}

- (instancetype)initWithSectionType:(MNSDocumentSectionType)sectionType
                                row:(NSNumber *)row {
    
    NSNumber *section = [[NSNumber alloc] initWithShort: sectionType];
    NSNumber *rowID = row.copy;
    self = [super initWithObjectsAndKeys: section,    MTReportSectionType,
                                          rowID,      MTReportDetailRowId, nil];
    return self;
    
}

- (instancetype)initWithSectionType:(MNSDocumentSectionType)sectionType
                         groupLevel:(NSUInteger)groupLevel
                                row:(NSNumber *)row {
    NSNumber *section = [[NSNumber alloc] initWithShort: sectionType];
    NSNumber *level = [[NSNumber alloc] initWithUnsignedInteger: groupLevel];
    NSNumber *rowID = row.copy;
    
    self = [super initWithObjectsAndKeys: section,    MTReportSectionType,
                                          level,      MTReportGroupLevel,
                                          rowID,      MTReportDetailRowId, nil];
    return self;

}

+ (instancetype)newSectionRepresentationWithType:(MNSDocumentSectionType)sectionType
                                      groupLevel:(NSUInteger)groupLevel
                                             row:(NSNumber *)row {

    id result = [[MADReportSectionRepresentation22 alloc] initWithSectionType:sectionType
                                                                   groupLevel:groupLevel row:row];
    return result;
    
}

+ (instancetype)newSectionRepresentationWithType:(MNSDocumentSectionType)sectionType
                                             row:(NSNumber *)row {
    id result = [[MADReportSectionRepresentation22 alloc] initWithSectionType:sectionType row:row];
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
