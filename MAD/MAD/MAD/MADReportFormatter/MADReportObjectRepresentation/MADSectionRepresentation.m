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

@interface MADSectionRepresentation ()

    @property (readwrite, nonatomic, copy) NSNumber *row;

@end

@implementation MADSectionRepresentation {
    MADDocumentSectionType _sectionType;
    NSUInteger _groupLevel;
}

+ (instancetype)newSectionRepresentation:(MADDocumentSectionType)sectionType
                              groupLevel:(NSUInteger)groupLevel
                                     row:(NSNumber *)row {
    id result = [[self alloc] initSectionRepresentation:sectionType groupLevel:groupLevel row:row];
    return result;
}

+ (instancetype)newSectionRepresentation:(MADDocumentSectionType)sectionType
                                     row:(NSNumber *)row {
    id result = [[self alloc] initSectionRepresentation:sectionType row:row];
    return result;
}

- (instancetype)initSectionRepresentation:(MADDocumentSectionType)sectionType
                                      row:(NSNumber *)row {
    return [self initSectionRepresentation:sectionType groupLevel:NSUIntegerMax row:row];
}

- (instancetype)initSectionRepresentation:(MADDocumentSectionType)sectionType
                              groupLevel:(NSUInteger)groupLevel
                                     row:(NSNumber *)row {
    if (self = [super init]) {
        _sectionType = sectionType;
        _groupLevel = groupLevel;
        self.row = row.copy;
    }
    return self;
}

- (NSUInteger)groupLevel {
    return _groupLevel;
}

- (MADDocumentSectionType)sectionType {
    return _sectionType;
}

- (NSNumber *)detailRowId {
    return self.row;
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
