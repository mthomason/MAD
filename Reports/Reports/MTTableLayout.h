//
//  MTTableLayout.h
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTTableLayout_h
#define Reports_MTTableLayout_h

#import <UIKit/UIKit.h>

typedef void (^block_enumerateObjectsUsingBlock)(id obj, NSUInteger idx, BOOL *stop);

@interface MTTableLayout : UICollectionViewLayout

- (id)initWithColumnCount:(NSUInteger)columnCount andRowCount:(NSUInteger)rowCount;
- (void)setColumnCount:(NSUInteger)columnCount andRowCount:(NSUInteger)rowCount;
- (NSUInteger)columnForIndexPath:(NSIndexPath *)indexPath;
- (NSUInteger)rowForIndexPath:(NSIndexPath *)indexPath;

@end

#endif
