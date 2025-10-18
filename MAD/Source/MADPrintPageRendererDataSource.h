//
//  MADPrintPageRendererDataSource.h
//  MAD
//
//  Created by Michael on 1/16/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADPrintPageRendererDataSourceProtocol_h
#define MAD_MADPrintPageRendererDataSourceProtocol_h

#import <MADAPI/MADAliases.h>
#import <MAD/MADAggregateFunctionGroupByType.h>
#import <MAD/MADAggregateFunctionType.h>

#import <Foundation/NSObject.h>

@class MADDatabase, MADDataTableFast, MADReportFormatter, RptqDocumentElement, MADDocumentObjectDataReference;

@protocol MADPrintPageRendererDataSourceProtocol <NSObject>

@property (readonly, nonatomic, strong) MADDatabase *database;
@property (readonly, nonatomic, strong) MADDataTableFast *dataTable;
@property (readwrite, nonatomic, strong) MADReportFormatter *reportFormatter;

- (NSArray <MADResult *> *)groupLevelKeys:(int64_t)rowID;
- (NSArray <MADResult *> *)groupKeys:(int64_t)rowID groupNumber:(int64_t)groupNumber;
- (NSArray <NSString *> *)groupLevelKeyNames;

- (NSDictionary <NSString *, MADResult *> *)dataForRow:(NSUInteger)rowID
												 error:(NSError * __autoreleasing *)error;
- (NSDictionary *)dataForRowReportFirst;
- (NSDictionary *)dataForRowReportLast;
- (NSDictionary *)dataForRowPageFirst:(NSUInteger)pageIndex;
- (NSDictionary *)dataForRowPageLast:(NSUInteger)pageIndex;
- (NSDictionary *)dataForRow:(NSUInteger)rowID
					  column:(NSString *)columnKey
					   error:(NSError * __autoreleasing *)error;
- (NSArray <__kindof NSDictionary *> *)dataForGroups:(NSArray *)groupKeys
											 groupID:(int64_t)groupID;
- (__kindof NSObject <NSCopying> *)dataForRows:(NSArray *)rowIDs
										column:(NSString *)columnKey
										groups:(NSArray *)groupKeys
									  function:(MTAggregateFunctionType)function
									   groupBy:(MTAggregateGroupByType)groupBy;
- (NSUInteger)rowIDFirstOfReport;
- (NSUInteger)rowIDLastOfReport;
- (NSUInteger)rowIDFirstOfPage:(NSUInteger)page;
- (NSUInteger)rowIDLastOfPage:(NSUInteger)page;
- (NSArray <NSNumber *> *)rowIDsForPage:(NSUInteger)pageIndex;

- (void)updatePrintingReportFormatter;

@end

#endif
