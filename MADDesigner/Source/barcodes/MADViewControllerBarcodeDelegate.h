//
//  MADViewControllerBarcodeDelegate.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADViewControllerBarcodeDelegate_h
#define MADViewControllerBarcodeDelegate_h

@class NSManagedObjectID, MTBarcode, RptqQueryField;

@protocol MADViewControllerBarcodeDelegate

    - (void)didUpdateBarcodeWithObjectID:(NSManagedObjectID *)barcodeObjectID
                           barcodeObject:(MTBarcode *)barcode
                            withFieldOne:(NSManagedObjectID /* RptqQueryField */ *)fieldOne
                             andFieldTwo:(NSManagedObjectID /* RptqQueryField */ *)fieldTwo;

@end

#endif /* MADViewControllerBarcodeDelegate_h */
