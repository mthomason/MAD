//
//  MADAlertController.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/23/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADAlertController_h
#define MAD_Designer_MADAlertController_h

#import <UIKit/UIAlertController.h>

@protocol MADAlertControllerAlertRemovedProtocol;

@interface MADAlertController : UIAlertController

    @property (nonatomic, weak) id <MADAlertControllerAlertRemovedProtocol> madAlertControllerAlertRemovedDelegate;

@end

#endif
