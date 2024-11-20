//
//  NSError+Constructors.h
//  MAD
//
//  Created by Michael Thomason on 4/1/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_NSError_Constructors_h
#define Reports_NSError_Constructors_h

#import <Foundation/NSError.h>

@class UIViewController;

@interface NSError (Constructors)

+ (void)presentError:(NSError *)error
    onViewController:(UIViewController *)viewController
          completion:(void (^)(BOOL success))completion;


@end

#endif
