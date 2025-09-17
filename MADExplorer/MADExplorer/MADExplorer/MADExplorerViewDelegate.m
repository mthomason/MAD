//
//  MADExplorerViewDelegate.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/30/15.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "MADExplorerViewDelegate.h"
#import "MADExplorerProtocol.h"

#import "MADLabelFileExplorerDocumentCellTitle.h"
#import "MADLabelFileExplorerDocumentCellSubtitle.h"

#import "MADCollectionViewCellDocument.h"

#import "MADStandard.h"
#import "MADExplorerCellTitle.h"
#import "madlog.h"

#import <MADCocoaExtensions/MTMath.h>
#import <MADCocoaExtensions/NSNumberFormatter+MADExtensions.h>
#import <MADCocoaExtensions/MADViewHelpers.h>

#import <MADFileManager/MADMetaData.h>

#import <UIKit/UITableView.h>
#import <UIKit/UIActivityIndicatorView.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIImageView.h>
#import <UIKit/UILongPressGestureRecognizer.h>
#import <UIKit/UITapGestureRecognizer.h>

/*char *string_for_n(unsigned long fileSize) {
	char buffer_int[12];
	const double one_for_div = 1;
	double integral, fraction;
	fraction = modf(madSystemFileSizeToMB(fileSize), &integral);
	itoa(integral, buffer_int);
	double i = integral / 10;
	strcat(&buffer_int, <#const char *#>)
	i = integral / one_for_div;
}*/

@interface MADExplorerViewDelegate ()

	@property (nonatomic, readwrite, strong) NSMutableArray <NSMutableIndexSet *> *selected;
	@property (nonatomic, readwrite, strong) NSMutableArray <NSMutableIndexSet *> *highlighted;
	@property (nonatomic, strong) NSNumberFormatter *subtitleNumberFormatter;

	@property (nonatomic, strong) NSMutableDictionary <NSNumber *, UILongPressGestureRecognizer *>  *longPressGestures;

	@property (nonatomic, copy) NSPredicate *predicateKindOfLongPressGestureRecognizer;

@end

@implementation MADExplorerViewDelegate

@synthesize showingPopover = _showingPopover;

- (void)dealloc {
	_delegate = nil;
	_predicateKindOfLongPressGestureRecognizer = nil;
	[_longPressGestures removeAllObjects];
}

#pragma mark -
#pragma mark Constructors

- (instancetype)init {
	id delegate = [self initWithNumberOfSections:1];
	return delegate;
}

- (instancetype)initWithNumberOfSections:(NSUInteger)numberOfSections {
	if (self = [super init]) {
		
		NSMutableArray <NSMutableIndexSet *> *arraySelected = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
		for (NSUInteger i = 0; i < numberOfSections; i++) {
			NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc] init];
			[arraySelected addObject:indexSet];
		}
		self.selected = arraySelected;
		
		NSMutableArray <NSMutableIndexSet *> *arrayHighlighted = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
		for (NSUInteger i = 0; i < numberOfSections; i++) {
			NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc] init];
			[arrayHighlighted addObject:indexSet];
		}
		self.highlighted = arrayHighlighted;
		
		_editing = NO;
		_longPressGestures = [[NSMutableDictionary alloc] init];
		
	}
	return self;
}

#pragma mark -
#pragma mark Properties

- (NSArray <NSIndexPath *> *)indexPathsForSelectedItems {
	__block NSArray *indexPaths = [[NSArray alloc] init];
	NSInteger sectionIndex = 0;
	for (NSIndexSet *set in _selected) {
		[set enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
			NSIndexPath *path = [NSIndexPath indexPathForItem:(NSInteger)idx inSection:sectionIndex];
			indexPaths = [indexPaths arrayByAddingObject:path];
		}];
		sectionIndex++;
	}
	return indexPaths;
}

- (NSArray <NSIndexPath *> *)indexPathsForHighlightedItems {
	__block NSArray *indexPaths = [[NSArray alloc] init];
	NSInteger sectionIndex = 0;
	for (NSIndexSet *set in _highlighted) {
		[set enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
			NSIndexPath *path = [NSIndexPath indexPathForItem:(NSInteger)idx
													inSection:sectionIndex];
			indexPaths = [indexPaths arrayByAddingObject:path];
		}];
		sectionIndex++;
	}
	return indexPaths;
}

- (NSUInteger)numberOfItemsSelected {
	NSUInteger c = 0;
	for (NSIndexSet *set in _selected) {
		c += set.count;
	}
	return c;
}

