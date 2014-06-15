//
//  MTArrayDataSourceCollectionView.m
//  MAD
//
//  Created by Michael Thomason on 6/14/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTArrayDataSourceCollectionView.h"
#import "MTArrayDataSourcePrivate.h"

@implementation MTArrayDataSourceCollectionView

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:self.cellIdentifier
                                                                           forIndexPath:indexPath];
    id item = [self itemAtIndexPath:indexPath];
    self.configureCellBlock(cell, item);
    return cell;
}

@end
