//
//  MTReportFormatter.h
//  MAD
//
//  Created by Michael Thomason on 3/20/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MTReportFormatter_h
#define MAD_MTReportFormatter_h

#import <CoreGraphics/CGGeometry.h>
#import <MAD/MTTableFormatter.h>
#import <MADFoundation/MTCacheProtocol.h>
#import <MADFoundation/MADDataProtocol.h>
#import <MAD/MADSectionPlist.h>

typedef NS_OPTIONS(NSUInteger, MTReportFormatterOptions) {
    MTReportFormatterOptionsNone    = 0,
    MTReportFormatterOptionsMargin  = 1 << 0,
};

@protocol MTReportFormatterDataSource <NSObject>

    - (BOOL)cacheExist;
    - (NSEnumerator *)enumeratorForReportData;
    - (NSDictionary *)dataForCacheId:(NSNumber *)cachedID;

@end

extern NSString * const MTNullIdentifier;

@class MADocument, RptqDocumentSection, RptqDocument, MADArrayCaching,
        MTReportFormatterPageDefinition;

@class MADArrayCaching<ObjectType>;

typedef NSArray         <__kindof id>                                   MADObjectArray;
typedef NSArray         <__kindof MADSectionPlist *>                    MADSectionArray;
typedef NSArray         <__kindof NSNumber *>                           MADIndexArray;

typedef MADArrayCaching <__kindof MADIndexArray *>                      MADCachingIndexes;
typedef MADArrayCaching <__kindof MADSectionArray *>                    MADCachingLayout;

@interface MTReportFormatter : MTTableFormatter

    @property (nonatomic, weak) id <MADDataProtocol> dataDelegate;

    //  These are the rowids by page.  These point to data in the cache.
    //      Once these arrays are populated, they are used by the print page render to
    //      draw the report.
    @property (nonatomic, strong, readonly) MADCachingIndexes *reportIndexes;

    //  `reportLayout` contains and object for each page.  Each object in `reportLayout` is an array
    //      which represents a page.  The array contains dictionaries for each object on that page.
    @property (nonatomic, strong, readonly) MADCachingLayout *reportLayout;

    @property (nonatomic, weak)             id <MTReportFormatterDataSource> datasource;
    @property (nonatomic, weak)             id <MTCacheProtocol> cachedDelegate;

    @property (nonatomic, strong, readonly) MTReportFormatterPageDefinition *page;
    @property (nonatomic, weak, readonly)   MADocument *layout;

    @property (readonly) NSUInteger numberOfPages;
    @property (readonly) NSUInteger numberOfGroups;

    //  Use this to cache in location other than default.
    @property (nonatomic, copy, readwrite) NSString *overrideIdentifier;

    - (instancetype)initWithDocument: (MADocument *)layout
                             options: (MTReportFormatterOptions)options;
                             
    + (instancetype)newReportFormatterWithQuery: (MTQuery *)query layout: (MADocument *)layout
                                     options: (MTReportFormatterOptions)options;

    - (void)formatForSize:(CGSize)printableSize;
    - (void)formatForSize:(CGSize)printableSize contentChanged:(BOOL)contextChanged;
    - (void)reformatForSize:(CGSize)printableSize;

    - (void)loadFromCacheWithSize:(CGSize)printableSize;

    - (NSEnumerator <__kindof MADSectionPlist *> *)layoutEnumeratorForPage:(NSUInteger)pageIndex;
    - (MADSectionArray *)layoutForPage:(NSUInteger)page;

    - (CGFloat)heightForSection:(RptqDocumentSection *)documentSection;
    - (MADIndexArray *)rowidsForPage:(NSUInteger)pageIndex;
    - (MADObjectArray *)keysForCachedID:(NSNumber *)rowid;

    - (void)setLayoutSize:(CGSize)layoutSize;
    - (void)setMarginUsingPrintableRect:(CGRect)printableRect;

@end

#endif
