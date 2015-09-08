//
//  UINavigationControllerModelControllers.h
//  Reports
//
//  Created by Michael Thomason on 2/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTNavigationController_h
#define Reports_MTNavigationController_h

#import <UIKit/UIKit.h>
#import "MADocumentProtocol.h"

@interface MADNavigationController : UINavigationController
    <MADocumentProtocol, UINavigationControllerDelegate, UIViewControllerTransitioningDelegate>

- (IBAction)done:(id)sender;

@end

#endif
