//
//  MADSectionPlist.h
//  MAD
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADSectionPlist_MADReportObjectRepresentation_h
#define MAD_MADSectionPlist_MADReportObjectRepresentation_h

#import <Foundation/NSDictionary.h>
#import "MADocumentSectionType.h"

extern NSString * const MTReportSectionType;
extern NSString * const MTReportDetailRowId;
extern NSString * const MTReportGroupLevel;

typedef NSDictionary  <NSString *, NSNumber *> MADSectionPlist;

@interface  NSDictionary (MADSectionPlist)

    + (MADSectionPlist *)newSectionRepresentationWithType:(MNSDocumentSectionType)sectionType
                                               groupLevel:(NSUInteger)groupLevel
                                                      row:(NSNumber *)row;

    + (MADSectionPlist *)newSectionRepresentationWithType:(MNSDocumentSectionType)sectionType
                                                      row:(NSNumber *)row;

    - (NSUInteger)groupLevel;
    - (MNSDocumentSectionType)sectionType;
    - (NSNumber *)detailRowId;

@end

#endif
