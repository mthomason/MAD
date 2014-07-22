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
#import "MTTableFormatter.h"
#import "MTCacheProtocol.h"
#import "MADDataProtocol.h"

typedef NS_OPTIONS(NSUInteger, MTReportFormatterOptions) {
    MTReportFormatterOptionsNone    = 0,
    MTReportFormatterOptionsMargin  = 1 << 0,
};

extern NSString * const MTNullIdentifier;

@class RptqDocumentSection, RptqDocument, MTArrayCached, MTReportFormatterPageDefinition;

@protocol MTReportFormatterDataSource <NSObject>

- (BOOL)cacheExist;
- (NSEnumerator *)enumeratorForReportData;
- (NSDictionary *)dataForCacheId:(NSNumber *)cachedID;

@end

@interface MTReportFormatter : MTTableFormatter

@property (nonatomic, weak) id <MADDataProtocol> dataDelegate;

- (void)initalizeStateMachine;

- (id)initWithQuery:(MTQuery *)query layout:(RptqDocument *)layout options:(MTReportFormatterOptions)options ;
+ (id)reportFormatterWithQuery:(MTQuery *)query layout:(RptqDocument *)layout options:(MTReportFormatterOptions)options;
+ (NSValue *)KeyReportSectionType;

- (void)formatForSize:(CGSize)printableSize;
- (void)formatForSize:(CGSize)printableSize contentChanged:(BOOL)contextChanged;
- (void)reformatForSize:(CGSize)printableSize;

- (NSEnumerator *)layoutEnumeratorForPage:(NSUInteger)pageIndex;
- (NSArray *)layoutForPage:(NSUInteger)page;

- (CGFloat)heightForSection:(RptqDocumentSection *)documentSection;
- (NSArray *)rowidsForPage:(NSInteger)pageIndex;
- (NSArray *)keysForCachedID:(NSNumber *)rowid;

- (NSUInteger)numberOfPages;
- (NSUInteger)numberOfGroups;

- (void)setLayoutSize:(CGSize)layoutSize;
- (void)setMarginUsingPrintableRect:(CGRect)printableRect;

@property (nonatomic, weak) id <MTReportFormatterDataSource> datasource;
@property (nonatomic, weak) id <MTCacheProtocol> cachedDelegate;

@property (nonatomic, strong, readonly) MTReportFormatterPageDefinition *page;
@property (nonatomic, strong, readwrite) NSArray *sortedQueryGroups;
@property (nonatomic, strong, readonly) RptqDocument *layout;

@property (nonatomic, strong, readonly) MTArrayCached *reportIndexes;
@property (nonatomic, strong, readonly) MTArrayCached *reportLayout;

@property (nonatomic, strong) NSString *overrideIdentifier; //Use this to cache in location other than default.

@end

#endif
