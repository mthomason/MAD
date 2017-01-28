//
//  MADManagedObjectCollectionViewCell.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDesigner_MADManagedObjectViewCell_h
#define MADDesigner_MADManagedObjectViewCell_h

#import <UIKit/UICollectionViewCell.h>
#import "MADManagedObjectViewProtocol.h"

@class NSManagedObjectID;

@interface MADManagedObjectCollectionViewCell : UICollectionViewCell
    <MADManagedObjectViewProtocol>

@end

#endif /* MADManagedObjectViewCell_h */
