//
//  MADStoreViewController.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/18/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADStoreViewController_h
#define MAD_Designer_MADStoreViewController_h

#import "MADViewController.h"
#import "MUIViewControllerDelegate.h"

@interface MADStoreViewController : MADCollectionViewController
    <MTViewControllerProtocol, UICollectionViewDelegateFlowLayout>

    @property (nonatomic, weak) id <MTViewControllerProtocol> delegate;

@end

#endif
