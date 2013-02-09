//
//  MTPrintPageRenderReportPageData.m
//  Reports
//
//  Created by Michael Thomason on 2/7/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTPrintPageRenderReportPageData.h"

const NSString *MTReportSectionType = @"MTReportSectionType";
const NSString *MTReportSectionValues = @"MTReportSectionValues";

const NSString *MTPageDetail = @"MTPageDetail";
const NSString *MTPageHeader = @"MTPageHeader";
const NSString *MTPageFooter = @"MTPageFooter";
const NSString *MTReportHeader = @"MTReportHeader";
const NSString *MTReportFooter = @"MTReportFooter";
const NSString *MTReportGroupHeader = @"MTReportGroupHeader";
const NSString *MTReportGroupFooter = @"MTReportGroupFooter";

@interface MTPrintPageRenderReportPageData()

@property (nonatomic, retain, readwrite) NSMutableArray *cachedPageData;

@end

@implementation MTPrintPageRenderReportPageData

- (void)dealloc {
    [_cachedPageData release];
    [super dealloc];
}

- (id)init {
    self = [super init];
    if (self) {
        NSMutableArray *pageData = [[NSMutableArray alloc] init];
        [self setCachedPageData:pageData];
        [pageData release];
    }
    return self;
}

- (NSArray *)enumeratePageSections {
    return [self cachedPageData];
}

- (void)addPageHeaderWithValueDictionary:(NSDictionary *)values {
    [[self cachedPageData] removeAllObjects];
    
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTPageHeader forKey:MTReportSectionType];
    [sectionData setObject:values forKey:MTReportSectionValues];
    [[self cachedPageData] addObject: sectionData];
    [sectionData release];
}

- (void)addPageFooterWithValueDictionary:(NSDictionary *)values {
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTPageFooter forKey:MTReportSectionType];
    [sectionData setObject:values forKey:MTReportSectionValues];
    [[self cachedPageData] addObject: sectionData];
    [sectionData release];
}

- (void)addReportHeaderWithValueDictionary:(NSDictionary *)values {
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTReportHeader forKey:MTReportSectionType];
    [sectionData setObject:values forKey:MTReportSectionValues];
    [[self cachedPageData] addObject: sectionData];
    [sectionData release];
}

- (void)addReportFooterWithValueDictionary:(NSDictionary *)values {
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTReportFooter forKey:MTReportSectionType];
    [sectionData setObject:values forKey:MTReportSectionValues];
    [[self cachedPageData] addObject: sectionData];
    [sectionData release];
}

- (void)addGroupHeaderWithValueDictionary:(NSDictionary *)values {
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTReportGroupHeader forKey:MTReportSectionType];
    [sectionData setObject:values forKey:MTReportSectionValues];
    [[self cachedPageData] addObject: sectionData];
    [sectionData release];
}

- (void)addGroupFooterWithValueDictionary:(NSDictionary *)values {
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTReportGroupFooter forKey:MTReportSectionType];
    [sectionData setObject:values forKey:MTReportSectionValues];
    [[self cachedPageData] addObject: sectionData];
    [sectionData release];
}

- (void)addDetailWithValueDictionary:(NSDictionary *)values {
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTPageDetail forKey:MTReportSectionType];
    [sectionData setObject:values forKey:MTReportSectionValues];
    [[self cachedPageData] addObject: sectionData];
    [sectionData release];
}

@end