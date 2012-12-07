//
//  QueryBuilderDataModal.h
//  TheReportViewer
//
//  Created by Michael Thomason on 3/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UIManagedDocumentReport;

@interface QueryBuilderDataModal : NSObject

- (id)initWithManagedDocumentQuery:(UIManagedDocumentReport *)managedDocument;

- (NSMutableDictionary *)datamodel;
- (NSMutableDictionary *)datamodelForNumberOfTables:(NSInteger)numberOfTables;

@end