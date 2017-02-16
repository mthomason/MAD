//
//  MADDesignerElementPIckerViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/15/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADDesignerElementPIckerViewController_h
#define Reports_MADDesignerElementPIckerViewController_h

#import "MADCollectionViewController.h"

@protocol MADElementPickerProtocol;

@class MADocument, NSManagedObjectID, RptqQueryField;

@interface MADDesignerElementPickerViewController : MADCollectionViewController

    @property (nonatomic, weak) id <MADElementPickerProtocol> objectSelectorDelegate;
    @property (nonatomic, weak) MADocument *document;

@end

#endif
