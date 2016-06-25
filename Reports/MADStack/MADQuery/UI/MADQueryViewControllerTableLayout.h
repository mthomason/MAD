//
//  MADQueryViewControllerTableLayout.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/11/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDesigner_MADQueryViewControllerTableLayout_h
#define MADDesigner_MADQueryViewControllerTableLayout_h

#import <Foundation/NSObject.h>
#import <UIKit/UITableView.h>

@interface MADQueryViewControllerTableLayout : NSObject

    - (instancetype)initWithNumberOfTables:(NSInteger)numberOfTables
                          reportingEnabled:(BOOL)reportingEnabled;

    - (NSArray *)sectionTypes;

@end

#endif
