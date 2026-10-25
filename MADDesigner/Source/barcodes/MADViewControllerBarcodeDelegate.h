//
//  MADViewControllerBarcodeDelegate.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADViewControllerBarcodeDelegate_h
#define MADViewControllerBarcodeDelegate_h

@class MADBarcode, RptqQueryField;

@protocol MADViewControllerBarcodeDelegate

    - (void)didUpdateBarcodeWithObjectID:(int64_t)barcodeObjectID
                           barcodeObject:(MADBarcode *)barcode
                            withFieldOne:(int64_t /* RptqQueryField */)fieldOne
                             andFieldTwo:(int64_t /* RptqQueryField */)fieldTwo;

@end

#endif /* MADViewControllerBarcodeDelegate_h */
