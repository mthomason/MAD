//
//  MADRefreshOperationInitalizeMainDataTable.h
//  MAD Designer
//
//  Created by Michael Thomason on 4/2/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADRefreshOperationInitalizeMainDataTable_h
#define Reports_MADRefreshOperationInitalizeMainDataTable_h

#import "MADOperation.h"

@class MADocument;

@interface MADRefreshOperationInitalizeMainDataTable : MADOperation

    - (instancetype)initWithDocument:(MADocument *)document;

@end

#endif
