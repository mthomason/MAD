//
//  MADocumentSectionType.h
//  MAD
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADocumentSectionType_h
#define MAD_MADocumentSectionType_h

#import <Foundation/NSObjCRuntime.h>

typedef NS_ENUM(int16_t, MADDocumentSectionType) {
	MADDocumentSectionTypeUnknown = 0,
	MADDocumentSectionTypeReportHeader = 1,
	MADDocumentSectionTypeReportFooter = 2,
	MADDocumentSectionTypePageHeader = 3,
	MADDocumentSectionTypePageFooter = 4,
	MADDocumentSectionTypeBody = 5,
	MADDocumentSectionTypeGroupHeader = 6,
	MADDocumentSectionTypeGroupFooter = 7,
};

static inline NSString *NSStringFromMADDocumentSectionType(MADDocumentSectionType);
static inline NSString *NSStringFromMADDocumentSectionType(MADDocumentSectionType value) {
	switch (value) {
		case MADDocumentSectionTypeReportHeader: return @"MADDocumentSectionTypeReportHeader";
		case MADDocumentSectionTypeReportFooter: return @"MADDocumentSectionTypeReportFooter";
		case MADDocumentSectionTypePageHeader: return @"MADDocumentSectionTypePageHeader";
		case MADDocumentSectionTypePageFooter: return @"MADDocumentSectionTypePageFooter";
		case MADDocumentSectionTypeBody: return @"MADDocumentSectionTypeBody";
		case MADDocumentSectionTypeGroupHeader: return @"MADDocumentSectionTypeGroupHeader";
		case MADDocumentSectionTypeGroupFooter: return @"MADDocumentSectionTypeGroupFooter";
		case MADDocumentSectionTypeUnknown: default: return @"MADDocumentSectionTypeUnknown";
	}
}

extern const NSUInteger MADDocumentSectionIndexDocumentHeader;
extern const NSUInteger MADDocumentSectionIndexPageHeader;
extern const NSUInteger MADDocumentSectionIndexDetail;
extern const NSUInteger MADDocumentSectionIndexPageFooter;
extern const NSUInteger MADDocumentSectionIndexDocumentFooter;

static inline NSUInteger documentSectionDynamicIndexDetail(NSUInteger numberOfGroups);
static inline NSUInteger documentSectionDynamicIndexDetail(NSUInteger numberOfGroups) {
	return MADDocumentSectionIndexDetail + numberOfGroups;
}

static inline NSUInteger documentSectionDynamicIndexPageFooter(NSUInteger numberOfGroups);
static inline NSUInteger documentSectionDynamicIndexPageFooter(NSUInteger numberOfGroups) {
	return MADDocumentSectionIndexPageFooter + (2 * numberOfGroups);
}

static inline NSUInteger documentSectionDynamicIndexDocumentFooter(NSUInteger numberOfGroups);
static inline NSUInteger documentSectionDynamicIndexDocumentFooter(NSUInteger numberOfGroups) {
	return MADDocumentSectionIndexDocumentFooter + (2 * numberOfGroups);
}

static inline BOOL isSectionDetail(NSUInteger index, NSUInteger numberOfGroups);
static inline BOOL isSectionDetail(NSUInteger index, NSUInteger numberOfGroups) {
	return index == documentSectionDynamicIndexDetail(numberOfGroups);
}

static inline BOOL isPageFooter(NSUInteger index, NSUInteger numberOfGroups);
static inline BOOL isPageFooter(NSUInteger index, NSUInteger numberOfGroups) {
	return index == documentSectionDynamicIndexPageFooter(numberOfGroups);
}

static inline BOOL isDocumentFooter(NSUInteger index, NSUInteger numberOfGroups);
static inline BOOL isDocumentFooter(NSUInteger index, NSUInteger numberOfGroups) {
	return index == documentSectionDynamicIndexDocumentFooter(numberOfGroups);
}

static inline BOOL isPageHeader(NSUInteger index);
static inline BOOL isPageHeader(NSUInteger index) {
	return index == MADDocumentSectionIndexPageHeader;
}

static inline BOOL isDocumentHeader(NSUInteger index);
static inline BOOL isDocumentHeader(NSUInteger index) {
	return index == MADDocumentSectionIndexDocumentHeader;
}

static inline BOOL isGroupHeader(NSUInteger index, NSUInteger numberOfGroups);
static inline BOOL isGroupHeader(NSUInteger index, NSUInteger numberOfGroups) {
	return ((index - MADDocumentSectionIndexPageHeader) <= numberOfGroups);
}

static inline MADDocumentSectionType documentSectionType(NSUInteger index, NSUInteger numberOfGroups);
static inline MADDocumentSectionType documentSectionType(NSUInteger index, NSUInteger numberOfGroups) {
	return isSectionDetail(index, numberOfGroups) ? MADDocumentSectionTypeBody :
	(isPageHeader(index) ? MADDocumentSectionTypePageHeader :
	 (isPageFooter(index, numberOfGroups) ? MADDocumentSectionTypePageFooter :
	  (isDocumentHeader(index) ? MADDocumentSectionTypeReportHeader :
	   (isDocumentFooter(index, numberOfGroups) ? MADDocumentSectionTypeReportFooter :
		(isGroupHeader(index, numberOfGroups) ?
		 MADDocumentSectionTypeGroupHeader :
		 MADDocumentSectionTypeGroupFooter)
		)
	   )
	  )
	 );
}

#endif /* MADocumentSectionType_h */
