//
//  MTReportFormatter.h
//  MAD
//
//  Created by Michael Thomason on 3/20/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MTReportFormatter_h
#define MAD_MTReportFormatter_h

#import <MAD/MTTableFormatter.h>

#import <CoreGraphics/CGGeometry.h>
#import <MAD/MADSectionRepresentation.h>

typedef NS_OPTIONS(NSUInteger, MTReportFormatterOptions) {
    MTReportFormatterOptionsNone    = 0,
    MTReportFormatterOptionsMargin  = 1 << 0,
};

@protocol MTReportFormatterDataSource;
@protocol MADDataProtocol;
@protocol MTCacheProtocol;

@class MADocument;
@class RptqDocumentSection;
@class RptqDocument;
@class MADArrayCaching;
@class MADPageOptions;
@class NSManagedObjectID;
@class MADArrayCaching <ObjectType>;

typedef NSArray         <id>                                            MADObjectArray;
typedef NSArray         <MADSectionRepresentation *>                    MADSectionArray;
typedef NSArray         <NSNumber *>                                    MADIndexArray;

typedef MADArrayCaching <MADIndexArray *>                               MADCachingIndexes;
typedef MADArrayCaching <MADSectionArray *>                             MADCachingLayout;

@interface MTReportFormatter : MTTableFormatter

    - (instancetype)initWithDocument: (MADocument *)layout
                             options: (MTReportFormatterOptions)options;
                             
    + (instancetype)newReportFormatterWithLayout: (MADocument *)layout
                                         options: (MTReportFormatterOptions)options;


    @property (nonatomic, weak) id <MADDataProtocol> dataDelegate;


    //  `reportLayout` contains and object for each page.  Each object in `reportLayout` is an array
    //      which represents a page.  The array contains dictionaries for each object on that page.
    @property (nonatomic, strong, readonly) MADCachingLayout *reportLayout;

    @property (nonatomic, weak)             id <MTReportFormatterDataSource> datasource;
    @property (nonatomic, weak)             id <MTCacheProtocol> cachedDelegate;

    @property (nonatomic, strong, readonly) MADPageOptions *page;
    @property (nonatomic, weak,   readonly) MADocument *layout;

    @property (readonly) NSUInteger numberOfPages;
    @property (readonly) NSUInteger numberOfGroups;

    //  Use this to cache in location other than default.
    @property (nonatomic, copy, readwrite) NSString *overrideIdentifier;

    - (void)formatForSize:(CGSize)printableSize;
    - (void)formatForSize:(CGSize)printableSize contentChanged:(BOOL)contextChanged;

    - (void)loadFromCacheWithSize:(CGSize)printableSize;

    - (NSEnumerator <__kindof MADSectionRepresentation *> *)layoutEnumeratorForPage:(NSUInteger)pageIndex;
    - (MADSectionArray *)layoutForPage:(NSUInteger)page;

    - (CGFloat)heightForSectionWithObjectID:(NSManagedObjectID *)objectID;

    - (MADIndexArray *)rowidsForPage:(NSUInteger)pageIndex;

    - (void)setLayoutSize:(CGSize)layoutSize;
    - (void)setMarginUsingPrintableRect:(CGRect)printableRect;

    - (MADObjectArray *)newObjectArrayKeyValuesForResultRow:(id)resultRow;

@end

#endif
