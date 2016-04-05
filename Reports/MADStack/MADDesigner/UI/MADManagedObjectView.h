//
//  UIView+NSObjectIdTag.h
//  Reports
//
//  Created by Michael Thomason on 12/24/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_NSManagedObjectID_NSObjectIdTag_h
#define Reports_NSManagedObjectID_NSObjectIdTag_h

#import <UIKit/UIKit.h>

@class NSManagedObjectID;

@protocol MADManagedObjectViewProtocol <NSObject>
@required;
    @property (nonatomic, copy) NSManagedObjectID *objectIdTag;
@end

@interface MADManagedObjectView : UIView
        <MADManagedObjectViewProtocol>
    @property (nonatomic, copy) NSManagedObjectID *objectIdTag;

@end

@interface MADManagedObjectCollectionView : UICollectionView
        <MADManagedObjectViewProtocol>
    @property (nonatomic, copy) NSManagedObjectID *objectIdTag;

@end

@interface MADManagedObjectCollectionViewCell : UICollectionViewCell
        <MADManagedObjectViewProtocol>
    @property (nonatomic, copy) NSManagedObjectID *objectIdTag;

@end


#endif
