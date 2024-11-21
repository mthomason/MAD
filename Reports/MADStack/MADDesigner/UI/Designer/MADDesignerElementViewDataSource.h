//
//  MADDesignerElementViewDataSource.h
//  MAD Designer
//
//  Created by Michael on 9/2/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADDesignerElementViewDataSource_h
#define MADDesignerElementViewDataSource_h

#import <MAD/MADDocumentObjectType.h>

@class MADDesignerElementView;

@protocol MADDesignerElementViewDataSource <NSObject>
  @required
	- (MADPrintPageElementType)documentObjectTypeForElementView:(MADDesignerElementView *)elementView;
	- (id)documentObjectForElementView:(MADDesignerElementView *)elementView;
	- (CGSize)documentObjectSizeForElementView:(MADDesignerElementView *)elementView;
  @optional
@end

#endif /* MADDesignerElementViewDataSource_h */
