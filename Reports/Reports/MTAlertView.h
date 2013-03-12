//
//  MTAlertView.h
//  Reports
//
//  Created by Michael Thomason on 3/11/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTAlertView_h
#define Reports_MTAlertView_h

#import <UIKit/UIKit.h>

typedef void (^MTAlertViewDismissBlock)(NSInteger buttonIndex);
typedef void (^MTAlertViewCancelBlock)();

@interface MTAlertView : UIAlertView <UIAlertViewDelegate>

- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
  cancelButtonTitle:(NSString *)cancelButtonTitle
   otherButtonTitle:(NSArray *)otherButtons
          onDismiss:(MTAlertViewDismissBlock)dismissed
           onCancel:(MTAlertViewCancelBlock)cancelled;

@end

#endif