- (NSUInteger)numberOfItemsHighlighted {
	NSUInteger c = 0;
	for (NSIndexSet *set in _highlighted) {
		c += set.count;
	}
	return c;
}

- (void)setEditing:(BOOL)editing {
	//NSLog(@"%s: %@", __PRETTY_FUNCTION__, editing ? @"YES" : @"NO");
	if (_editing != editing) {
		_editing = editing;
	}
}

#pragma mark -
#pragma mark Overrides

- (void)setShowingPopover:(BOOL)showingPopover {
	if (_showingPopover != showingPopover) {
		id <MADExplorerProtocol, UIGestureRecognizerDelegate> sdelegate = self.delegate;
		NSArray <NSIndexPath *> *visibleItems;
		visibleItems = [[sdelegate fileExplorerView] indexPathsForVisibleItems];
		id <MADExplorerProtocol, UIGestureRecognizerDelegate> __weak wdelegate = sdelegate;
		for (NSIndexPath * _Nonnull obj in visibleItems) {
			MADCollectionViewCellDocument *visibleCell;
			visibleCell = (MADCollectionViewCellDocument *)[[wdelegate fileExplorerView] cellForItemAtIndexPath:obj];
			if (showingPopover) {
				visibleCell.labelTitle.textColor = visibleCell.labelTitle.disabledTextColor.copy;
			} else {
				visibleCell.labelTitle.textColor = visibleCell.labelTitle.enabledTextColor.copy;
			}
		}
		_showingPopover = showingPopover;
	}
}

- (BOOL)isShowingPopover {
	return _showingPopover;
}

- (NSPredicate *)predicateKindOfLongPressGestureRecognizer {
	
	if (_predicateKindOfLongPressGestureRecognizer == nil) {
		NSPredicate *predicate;
		NSExpression *left, *right;
		left = [NSExpression expressionForEvaluatedObject];
		right = [NSExpression expressionForConstantValue:[UILongPressGestureRecognizer class]];
		predicate = [NSComparisonPredicate predicateWithLeftExpression: left
													   rightExpression: right
														customSelector: @selector(isMemberOfClass:)];
		_predicateKindOfLongPressGestureRecognizer = predicate.copy;
		
	}
	return _predicateKindOfLongPressGestureRecognizer;
}

#pragma mark -
#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView
	   willDisplayCell:(nonnull MADCollectionViewCellDocument *)cell
	forItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
	
	typeof(_delegate) __strong fileExplorerDelegate = _delegate;
	//cell.contentView.autoresizingMask = MADViewAutoresizingFlexable();
	//cell.contentView.translatesAutoresizingMaskIntoConstraints = YES;
	
	SEL actionEdit = @selector(actionActivateEditMode:);
	
	UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget: self
																								   action: actionEdit];
	longPressGesture.delegate = fileExplorerDelegate;
	[cell addGestureRecognizer: longPressGesture];

	typeof(self) __weak weakself = self;
	cell.labelTitle.handleTap = ^(UILabel *titleLabel) {

		UIView *superview = titleLabel.superview;
		do {
			superview = superview.superview;
		} while (superview != nil && ![superview isKindOfClass:[UICollectionViewCell class]]);
		if (superview == nil) return;
		
		NSAssert([superview isKindOfClass:[UICollectionViewCell class]], @"We expect a collection view");
		UICollectionViewCell *c = (UICollectionViewCell *)superview;
		typeof(self) strongself = weakself;

		id <MADExplorerProtocol, UIGestureRecognizerDelegate> fileDelegate = strongself.delegate;
		if (!strongself.isEditing) {
			[strongself actionRename:c];
		} else {
			UICollectionView *fileExplorerCollectionView = fileDelegate.fileExplorerView;
			NSIndexPath *tappedCellPath = [fileExplorerCollectionView indexPathForCell:c];
			if (tappedCellPath != nil) {
				if (c.isSelected) {
					if ([strongself collectionView:fileExplorerCollectionView shouldDeselectItemAtIndexPath:tappedCellPath]) {
						[fileExplorerCollectionView deselectItemAtIndexPath: tappedCellPath animated: YES];
						[strongself collectionView:fileExplorerCollectionView didDeselectItemAtIndexPath:tappedCellPath];
					}
				} else {
					if ([strongself collectionView:fileExplorerCollectionView shouldSelectItemAtIndexPath:tappedCellPath]) {
						[fileExplorerCollectionView selectItemAtIndexPath: tappedCellPath
													   animated: YES
												 scrollPosition: UICollectionViewScrollPositionNone];
						[strongself collectionView:fileExplorerCollectionView didSelectItemAtIndexPath:tappedCellPath];
					}
				}
			}
		}
	};
	[cell setWobbling: self.isEditing];
	NSNumber *hash = [[NSNumber alloc] initWithUnsignedInteger:cell.hash];
	_longPressGestures[hash] = longPressGesture;
	
	MADMetaData *metadata = [fileExplorerDelegate metadataForItemAtIndexPath:indexPath];
	[cell updateDisplayForMetaData:metadata editing:_editing];

}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(MADCollectionViewCellDocument *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
	NSNumber *hash = [[NSNumber alloc] initWithUnsignedInteger:cell.hash];
	UILongPressGestureRecognizer *gestureToRemove = _longPressGestures[hash];
	if (gestureToRemove != nil) {
		[cell removeGestureRecognizer: gestureToRemove];
	}
	[cell prepareForReuse];
	if (self.isShowingPopover) {
		cell.labelTitle.textColor = cell.labelTitle.disabledTextColor.copy;
	} else {
		cell.labelTitle.textColor = cell.labelTitle.enabledTextColor.copy;
	}
	[_longPressGestures removeObjectForKey: hash];
	cell.wobbling = NO;
	cell.working = NO;
	//[collectionView.collectionViewLayout invalidateLayout];
	//cell.delegate = nil;
}

