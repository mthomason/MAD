//
//  MADQueryViewControllerTableLayout.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/11/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MADQueryViewControllerTableLayout : NSObject

- (instancetype)initWithNumberOfTables:(NSInteger)numberOfTables
                      reportingEnabled:(BOOL)reportingEnabled;

- (NSArray *)sectionTypes;

@end
