//
//  MADReportObjectRepresentation.h
//  MAD
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_NSDictionary_MADReportObjectRepresentation_h
#define MAD_NSDictionary_MADReportObjectRepresentation_h

#import <Foundation/NSDictionary.h>
#import "MADDocumentSectionType.h"

extern NSString * const MTReportSectionType;
extern NSString * const MTReportDetailRowId;
extern NSString * const MTReportGroupLevel;

@interface NSDictionary (MADReportObjectRepresentation)

+ (instancetype)newObjectRepresentationWithSectionType:(MNSDocumentSectionType)sectionType
                                            groupLevel:(NSUInteger)groupLevel
                                                   row:(NSNumber *)row;

+ (instancetype)newObjectRepresentationWithSectionType:(MNSDocumentSectionType)sectionType
                                                   row:(NSNumber *)row;

- (NSUInteger)groupLevel;
- (MNSDocumentSectionType)sectionType;
- (NSNumber *)detailRowId;

@end

#endif
