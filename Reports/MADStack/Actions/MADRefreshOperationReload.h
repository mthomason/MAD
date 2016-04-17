//
//  MADRefreshOperationReload.h
//  MAD Designer
//
//  Created by Michael Thomason on 4/3/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADOperation.h"

@class MADocument;
@class MADPageViewAttributes;

@interface MADRefreshOperationReload : MADOperation

    - (instancetype)initWithDocument:(MADocument *)document;

    @property (nonatomic, readonly, copy) MADPageViewAttributes *pageAttributes;
    @property (nonatomic, readonly, assign) bool success;

@end
