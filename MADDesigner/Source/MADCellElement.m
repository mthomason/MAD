//
//  MTCollectionViewCell.m
//  Reports
//
//  Created by Michael Thomason on 12/21/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADCellElement.h"
#import "MADDesignerElementView.h"
#import "MADCellElementDelegate.h"
#import <UIKit/UIMenuController.h>
#import <UIKit/UIImage.h>

@interface MADCellElement ()
@property (nonatomic, weak) MADDesignerElementView *elementView;
@end

@implementation MADCellElement

- (void)dealloc { }

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		UIContextMenuInteraction *interaction = [[UIContextMenuInteraction alloc] initWithDelegate:self];
		[self.contentView addInteraction:interaction];
		//[self commonInit];
	}
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		UIContextMenuInteraction *interaction = [[UIContextMenuInteraction alloc] initWithDelegate:self];
		[self.contentView addInteraction:interaction];
		//[self commonInit];
	}
	return self;
}

- (UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location {
	return [UIContextMenuConfiguration configurationWithIdentifier:nil
												   previewProvider:nil
													actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull __unused suggestedActions) {
		UIAction *edit = [UIAction actionWithTitle:@"Edit"
											 image:[UIImage systemImageNamed:@"pencil"]
										identifier:nil
										   handler:^(__kindof UIAction * _Nonnull __unused action) {
			NSObject <MADCellElementDelegate> *delegate = self.delegate;
			if ([delegate respondsToSelector:@selector(editDocumentObjectRepresentedByCell:)]) {
					[delegate editDocumentObjectRepresentedByCell:self];
			}
		}];
		UIAction *delete = [UIAction actionWithTitle:@"Delete"
											   image:[UIImage systemImageNamed:@"trash"]
										  identifier:nil
											 handler:^(__kindof UIAction * _Nonnull __unused action) {
			NSObject <MADCellElementDelegate> *delegate = self.delegate;
			if ([delegate respondsToSelector:@selector(deleteDocumentObjectRepresentedByCell:)]) {
					[delegate deleteDocumentObjectRepresentedByCell:self];
			}
		}];
		UIAction *format = [UIAction actionWithTitle:@"Format"
											   image:[UIImage systemImageNamed:@"paintbrush"]
										  identifier:nil
											 handler:^(__kindof UIAction * _Nonnull __unused action) {
			NSObject <MADCellElementDelegate> *delegate = self.delegate;
			if ([delegate respondsToSelector:@selector(formatDocumentObjectRepresentedByCell:)]) {
					[delegate formatDocumentObjectRepresentedByCell:self];
			}
		}];
		return [UIMenu menuWithTitle:@"" children:@[edit, format, delete]];
	}];
}

- (void)commonInit {
	UIMenuController *menu = [UIMenuController sharedMenuController];
	NSArray *menuMenuItems = menu.menuItems.count > 0 ? menu.menuItems : [[NSArray alloc] init];
	NSMutableArray <UIMenuItem *> *menuItems = [[NSMutableArray alloc] initWithArray: menuMenuItems];
	
	NSUInteger indexOfActions = [menuItems indexOfObjectPassingTest:^BOOL(UIMenuItem * _Nonnull obj, NSUInteger __unused idx, BOOL * _Nonnull __unused stop) {
		return obj.action == @selector(edit:);
	}];

	if (indexOfActions == NSNotFound) {
		
		UIMenuItem *menuItemEdit = [[UIMenuItem alloc] initWithTitle: NSLocalizedString(@"Edit", @"Edit") action: @selector(edit:)];
		[menuItems addObject:menuItemEdit];
	}
	
	indexOfActions = [menuItems indexOfObjectPassingTest:^BOOL(UIMenuItem * _Nonnull obj, NSUInteger __unused idx, BOOL * _Nonnull __unused stop) {
		return obj.action == @selector(format:);
	}];

	if (indexOfActions == NSNotFound) {
		UIMenuItem *menuItemFormat = [[UIMenuItem alloc] initWithTitle: NSLocalizedString(@"Format", @"Format") action: @selector(format:)];
		[menuItems addObject:menuItemFormat];
	}
	menu.menuItems = menuItems;
}

- (BOOL)canBecomeFirstResponder {
	return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
	BOOL result = NO;
	
	MADPrintPageElementType objectType = [self.delegate objectTypeRepresentedByCell:self];
	
	BOOL deleteAction = action == @selector(delete:);
	BOOL editAction = action == @selector(edit:);
	BOOL formatAction = action == @selector(format:);
	
	switch (objectType) {
			
		case MADPrintPageElementTypeLabelDynamic: {
			result = deleteAction || editAction || formatAction;
			break;
		}
			
		case MADPrintPageElementTypeLabelStatic: {
			result = deleteAction || editAction || formatAction;
			break;
		}
		case MADPrintPageElementTypeAggregate: {
			result = deleteAction || editAction || formatAction;
			break;
		}
		case MADPrintPageElementTypeImage: {
			result = deleteAction || formatAction;	// FIXME: Add ability to edit image fields.  84848422
			break;
		}
		case MADPrintPageElementTypeWhtiespace: {
			result = deleteAction || formatAction;
			break;
		}
		case MADPrintPageElementTypeBarcode: {
			result = deleteAction || editAction || formatAction;
			break;
		}
		default:
			break;
	}
	
	return result;
}

- (void)format:(id)sender {
	[self.delegate formatDocumentObjectRepresentedByCell:self];
}

- (void)edit:(id)sender {
	[self.delegate editDocumentObjectRepresentedByCell:self];
}

- (void)delete:(id)sender {
	[self.delegate deleteDocumentObjectRepresentedByCell:self];
}

- (void)addElementView:(MADDesignerElementView *)elementView {
	[self.contentView addSubview:elementView];
	[self.contentView bringSubviewToFront:elementView];
	self.elementView = elementView;
}

#pragma mark - Accessibility

- (BOOL)isAccessibilityElement {
	return YES;
}

- (NSString *)accessibilityHint {
	return NSLocalizedString(@"Shows toolbox.", @"Shows toolbox.");
}

- (NSString *)accessibilityLabel {
	return self.elementView.textRepresentation;
}

@end
