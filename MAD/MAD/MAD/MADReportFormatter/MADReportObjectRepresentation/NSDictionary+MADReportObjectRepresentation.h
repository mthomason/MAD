//
//  MADReportObjectRepresentation.h
//  MAD
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const MTReportSectionType;
extern NSString * const MTReportDetailRowId;
extern NSString * const MTReportGroupLevel;

typedef NS_ENUM(NSUInteger, MNSDocumentSectionType);
typedef NS_ENUM(NSUInteger, MNSDocumentSectionType) {
    MNSDocumentSectionTypeReportHeader = 1,
    MNSDocumentSectionTypeReportFooter = 2,
    MNSDocumentSectionTypePageHeader = 3,
    MNSDocumentSectionTypePageFooter = 4,
    MNSDocumentSectionTypeBody = 5,
    MNSDocumentSectionTypeGroupHeader = 6,
    MNSDocumentSectionTypeGroupFooter = 7,
};

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
