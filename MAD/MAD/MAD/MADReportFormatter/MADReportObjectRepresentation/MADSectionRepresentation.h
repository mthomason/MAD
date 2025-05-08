//
//  MADSectionRepresentation.h
//  MAD
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADSectionPlist_MADReportObjectRepresentation_h
#define MAD_MADSectionPlist_MADReportObjectRepresentation_h

#import <Foundation/NSObject.h>
#import <MAD/MADocumentSectionType.h>

@interface MADSectionRepresentation : NSObject <NSCoding, NSSecureCoding>

+ (instancetype)newSectionRepresentation:(MADDocumentSectionType)sectionType
							  groupLevel:(NSUInteger)groupLevel
									 row:(NSUInteger)row;
+ (instancetype)newSectionRepresentation:(MADDocumentSectionType)sectionType
									 row:(NSUInteger)row;

- (NSUInteger)groupLevel;
- (MADDocumentSectionType)sectionType;
- (NSUInteger)detailRowId;

@end

#endif
