//
//  MTReportFormatter.h
//  MAD
//
//  Created by Michael Thomason on 3/20/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MTReportFormatter_h
#define MAD_MTReportFormatter_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MAD/MTTableFormatter.h>
#import <MAD/MTReportFormatterDataSource.h>
#import <MADFoundation/MTCacheProtocol.h>
#import <MADFoundation/MADDataProtocol.h>

typedef NS_OPTIONS(NSUInteger, MTReportFormatterOptions) {
    MTReportFormatterOptionsNone    = 0,
    MTReportFormatterOptionsMargin  = 1 << 0,
};

extern NSString * const MTNullIdentifier;

@class MADocument, RptqDocumentSection, RptqDocument, MADArrayCaching,
        MTReportFormatterPageDefinition;

@interface MTReportFormatter : MTTableFormatter

@property (nonatomic, weak) id <MADDataProtocol> dataDelegate;

- (void)initalizeStateMachine;

- (instancetype)initWithQuery: (MTQuery *)query layout: (MADocument *)layout options: (MTReportFormatterOptions)options;
+ (instancetype)reportFormatterWithQuery: (MTQuery *)query layout: (MADocument *)layout
                                 options: (MTReportFormatterOptions)options NS_RETURNS_RETAINED;
+ (NSValue *)KeyReportSectionType;

- (void)formatForSize:(CGSize)printableSize;
- (void)formatForSize:(CGSize)printableSize contentChanged:(BOOL)contextChanged;
- (void)reformatForSize:(CGSize)printableSize;

- (NSEnumerator *)layoutEnumeratorForPage:(NSUInteger)pageIndex;
- (NSArray *)layoutForPage:(NSUInteger)page;

- (CGFloat)heightForSection:(RptqDocumentSection *)documentSection;
- (NSArray *)rowidsForPage:(NSUInteger)pageIndex;
- (NSArray *)keysForCachedID:(NSNumber *)rowid;

- (void)setLayoutSize:(CGSize)layoutSize;
- (void)setMarginUsingPrintableRect:(CGRect)printableRect;

@property (nonatomic, weak) id <MTReportFormatterDataSource> datasource;
@property (nonatomic, weak) id <MTCacheProtocol> cachedDelegate;

@property (nonatomic, strong, readonly) MTReportFormatterPageDefinition *page;

@property (nonatomic, weak, readonly) MADocument *layout;
@property (nonatomic, assign, readonly) NSUInteger numberOfPages;
@property (nonatomic, assign, readonly) NSUInteger numberOfGroups;

//  These are the rowids by page.  These point to data in the cache.
//      Once these arrays are populated, they are used by the print page render to
//      draw the report.
@property (nonatomic, strong, readonly) MADArrayCaching *reportIndexes;

//  `reportLayout` contains and object for each page.  Each object in `reportLayout` is an array
//      which represents a page.  The array contains dictionaries for each object on that page.
@property (nonatomic, strong, readonly) MADArrayCaching *reportLayout;

//  Use this to cache in location other than default.
@property (nonatomic, strong) NSString *overrideIdentifier;

@end

#endif
