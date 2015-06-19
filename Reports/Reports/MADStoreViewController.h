//
//  MADStoreViewController.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/18/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MUIViewControllerDelegate.h"

@interface MADStoreViewController : UICollectionViewController
    <MTViewControllerProtocol>

@property (nonatomic, assign) id <MTViewControllerProtocol> delegate;

@end
