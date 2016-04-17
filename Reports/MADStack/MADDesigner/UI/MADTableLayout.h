//
//  MADTableLayout.h
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADTableLayout_h
#define Reports_MADTableLayout_h

#import <UIKit/UICollectionViewLayout.h>

typedef void (^block_enumerateObjectsUsingBlock)(id obj, NSUInteger idx, BOOL *stop);

@protocol MADTableLayoutDelegate <NSObject>

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout widthRequiredColumn:(NSInteger)section;

@end

@interface MADTableLayout : UICollectionViewLayout

- (instancetype)initWithColumnCount:(NSUInteger)columnCount andRowCount:(NSUInteger)rowCount;
- (void)setColumnCount:(NSUInteger)columnCount andRowCount:(NSUInteger)rowCount;
- (NSUInteger)columnForIndexPath:(NSIndexPath *)indexPath;
- (NSUInteger)rowForIndexPath:(NSIndexPath *)indexPath;

@property (nonatomic, weak) id delegate;

@end

#endif
