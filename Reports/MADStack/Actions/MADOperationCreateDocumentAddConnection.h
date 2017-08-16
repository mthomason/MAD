//
//  MADCreateDocumentOperationAddConnection.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADCreateDocumentOperationAddConnection_h
#define MAD_Designer_MADCreateDocumentOperationAddConnection_h

#import <MADFoundation/MADOperation.h>

@class MADDatabaseConnection;

@interface MADOperationCreateDocumentAddConnection : MADOperation

- (instancetype)initWithDatabaseConnection:(MADDatabaseConnection *)databaseConnection NS_DESIGNATED_INITIALIZER;

@end

#endif
