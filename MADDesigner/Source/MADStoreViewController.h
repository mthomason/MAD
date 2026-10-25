//
//  MADStoreViewController.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/18/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADStoreViewController_h
#define MAD_Designer_MADStoreViewController_h

#import <MADAPI/MADViewControllerStandardProtocol.h>
#import <UIKit/UICollectionViewController.h>
#import <UIKit/UICollectionViewFlowLayout.h>

@interface MADStoreViewController : UICollectionViewController <MADViewControllerStandardProtocol, UICollectionViewDelegateFlowLayout>

@property (nonatomic, weak) id <MADViewControllerStandardProtocol> delegate;

@end

#endif
