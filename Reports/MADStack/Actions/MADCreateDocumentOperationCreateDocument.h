//
//  MADCreateDocumentOperationCreateDocument.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADCreateDocumentOperationCreateDocument_h
#define MAD_Designer_MADCreateDocumentOperationCreateDocument_h

#import "MADOperation.h"

@class MADocument;

@protocol MADCreateDocumentOperationCreateDocumentProtocol <NSObject>
    @property (readonly) MADocument *document;
@end

@interface MADCreateDocumentOperationCreateDocument : MADOperation
    <MADCreateDocumentOperationCreateDocumentProtocol>
    
@end

#endif
