//
//  MADRefreshOperation.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADRefreshOperation_h
#define Reports_MADRefreshOperation_h

#import "MADOperation.h"

@class MADocument;

@interface MADOperationRefresh : MADOperation

    - (instancetype)initWithDocument:(MADocument *)document;

@end

#endif
