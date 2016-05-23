//
//  MADocumentSectionType.h
//  MAD
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADocumentSectionType_h
#define MADocumentSectionType_h

typedef NS_ENUM(short, MNSDocumentSectionType) {
    MNSDocumentSectionTypeReportHeader = 1,
    MNSDocumentSectionTypeReportFooter = 2,
    MNSDocumentSectionTypePageHeader = 3,
    MNSDocumentSectionTypePageFooter = 4,
    MNSDocumentSectionTypeBody = 5,
    MNSDocumentSectionTypeGroupHeader = 6,
    MNSDocumentSectionTypeGroupFooter = 7,
};

#endif /* MADocumentSectionType_h */