- (UIContextMenuConfiguration *)collectionView:(UICollectionView *)collectionView
	contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)indexPath
										point:(CGPoint)point {
	return nil;
}

- (void)collectionView:(UICollectionView *)collectionView
	willDisplaySupplementaryView:(UICollectionReusableView *)view
				  forElementKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath { }

- (void)collectionView: (UICollectionView *)collectionView
	didEndDisplayingSupplementaryView:(UICollectionReusableView *)view
	forElementOfKind: (NSString *)elementKind atIndexPath: (NSIndexPath *)indexPath { }

#pragma mark Highlight Item

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	[self.highlighted[(NSUInteger)indexPath.section] addIndex:(NSUInteger)indexPath.item];
}

#pragma mark Unhighlight Item

- (void)collectionView:(UICollectionView *)collectionView
										didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {

	[self.highlighted[(NSUInteger)indexPath.section] removeIndex:(NSUInteger)indexPath.item];
}

#pragma mark Select Item

- (BOOL)collectionView:(UICollectionView *)collectionView
							shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	[self.selected[(NSUInteger)indexPath.section] addIndex:(NSUInteger)indexPath.item];
	
	MADMetaData *metadata = [_delegate metadataForItemAtIndexPath:indexPath];
	NSURL *url = metadata.URL.copy;
	
	if (self.isEditing) {
		[self downloadIfNotYetDownloaded: metadata];
	} else {
		collectionView.allowsSelection = NO;
		MADCollectionViewCellDocument *cell = (MADCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
		[cell setWorking:YES];
		[self.delegate openDocumentAtURL:url completion:^{
			[cell setWorking:NO];
		}];
	}

	[self invokeOperationDidChangeNumberOfItemsSelected:collectionView];
	
}

- (void)collectionView:(UICollectionView *)collectionView allowSelection:(BOOL)allowSelection {

	if (allowSelection) {
		NSInteger section = 0;
		for (NSMutableIndexSet *selectedSections in self.selected) {
			[selectedSections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
				NSIndexPath *indexPath = [NSIndexPath indexPathForItem:(NSInteger)idx inSection:section];
				MADCollectionViewCellDocument *cell = (MADCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
				if (cell != nil) {
					cell.working = NO;
				}
			}];
			section++;
		}
		[self.selected removeAllObjects];
	}
	collectionView.allowsSelection = allowSelection;
}

#pragma mark Deselect Item

