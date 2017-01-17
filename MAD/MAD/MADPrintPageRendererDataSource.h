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

@class MTDatabase;
@class MTDataTableFast;
@class MTReportFormatter;

@protocol MADPrintPageRendererDataSourceProtocol <NSObject>

    @property (readonly, nonatomic, strong) MTDatabase *database;
    @property (readonly, nonatomic, strong) MTDataTableFast *dataTable;
    @property (readwrite, nonatomic, strong) MTReportFormatter *reportFormatter;

    - (NSArray *)groupLevelKeys:(NSUInteger)rowID;

    - (void)updatePrintingReportFormatter;

@end

#endif
