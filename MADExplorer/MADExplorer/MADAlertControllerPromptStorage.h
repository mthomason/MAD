//
//  MADAlertControllerPromptStorage.h
//  MADExplorer
//
//  Created by Michael on 2/14/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADAlertControllerPromptStorage_h
#define Reports_MADAlertControllerPromptStorage_h

#import <UIKit/UIAlertController.h>

@interface MADAlertControllerPromptStorage : UIAlertController
    + (instancetype)newAlertControllerPromptStorage:(void (^)(void))handlerLocal
                                              cloud:(void (^)(void))handlerCloud;
@end

#endif
