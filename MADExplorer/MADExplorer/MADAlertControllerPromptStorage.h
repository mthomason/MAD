//
//  MADAlertControllerPromptStorage.h
//  MADExplorer
//
//  Created by Michael on 2/14/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADAlertControllerPromptStorage_h
#define Reports_MADAlertControllerPromptStorage_h

#import <UIKit/UIAlertController.h>

@interface MADAlertControllerPromptStorage : UIAlertController
    + (instancetype)newAlertControllerPromptStorage:(void (^)())handlerLocal
                                              cloud:(void (^)())handlerCloud;
@end

#endif
