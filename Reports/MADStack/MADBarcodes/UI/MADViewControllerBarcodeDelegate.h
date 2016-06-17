//
//  MADViewControllerBarcodeDelegate.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADViewControllerBarcodeDelegate_h
#define MADViewControllerBarcodeDelegate_h

@class NSManagedObjectID;
@class MTBarcode;
@class RptqQueryField;

@protocol MTViewControllerBarcodeDelegate

    - (void)didUpdateBarcodeWithObjectID:(NSManagedObjectID *)barcodeObjectID
                           barcodeObject:(MTBarcode *)barcode
                            withFieldOne:(RptqQueryField *)fieldOne
                             andFieldTwo:(RptqQueryField *)fieldTwo;

@end

#endif /* MADViewControllerBarcodeDelegate_h */
