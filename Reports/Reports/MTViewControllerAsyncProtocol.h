//
//  MTViewControllerAsyncProtocol.h
//  MAD
//
//  Created by Michael Thomason on 8/15/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTViewControllerAsyncProtocol_h
#define Reports_MTViewControllerAsyncProtocol_h

#import <Foundation/Foundation.h>

@protocol MTViewControllerAsyncProtocol <NSObject>

- (void)displayContentController:(UIViewController *)contentController;

@end

#endif
