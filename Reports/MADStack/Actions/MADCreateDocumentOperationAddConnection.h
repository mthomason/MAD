//
//  MADCreateDocumentOperationAddConnection.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADCreateDocumentOperationAddConnection_h
#define MAD_Designer_MADCreateDocumentOperationAddConnection_h

#import "MADOperation.h"

@class MADDatabaseConnection;

@interface MADCreateDocumentOperationAddConnection : MADOperation

- (instancetype)initWithDatabaseConnection:(MADDatabaseConnection *)databaseConnection NS_DESIGNATED_INITIALIZER;

@end

#endif