- (BOOL)collectionView:(UICollectionView *)collectionView
							shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
	BOOL shouldDeselect = NO;
	NSUInteger section = (NSUInteger)indexPath.section;
	if (_editing) {
		__strong typeof(_delegate) delegate = _delegate;
		if ([_selected[section] containsIndex:(NSUInteger)indexPath.item]) {
			shouldDeselect = YES;
		} else if ([[delegate fileExplorerView].indexPathsForSelectedItems containsObject:indexPath]) {
			shouldDeselect = YES;
			[_selected[section] removeAllIndexes];
			typeof(self) __weak weakself = self;
			[[delegate fileExplorerView].indexPathsForSelectedItems enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
				[weakself.selected[section] addIndex:(NSUInteger)obj.row];
			}];
			
		}
	}
	return shouldDeselect;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {

	//NSLog(@"%s: %ld", __PRETTY_FUNCTION__, (unsigned long)indexPath.item);
	MADCollectionViewCellDocument *cell = (MADCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
	cell.working = NO;
	[self.selected[(NSUInteger)indexPath.section] removeIndex:(NSUInteger)indexPath.item];
	[self invokeOperationDidChangeNumberOfItemsSelected:collectionView];
}

- (UIContextMenuConfiguration *) collectionView:(UICollectionView *) collectionView
   contextMenuConfigurationForItemsAtIndexPaths:(NSArray<NSIndexPath *> *) indexPaths
										  point:(CGPoint) point {
	return nil;
}

#pragma mark -
#pragma mark UICollectionViewFlowLayoutDelegate

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
						layout:(UICollectionViewLayout*)collectionViewLayout
		insetForSectionAtIndex:(NSInteger)section {
	return collectionView.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular ? UIEdgeInsetsMake(5.0, 5.0, 5.0, 5.0) : UIEdgeInsetsMake(5.0, 5.0, 5.0, 5.0);
}


- (CGFloat)collectionView:(UICollectionView *)collectionView
				   layout:(UICollectionViewLayout*)collectionViewLayout
									minimumLineSpacingForSectionAtIndex:(NSInteger)section {
	return collectionView.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular ? 5.0 : 5.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
				   layout:(UICollectionViewLayout*)collectionViewLayout
									minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
	return collectionView.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular ? 5.0 : 5.0;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
				  layout:(UICollectionViewLayout *)collectionViewLayout
											referenceSizeForHeaderInSection:(NSInteger)section {
	return CGSizeZero;
}

- (void)invokeOperationDidChangeNumberOfItemsSelected:(UICollectionView *)collectionView {
	NSObject <MADExplorerProtocol> *delegate = self.delegate;
	NSUInteger numberOfItemsSelected = [self numberOfItemsSelected];
	[delegate explorerDidChangeNumberOfItemsSelected: numberOfItemsSelected];
}

- (void)downloadIfNotYetDownloaded:(MADMetaData *)metadata {
	
	if (!metadata.isDownloaded) {
		
		NSURL *url = metadata.URL.copy;
		
		void (^startDownload)(void) = ^{

			if (url != nil) {
				NSError *error = nil;
				BOOL startedDownloading = [[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL: url error: &error];
				if (!startedDownloading && error != nil) {
					os_log_error(GetExplorerLog(), "%s: Error starting download: %@", __PRETTY_FUNCTION__, error);
				}
			}

		};
		
		[[NSOperationQueue mainQueue] addOperationWithBlock:startDownload];
		
	}
	
}

#pragma mark -
#pragma mark Helpers

- (NSString *)subtitleForStatus:(NSString *)status fileSize:(unsigned long long)fileSize {
	return [status isEqualToString: NSMetadataUbiquitousItemDownloadingStatusNotDownloaded] ?
						NSLocalizedString(MADTextNotDownloaded, MADTextNotDownloaded) :
						[MADStandard standardStringForFileSize:fileSize];
}

- (NSString *)titleForItemAtIndexPath:(NSIndexPath *)indexPath {
	MADMetaData *metadata = [self.delegate metadataForItemAtIndexPath:indexPath];
	NSURL *url = metadata.URL.copy;
	return url.lastPathComponent.stringByDeletingPathExtension;
}

- (NSString *)subtitleForItemAtIndexPath:(NSIndexPath *)indexPath {
	MADMetaData *metadata = [_delegate metadataForItemAtIndexPath:indexPath];
	return [MADExplorerCellTitle explorerCellTitle:metadata];
}

- (NSNumberFormatter *)subtitleNumberFormatter {
	if (!_subtitleNumberFormatter) {
		_subtitleNumberFormatter = [NSNumberFormatter ma_twoDecimalPlacesFormatter];
	}
	return _subtitleNumberFormatter;
}

#pragma mark -
#pragma mark Actions

- (void)actionEmail:(id)sender {
	[_delegate actionEmail:self];
}

- (void)actionActivateEditMode:(UILongPressGestureRecognizer *)sender {
	if (sender.state == UIGestureRecognizerStateBegan && [sender.view isKindOfClass:[UICollectionViewCell class]]) {
		[_delegate actionActivateEditMode:(UICollectionViewCell *)sender.view];
	}
}

- (void)actionRename:(id)sender {
	[_delegate actionRename:sender];
}

- (void)duplicate:(id)sender {
	[_delegate actionDuplicate:self];
}

@end
