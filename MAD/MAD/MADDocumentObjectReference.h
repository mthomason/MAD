//
//  MADDocumentObjectReference.h
//  MAD
//
//  Created by Michael on 1/16/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADDocumentObjectReference_h
#define MAD_MADDocumentObjectReference_h

#import <Foundation/NSObject.h>

@protocol MADPrintPageRendererDataSourceProtocol;

@class MTDatabase;
@class MTDataTable;
@class RptqDocumentElement;
@class MTReportFormatter;

@class NSManagedObjectID;
@class MADElementStylizedText;
@class NSMutableDictionary<KeyType, ObjectType>;

@interface MADDocumentObjectDataReference : NSObject
    <NSCopying>

    - (instancetype)initWithDataSource:(NSObject <MADPrintPageRendererDataSourceProtocol> *)datasource;

    @property (readonly, nonatomic, weak) NSObject <MADPrintPageRendererDataSourceProtocol> *datasource;
    @property (readonly, nonatomic, strong) NSMutableDictionary <NSManagedObjectID *, MADElementStylizedText *> *fontDescriptors;
    @property (readwrite, nonatomic, weak) __kindof RptqDocumentElement *item;

    @property (readwrite, nonatomic, assign) NSUInteger pageIndex;
    @property (readwrite, nonatomic, assign) NSUInteger detailRowId;

@end

#endif
