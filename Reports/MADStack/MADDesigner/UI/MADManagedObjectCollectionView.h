//
//  MADManagedObjectCollectionView.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADManagedObjectCollectionView_h
#define MADManagedObjectCollectionView_h

#import <UIKit/UICollectionView.h>
#import "MADManagedObjectViewProtocol.h"

@interface MADManagedObjectCollectionView : UICollectionView
    <MADManagedObjectViewProtocol>

@end

#endif /* MADManagedObjectCollectionView_h */
