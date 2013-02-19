//
//  QueryBuilderDataModal.h
//  Reports
//
//  Created by Michael Thomason on 3/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MTManagedDocumentReport;

@interface QueryBuilderDataModal : NSObject

- (id)initWithManagedDocumentQuery:(MTManagedDocumentReport *)managedDocument;

- (NSMutableDictionary *)datamodel;
- (NSMutableDictionary *)datamodelForNumberOfTables:(NSInteger)numberOfTables;

@end