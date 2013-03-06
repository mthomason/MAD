//
//  MTPrintPageRenderReportPageData.h
//  Reports
//
//  Created by Michael Thomason on 2/7/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTPrintPageRenderReportPageData_h
#define Reports_MTPrintPageRenderReportPageData_h

#import <Foundation/Foundation.h>

extern const NSString *MTReportSectionType;
extern const NSString *MTReportSectionValues;
extern const NSString *MTReportGroupLevel;

extern const NSString *MTPageDetail;
extern const NSString *MTPageHeader;
extern const NSString *MTPageFooter;
extern const NSString *MTReportHeader;
extern const NSString *MTReportFooter;
extern const NSString *MTReportGroupHeader;
extern const NSString *MTReportGroupFooter;

@interface MTReportViewerPrintPageRenderPageData : NSObject

- (id)init;

- (void)addPageHeaderWithValueDictionary:(NSDictionary *)values;
- (void)addReportHeaderWithValueDictionary:(NSDictionary *)values;
- (void)addGroupHeaderWithValueDictionary:(NSDictionary *)values andLevel:(NSUInteger)groupLevel;
- (void)addDetailWithValueDictionary:(NSDictionary *)values;
- (void)addGroupFooterWithValueDictionary:(NSDictionary *)values andLevel:(NSUInteger)groupLevel;
- (void)addReportFooterWithValueDictionary:(NSDictionary *)values;
- (void)addPageFooterWithValueDictionary:(NSDictionary *)values;

- (NSArray *)enumeratePageSections;

@end

#endif
