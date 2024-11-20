//
//  MADDesignerElementPIckerViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/15/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADDesignerElementPIckerViewController_h
#define Reports_MADDesignerElementPIckerViewController_h

#import <UIKit/UICollectionViewController.h>

@protocol MADElementPickerProtocol;

@class MADocument;

@interface MADDesignerElementPickerViewController : UICollectionViewController

    @property (nonatomic, weak) id <MADElementPickerProtocol> objectSelectorDelegate;
    @property (nonatomic, weak) MADocument *document;

@end

#endif
