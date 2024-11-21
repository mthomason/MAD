//
//  MADDocumentObjectCollectionViewCell.h
//  MAD Designer
//
//  Created by Michael Thomason on 10/24/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADDocumentObjectCollectionViewCell_h
#define MAD_MADDocumentObjectCollectionViewCell_h

#import <UIKit/UICollectionViewCell.h>
#import <MAD/MADDocumentObjectType.h>

@class UILabel;

@interface MADDocumentObjectCollectionViewCell : UICollectionViewCell

	@property (nonatomic, assign) MADPrintPageElementType type;
	@property (nonatomic, weak) IBOutlet UILabel *title;
	@property (nonatomic, weak) IBOutlet UILabel *detail;

@end

#endif
