//
//  MADReportFormatter.h
//  MAD
//
//  Created by Michael Thomason on 3/20/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADReportFormatter_h
#define MAD_MADReportFormatter_h

#import <MAD/MADTableFormatter.h>
#import <MAD/MADSectionRepresentation.h>

#import <MADFoundation/MADDataType.h>

#import <CoreGraphics/CGGeometry.h>

// The document this formatter lays out is whatever conforms to the render protocol --
// MADocument on Apple, MADHeadlessDocument anywhere -- so the render half is one
// implementation on both platforms (MAD_LINUX.md §9 Phase E).
#import <MAD/MADDocumentRenderProtocol.h>

typedef NS_OPTIONS(NSUInteger, MADReportFormatterOptions) {
	MADReportFormatterOptionsNone    = 0,
	MADReportFormatterOptionsMargin  = 1 << 0,
};

@protocol MADReportFormatterDataSource, MADDataProtocol, MADCacheProtocol, MADDocumentRenderProtocol;

// One declaration, and matching the class's own: Apple tolerates the same class
// forward-declared both bare and parameterized in one @class, and a forward
// declaration that disagrees with MADArrayCaching's variance about covariance,
// while GNUstep's clang calls the second an error (the formatter is in the Linux
// build now).
@class RptqDocumentSection, RptqDocument, MADPageOptions;
@class MADArrayCaching<ObjectType>;

@interface MADReportFormatter : MADTableFormatter

- (instancetype)initWithDocument: (id <MADDocumentRenderProtocol>)layout
						 options: (MADReportFormatterOptions)options;

+ (instancetype)newReportFormatterWithLayout: (id <MADDocumentRenderProtocol>)layout
									 options: (MADReportFormatterOptions)options;

@property (nonatomic, weak) id <MADDataProtocol> dataDelegate;

//  `reportLayout` contains and object for each page.  Each object in `reportLayout` is an array
//      which represents a page.  The array contains dictionaries for each object on that page.
@property (readonly, nonatomic, strong) MADArrayCaching <NSArray <MADSectionRepresentation *> *> *reportLayout;

@property (readwrite, nonatomic, weak) id <MADReportFormatterDataSource> datasource;
@property (readwrite, nonatomic, weak) id <MADCacheProtocol> cachedDelegate;

@property (readonly, nonatomic, strong) MADPageOptions *page;
@property (readonly, nonatomic, weak) id <MADDocumentRenderProtocol> layout;

@property (readonly, nonatomic) NSUInteger numberOfPages;
@property (readonly, nonatomic) NSUInteger numberOfGroups;

//  Use this to cache in location other than default.
@property (nonatomic, copy, readwrite) NSString *overrideIdentifier;

- (void)format:(CGSize)printableSize;
- (void)format:(CGSize)printableSize contentChanged:(BOOL)contextChanged;

- (void)loadFromCache:(CGSize)printableSize;

- (NSEnumerator <__kindof MADSectionRepresentation *> *)layoutEnumerator:(NSUInteger)pageIndex;

- (CGFloat)heightSection:(NSNumber *)identifier;

- (NSArray <NSNumber *> *)rowIDsForPage:(NSUInteger)pageIndex;

- (void)setLayoutSize:(CGSize)layoutSize;
- (void)setMarginUsingPrintableRect:(CGRect)printableRect;

- (NSArray *)newObjectArrayKeyValuesForResultRow:(id)resultRow;
- (void)layoutAddGroupFooterAtLevel:(NSUInteger)groupLevel withRowId:(NSUInteger)rowId;

//  One group-key comparison for a level whose declared type is known.  NULL is
//  first-class: NSNull implements no comparison, so the typed path never sees
//  it.  The typed classes (NSNumber, NSString, NSData) are compared the way the
//  cache's ORDER BY orders them, so equality and row adjacency agree.  Values
//  outside the level's canonical class are a contract violation: pairs of the
//  reader's three classes (a pre-contract cache) are logged once and compared
//  by a safe class-checked fallback; a class the reader can never produce
//  asserts in debug and answers Same in release.  See BUGS.md,
//  "MADReportFormatter compares untyped values through id".
+ (NSComparisonResult)compareValue:(id)value withValue:(id)value2 forDataType:(MADDataType)dataType;

@end

#endif
