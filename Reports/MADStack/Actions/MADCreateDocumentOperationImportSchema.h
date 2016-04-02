//
//  MADCreateDocumentOperationAddConnection.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADCreateDocumentOperationImportSchema_h
#define MAD_Designer_MADCreateDocumentOperationImportSchema_h

#import "MADOperation.h"

@class MTDatabaseConnection;

@protocol MADCreateDocumentOperationImportSchemaProtocol <NSObject>
    - (void)updateImportProgressWithMessage:(NSString *)message progress:(float)progress;
@end

@interface MADCreateDocumentOperationImportSchema : MADOperation

    - (instancetype)initWithDatabaseConnection:(MTDatabaseConnection *)databaseConnection NS_DESIGNATED_INITIALIZER;
    @property (nonatomic, weak) id <MADCreateDocumentOperationImportSchemaProtocol> parentOperation;
    
@end

#endif
