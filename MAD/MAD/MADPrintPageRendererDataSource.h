//
//  MADPrintPageRendererDataSource.h
//  MAD
//
//  Created by Michael on 1/16/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADPrintPageRendererDataSourceProtocol_h
#define MAD_MADPrintPageRendererDataSourceProtocol_h

#import <Foundation/NSObject.h>

@class MADDatabase, MADDataTableFast, MADReportFormatter, RptqDocumentElement, MADDocumentObjectDataReference;

@protocol MADPrintPageRendererDataSourceProtocol <NSObject>

    @property (readonly, nonatomic, strong) MADDatabase *database;
    @property (readonly, nonatomic, strong) MADDataTableFast *dataTable;
    @property (readwrite, nonatomic, strong) MADReportFormatter *reportFormatter;

    - (NSString *)getLabelDataDynamic:(MADDocumentObjectDataReference *)dataRef;
    - (NSString *)getLabelDataStatic:(MADDocumentObjectDataReference *)dataRef;
    - (NSArray *)groupLevelKeys:(NSUInteger)rowID;

    - (void)updatePrintingReportFormatter;

@end

#endif
