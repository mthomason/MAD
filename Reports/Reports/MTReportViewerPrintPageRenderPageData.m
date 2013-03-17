//
//  MTPrintPageRenderReportPageData.m
//  Reports
//
//  Created by Michael Thomason on 2/7/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTReportViewerPrintPageRenderPageData.h"

const NSString *MTReportSectionType = @"MTReportSectionType";
const NSString *MTReportSectionValues = @"MTReportSectionValues";
const NSString *MTReportGroupLevel = @"MTReportGroupLevel";

const NSString *MTPageDetail = @"MTPageDetail";
const NSString *MTPageHeader = @"MTPageHeader";
const NSString *MTPageFooter = @"MTPageFooter";
const NSString *MTReportHeader = @"MTReportHeader";
const NSString *MTReportFooter = @"MTReportFooter";
const NSString *MTReportGroupHeader = @"MTReportGroupHeader";
const NSString *MTReportGroupFooter = @"MTReportGroupFooter";

@interface MTReportViewerPrintPageRenderPageData()

@property (nonatomic, retain) NSMutableArray *cachedPageData;

@end

@implementation MTReportViewerPrintPageRenderPageData

- (id)copyWithZone:(NSZone *)zone {
    MTReportViewerPrintPageRenderPageData *copy = [[MTReportViewerPrintPageRenderPageData alloc] init];
    if (copy) {
        NSMutableArray *cachedPageData = [[NSMutableArray alloc] initWithArray:[self cachedPageData]];
        [copy setCachedPageData: cachedPageData];
        [cachedPageData release];
    }
    return copy;
}

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
    return [[[self cachedPageData] retain] autorelease];
}

- (void)addPageHeaderWithValueDictionary:(NSDictionary *)values {
    [[self cachedPageData] removeAllObjects];
    
    id newValue = [values copy];
    //NSLog(@"NewValue: %@", NSStringFromClass([newValue class]));
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTPageHeader forKey:MTReportSectionType];
    [sectionData setObject:newValue forKey:MTReportSectionValues];
    [[self cachedPageData] addObject: sectionData];
    [sectionData release];
    [newValue release];
}

- (void)addPageFooterWithValueDictionary:(NSDictionary *)values {
    id newValue = [values copy];
    //NSLog(@"NewValue: %@", NSStringFromClass([newValue class]));
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTPageFooter forKey:MTReportSectionType];
    [sectionData setObject:newValue forKey:MTReportSectionValues];
    [[self cachedPageData] addObject: sectionData];
    [sectionData release];
    [newValue release];
}

- (void)addReportHeaderWithValueDictionary:(NSDictionary *)values {
    id newValue = [values copy];
    //NSLog(@"NewValue: %@", NSStringFromClass([newValue class]));
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTReportHeader forKey:MTReportSectionType];
    [sectionData setObject:newValue forKey:MTReportSectionValues];
    [[self cachedPageData] addObject: sectionData];
    [sectionData release];
    [newValue release];
}

- (void)addReportFooterWithValueDictionary:(NSDictionary *)values {
    id newValue = [values copy];
    //NSLog(@"NewValue: %@", NSStringFromClass([newValue class]));
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTReportFooter forKey:MTReportSectionType];
    [sectionData setObject:newValue forKey:MTReportSectionValues];
    [[self cachedPageData] addObject: sectionData];
    [sectionData release];
    [newValue release];
}

- (void)addGroupHeaderWithValueDictionary:(NSDictionary *)values andLevel:(NSUInteger)groupLevel {
    id newValue = [values copy];
    //NSLog(@"NewValue: %@", NSStringFromClass([newValue class]));
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTReportGroupHeader forKey:MTReportSectionType];
    [sectionData setObject:newValue forKey:MTReportSectionValues];
    NSNumber *groupLevelObject = [[NSNumber alloc] initWithInteger:groupLevel];
    [sectionData setObject:groupLevelObject forKey:MTReportGroupLevel];
    [groupLevelObject release];
    [[self cachedPageData] addObject: sectionData];
    [sectionData release];
    [newValue release];
}

- (void)addGroupFooterWithValueDictionary:(NSDictionary *)values andLevel:(NSUInteger)groupLevel {
    id newValue = [values copy];
    //NSLog(@"NewValue: %@", NSStringFromClass([newValue class]));
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTReportGroupFooter forKey:MTReportSectionType];
    [sectionData setObject:newValue forKey:MTReportSectionValues];
    NSNumber *groupLevelObject = [[NSNumber alloc] initWithInteger:groupLevel];
    [sectionData setObject:groupLevelObject forKey:MTReportGroupLevel];
    [groupLevelObject release];
    [[self cachedPageData] addObject: sectionData];
    [sectionData release];
    [newValue release];
}

- (void)addDetailWithValueDictionary:(NSDictionary *)values {
    id newValue = [values copy];
    //NSLog(@"NewValue: %@", NSStringFromClass([newValue class]));
    NSMutableDictionary *sectionData = [[NSMutableDictionary alloc] initWithCapacity:3];
    [sectionData setObject:MTPageDetail forKey:MTReportSectionType];
    [sectionData setObject:newValue forKey:MTReportSectionValues];
    [[self cachedPageData] addObject: sectionData];
    [sectionData release];
    [newValue release];
}

@end