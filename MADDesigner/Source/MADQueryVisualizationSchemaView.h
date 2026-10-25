//
//  MADQueryVisualizationSchemaView.h
//  MAD Designer
//
//  Created by Michael on 1/26/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADQueryVisualizationSchemaView_h
#define Reports_MADQueryVisualizationSchemaView_h

#import "MADManagedObjectViewProtocol.h"
#import <UIKit/UIView.h>

@interface MADQueryVisualizationSchemaView : UIView <MADManagedObjectViewProtocol>

@property (nonatomic, readwrite) CGPoint center;
@property (nonatomic, readwrite) CGAffineTransform transform;
@property (nonatomic, readonly) CGRect bounds;
@property (nonatomic, assign) int64_t identifier;

@end

#endif
