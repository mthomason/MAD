//
//  MTArrayDataSourcePrivate.h
//  MAD
//
//  Created by Michael Thomason on 6/14/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MTArrayDataSourcePrivate_h
#define MAD_MTArrayDataSourcePrivate_h

@interface MTArrayDataSource ()

    @property (nonatomic, strong) NSMutableArray *items;
    @property (nonatomic, copy) NSString *cellIdentifier;
    @property (nonatomic, copy) MTCellConfigureBlock configureCellBlock;

@end

#endif
