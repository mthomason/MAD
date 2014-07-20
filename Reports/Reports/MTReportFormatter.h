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

typedef NS_OPTIONS(NSInteger, MTReportFormatterOptions) {
    MTReportFormatterOptionsNone   = 1 << 0,
};

extern NSString * const MTNullIdentifier;

@class RptqDocumentSection, RptqDocument, MTArrayCached;

@protocol MTReportFormatterDataSource <NSObject>

- (BOOL)cacheExist;
- (NSEnumerator *)enumeratorForReportData;
- (NSDictionary *)dataForCacheId:(NSNumber *)cachedID;

@end

@interface MTReportFormatter : MTTableFormatter

@property (nonatomic, weak) id <MADDataProtocol> dataDelegate;

- (void)initalizeStateMachine;

- (id)initWithQuery:(MTQuery *)query andLayout:(RptqDocument *)layout;
+ (id)reportFormatterWithQuery:(MTQuery *)query andLayout:(RptqDocument *)layout;

- (void)formatForSize:(CGSize)printableSize;
- (void)formatForSize:(CGSize)printableSize options:(MTReportFormatterOptions)options;
- (void)formatForSize:(CGSize)printableSize options:(MTReportFormatterOptions)options contentChanged:(BOOL)contextChanged;
- (void)reformatForSize:(CGSize)printableSize options:(MTReportFormatterOptions)options;

- (NSUInteger)numberOfPages;
- (NSEnumerator *)layoutEnumeratorForPage:(NSUInteger)pageIndex;
- (NSArray *)layoutForPage:(NSUInteger)page;

- (CGFloat)heightForSection:(RptqDocumentSection *)documentSection;
+ (NSValue *)KeyReportSectionType;
- (NSIndexSet *)rowidsForPage:(NSInteger)pageIndex;
- (NSArray *)keysForCachedID:(NSNumber *)rowid;
- (NSUInteger)numberOfGroups;


@property (nonatomic, weak) id <MTReportFormatterDataSource> datasource;
@property (nonatomic, weak) id <MTCacheProtocol> cachedDelegate;

@property (nonatomic, strong, readwrite) NSArray *sortedQueryGroups;
@property (nonatomic, strong, readonly) RptqDocument *layout;

@property (nonatomic, strong, readonly) MTArrayCached *reportIndexes;
@property (nonatomic, strong, readonly) MTArrayCached *reportLayout;

@property (nonatomic, strong) NSString *overrideIdentifier; //Use this to cache in location other than default.

@end

#endif
