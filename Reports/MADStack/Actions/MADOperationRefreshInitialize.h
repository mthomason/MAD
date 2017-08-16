//
//  MADOperationRefreshInitialize.h
//  MAD Designer
//
//  Created by Michael Thomason on 4/2/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADRefreshOperationInitialize_h
#define Reports_MADRefreshOperationInitialize_h

#import <MADFoundation/MADOperation.h>

@class MADocument;

@protocol MADRefreshOperationInitializeProtocol <NSObject>
    @property (readonly) MADocument *document;
@end

@interface MADOperationRefreshInitialize : MADOperation

    - (instancetype)initWithDocument:(MADocument *)document;

@end

#endif
