//
//  MADManagedObjectCollectionViewCell.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADDesigner_MADManagedObjectCollectionViewCell_h
#define MADDesigner_MADManagedObjectCollectionViewCell_h

#import <UIKit/UICollectionViewCell.h>
#import "MADManagedObjectViewProtocol.h"

@interface MADManagedObjectCollectionViewCell : UICollectionViewCell
	<MADManagedObjectViewProtocol>

@end

#endif /* MADManagedObjectViewCell_h */
