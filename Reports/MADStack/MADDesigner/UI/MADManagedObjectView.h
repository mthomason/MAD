//
//  UIView+NSObjectIdTag.h
//  Reports
//
//  Created by Michael Thomason on 12/24/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_NSManagedObjectID_NSObjectIdTag_h
#define Reports_NSManagedObjectID_NSObjectIdTag_h

#import <UIKit/UIView.h>
#import "MADManagedObjectViewProtocol.h"


@interface MADManagedObjectView : UIView
        <MADManagedObjectViewProtocol>
        
    @property (nonatomic, copy) NSManagedObjectID *objectIdTag;

@end

#endif
