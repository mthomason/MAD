//
//  MADReportObjectRepresentation.m
//  MAD
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <MAD/MADReportObjectRepresentation.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSString.h>

//Keys stored in the cache.  Short and unique.
NSString * const MTReportSectionType                    = @"a";
NSString * const MTReportGroupLevel                     = @"b";
NSString * const MTReportDetailRowId                    = @"d";

static NSString * const MADIdentifierReportObject       = @"o";

@interface MADReportObjectRepresentation ()
    @property (nonatomic, strong) NSDictionary *objectRepresentation;
@end

@implementation MADReportObjectRepresentation

- (instancetype)initWithSectionType:(MNSDocumentSectionType)sectionType
                         groupLevel:(NSUInteger)groupLevel {
    
    if (self = [super init]) {
        
        NSNumber *section = [[NSNumber alloc] initWithShort: sectionType];
        NSNumber *level = [[NSNumber alloc] initWithUnsignedInteger: groupLevel];
        NSDictionary *result = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                            section,    MTReportSectionType,
                                                            level,      MTReportGroupLevel, nil];
        self.objectRepresentation = result;
        
    }
    return self;
    
}

- (instancetype)initWithSectionType:(MNSDocumentSectionType)sectionType
                                row:(NSNumber *)row {
    
    if (self = [super init]) {
        
        NSNumber *section = [[NSNumber alloc] initWithShort: sectionType];
        NSNumber *rowID = row.copy;
        NSDictionary *result = [[NSDictionary alloc] initWithObjectsAndKeys:
                                section,    MTReportSectionType,
                                rowID,      MTReportDetailRowId, nil];
        self.objectRepresentation = result;
        
    }
    return self;
    
}

- (instancetype)initWithSectionType:(MNSDocumentSectionType)sectionType
                         groupLevel:(NSUInteger)groupLevel
                                row:(NSNumber *)row {
    
    if (self = [super init]) {
    
        NSNumber *section = [[NSNumber alloc] initWithShort: sectionType];
        NSNumber *level = [[NSNumber alloc] initWithUnsignedInteger: groupLevel];
        NSNumber *rowID = row.copy;
        NSDictionary *result = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                            section,    MTReportSectionType,
                                                            level,      MTReportGroupLevel,
                                                            rowID,      MTReportDetailRowId, nil];
        self.objectRepresentation = result;

    }
    return self;

}

+ (instancetype)newObjectRepresentationWithSectionType:(MNSDocumentSectionType)sectionType
                                            groupLevel:(NSUInteger)groupLevel
                                                   row:(NSNumber *)row {
    id result = [[MADReportObjectRepresentation alloc] initWithSectionType: sectionType
                                                                groupLevel: groupLevel
                                                                       row: row];
    return result;
    
}

+ (instancetype)newObjectRepresentationWithSectionType:(MNSDocumentSectionType)sectionType
                                                   row:(NSNumber *)row {
    
    id result = [[MADReportObjectRepresentation alloc] initWithSectionType: sectionType
                                                                       row: row];
    return result;
    
}

- (NSUInteger)groupLevel {
    return ((NSNumber *)self.objectRepresentation[MTReportGroupLevel]).unsignedIntegerValue;
}

- (MNSDocumentSectionType)sectionType {
    return ((NSNumber *)self.objectRepresentation[MTReportSectionType]).shortValue;
}

- (NSNumber *)detailRowId {
    return self.objectRepresentation[MTReportDetailRowId];
}

- (id)debugQuickLookObject {
    NSMutableString *debugString = [[NSMutableString alloc] init];
    [debugString appendString:@"MADReportObjectRepresentation\n"];
    [debugString appendString:@"-----------------------------\n"];
    [debugString appendFormat:@"Row ID:       %lu\n", self.detailRowId.unsignedIntegerValue];
    [debugString appendFormat:@"Section type: %lu\n", (unsigned long)self.sectionType];
    [debugString appendFormat:@"Group level:  %lu\n", (unsigned long)self.groupLevel];
    [debugString appendString:@"-----------------------------\n"];
    [debugString appendString:@"\n"];
    return @"";
}

@end
