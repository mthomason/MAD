//
//  MADDocumentSectionType.h
//  MAD
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADDocumentSectionType_h
#define MAD_MADDocumentSectionType_h

//Do not change these enum values, as they are used in core data.
typedef NS_ENUM(NSUInteger, MNSDocumentSectionType) {
    MNSDocumentSectionTypeReportHeader = 1,
    MNSDocumentSectionTypeReportFooter = 2,
    MNSDocumentSectionTypePageHeader = 3,
    MNSDocumentSectionTypePageFooter = 4,
    MNSDocumentSectionTypeBody = 5,
    MNSDocumentSectionTypeGroupHeader = 6,
    MNSDocumentSectionTypeGroupFooter = 7,
};

#endif /* MADDocumentSectionType_h */
