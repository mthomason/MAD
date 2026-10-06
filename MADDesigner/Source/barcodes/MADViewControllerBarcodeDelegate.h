//
//  MADViewControllerBarcodeDelegate.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADViewControllerBarcodeDelegate_h
#define MADViewControllerBarcodeDelegate_h

@class MTBarcode, RptqQueryField;

@protocol MADViewControllerBarcodeDelegate

    - (void)didUpdateBarcodeWithObjectID:(int64_t)barcodeObjectID
                           barcodeObject:(MTBarcode *)barcode
                            withFieldOne:(int64_t /* RptqQueryField */)fieldOne
                             andFieldTwo:(int64_t /* RptqQueryField */)fieldTwo;

@end

#endif /* MADViewControllerBarcodeDelegate_h */
