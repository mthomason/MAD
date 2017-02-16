//
//  MADStoreViewController.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/18/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADStoreViewController_h
#define MAD_Designer_MADStoreViewController_h

#import <UIKit/UICollectionViewController.h>
#import <UIKit/UICollectionViewFlowLayout.h>
#import "MADViewControllerStandardProtocol.h"

@interface MADStoreViewController : UICollectionViewController
    <MADViewControllerStandardProtocol, UICollectionViewDelegateFlowLayout>

    @property (nonatomic, weak) id <MADViewControllerStandardProtocol> delegate;

@end

#endif
