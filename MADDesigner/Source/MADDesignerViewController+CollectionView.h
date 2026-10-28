//
//  MADDesignerViewController+CollectionView.h
//  Reports
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADDesignerViewController_CollectionView_h
#define MAD_MADDesignerViewController_CollectionView_h

#import "MADDesignerViewController_Private.h"

@interface MADDesignerViewController (CollectionView) <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, MADDesignerSectionLayoutLiquidDelegate, MADCellElementDelegate>

- (void)editDocumentObjectAggregateWithID:(NSNumber *)identifier objectID:(int64_t)objectID;
- (void)editDocumentObjectBarcodeWithID:(NSNumber *)objectID;
- (void)editDocumentObjectBarcode:(RptqDocumentElement *)object;
- (void)editDocumentObjectImage:(RptqDocumentElement *)object;
- (void)editDocumentObjectLabelDynamic:(RptqDocumentElement *)object;
- (void)editDocumentObjectLabelStatic:(RptqDocumentElement *)object;
- (void)deleteDocumentObjectRepresentedByCell:(MADCellElement *)cell;

@end

#endif
