//
//  NSError+Constructors.h
//  MAD
//
//  Created by Michael Thomason on 4/1/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_NSError_Constructors_h
#define Reports_NSError_Constructors_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSError (Constructors)

+ (void)presentError:(NSError *)error
    onViewController:(UIViewController *)viewController
          completion:(void (^)(BOOL success))completion;


@end

#endif
