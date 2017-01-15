//
//  MADRefreshOperationInitalize.h
//  MAD Designer
//
//  Created by Michael Thomason on 4/2/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADRefreshOperationInitalize_h
#define Reports_MADRefreshOperationInitalize_h

#import "MADOperation.h"

@class MADocument;

@protocol MADRefreshOperationInitalizeProtocol <NSObject>
    @property (readonly) MADocument *document;
@end

@interface MADOperationRefreshInitialize : MADOperation

    - (instancetype)initWithDocument:(MADocument *)document;

@end

#endif
