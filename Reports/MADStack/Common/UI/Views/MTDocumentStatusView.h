//
//  MTDocumentStatusView.h
//  Reports
//
//  Created by Michael Thomason on 1/2/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDocumentStatusView_h
#define Reports_MTDocumentStatusView_h

#import <UIKit/UIKit.h>

@interface MTDocumentStatusView : UIView

    - (void)setDocumentState:(UIDocumentState)documentState;
    - (void)setDocumentMessage:(NSString *)message;
    - (void)setActivityState:(BOOL)active;

@end

#endif
