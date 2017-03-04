//
//  MADReportFormatter.h
//  MAD
//
//  Created by Michael Thomason on 3/20/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADReportFormatter_h
#define MAD_MADReportFormatter_h

#import <MAD/MADTableFormatter.h>

#import <CoreGraphics/CGGeometry.h>
#import <MAD/MADSectionRepresentation.h>

typedef NS_OPTIONS(NSUInteger, MADReportFormatterOptions) {
    MADReportFormatterOptionsNone    = 0,
    MADReportFormatterOptionsMargin  = 1 << 0,
};

@protocol MADReportFormatterDataSource, MADDataProtocol, MADCacheProtocol;

@class MADocument, RptqDocumentSection, RptqDocument, MADArrayCaching, MADPageOptions,
       NSManagedObjectID, MADArrayCaching <ObjectType>;

@interface MADReportFormatter : MADTableFormatter

    - (instancetype)initWithDocument: (MADocument *)layout
                             options: (MADReportFormatterOptions)options;
                             
    + (instancetype)newReportFormatterWithLayout: (MADocument *)layout
                                         options: (MADReportFormatterOptions)options;


    @property (nonatomic, weak) id <MADDataProtocol> dataDelegate;


    //  `reportLayout` contains and object for each page.  Each object in `reportLayout` is an array
    //      which represents a page.  The array contains dictionaries for each object on that page.
    @property (readonly, nonatomic, strong) MADArrayCaching <NSArray <MADSectionRepresentation *> *> *reportLayout;

    @property (readwrite, nonatomic, weak) id <MADReportFormatterDataSource> datasource;
    @property (readwrite, nonatomic, weak) id <MADCacheProtocol> cachedDelegate;

    @property (readonly, nonatomic, strong) MADPageOptions *page;
    @property (readonly, nonatomic, weak) MADocument *layout;

    @property (readonly, nonatomic) NSUInteger numberOfPages;
    @property (readonly, nonatomic) NSUInteger numberOfGroups;

    //  Use this to cache in location other than default.
    @property (nonatomic, copy, readwrite) NSString *overrideIdentifier;

    - (void)formatForSize:(CGSize)printableSize;
    - (void)formatForSize:(CGSize)printableSize contentChanged:(BOOL)contextChanged;

    - (void)loadFromCacheWithSize:(CGSize)printableSize;

    - (NSEnumerator <__kindof MADSectionRepresentation *> *)layoutEnumeratorForPage:(NSUInteger)pageIndex;
    - (NSArray <MADSectionRepresentation *> *)layoutForPage:(NSUInteger)page;

    - (CGFloat)heightForSectionWithObjectIdentifier:(NSNumber *)identifier;

    - (NSArray <NSNumber *> *)rowidsForPage:(NSUInteger)pageIndex;

    - (void)setLayoutSize:(CGSize)layoutSize;
    - (void)setMarginUsingPrintableRect:(CGRect)printableRect;

    - (NSArray *)newObjectArrayKeyValuesForResultRow:(id)resultRow;

@end

#endif
