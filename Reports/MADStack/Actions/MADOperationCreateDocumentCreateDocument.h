//
//  MADCreateDocumentOperationCreateDocument.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADCreateDocumentOperationCreateDocument_h
#define MAD_Designer_MADCreateDocumentOperationCreateDocument_h

#import "MADOperation.h"

@class MADocument, MADDatabaseConnection;

@protocol MADOperationCreateDocumentProtocol <NSObject>
    @property (readonly) MADocument *document;
@end

@interface MADOperationCreateDocumentCreateDocument : MADOperation
    <MADOperationCreateDocumentProtocol>

- (instancetype)initWithDatabaseConnection:(MADDatabaseConnection *)databaseConnection;
    
@end

#endif
