//
//  UIManagedDocument+Extras.h
//  MAD
//
//  Created by Michael Thomason on 6/8/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MAD_UIManagedDocument__Extras_h
#define Reports_MAD_UIManagedDocument__Extras_h

#import <UIKit/UIManagedDocument.h>

@interface UIManagedDocument (Extras)

    - (void)resetPersistentStore;
    - (void)deleteFromDiskCompletion:(void (^)(BOOL success))completion;

@end

#endif
