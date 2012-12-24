//
//  MTCollectionViewSection.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTCollectionViewSection.h"
#import "CGGeometry+Extras.h"
#import "MTCollectionViewCellElement.h"
#import "AppDelegate.h"

@implementation MTCollectionViewSection

- (void)dealloc {
    [_designerViewController release];
    [_objectID release];
    [_localizedName release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame name:(NSString *)name andObjectID:(NSManagedObjectID *)objid inDesigner:(MUIViewControllerReportDesigner *)designerViewController {
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        [self setDelegate:self];
        [self setDataSource:self];
        
        [self setDesignerViewController:designerViewController];

        [self registerClass:[MTCollectionViewCellElement class] forCellWithReuseIdentifier:@"MTCollectionViewCellElement"];
        [self setObjectID: objid];
        [self setLocalizedName: name];

        [self setBackgroundColor: [UIColor edaBlackTwentyFivePercent]];
        [[self layer] setCornerRadius: 5.0000f];
        //[self setOpaque: NO];
        [self setClipsToBounds: YES];

    }
    [layout release];

    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect: rect];
    [[UIColor blueColor] set];
    [[self localizedName] drawInRect: rect
                            withFont: [UIFont systemFontOfSize:([UIFont systemFontSize])]
                       lineBreakMode: NSLineBreakByClipping
                           alignment: NSTextAlignmentLeft];
}

- (NSIndexPath *)indexOfAlienViewWithCenterPoint:(CGPoint)alienCenter {
    CGFloat minDistance = CGFLOAT_MAX;
    NSIndexPath *nearestIndexPath = nil;
    for (NSIndexPath *indexPath in [self indexPathsForVisibleItems]) {
        UICollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForItemAtIndexPath: indexPath];
        CGFloat distance = CGDistance([layoutAttributes center], alienCenter);
        if (distance < minDistance) {
            minDistance = distance;
            nearestIndexPath = indexPath;
        }
    }
    return  nearestIndexPath;
}

#pragma mark - Collection View Flow Layout Delegate

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(5.0000f, 5.0000f, 5.0000f, 5.0000f);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 5.0000f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 5.0000f;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger row = [indexPath row];
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[self objectID] fromObjectContext:managedObjectContext];
    
    NSOrderedSet *objects = [documentSection hasObjects];
    
    CGSize result;
    
    if ([objects count] > row) {
        
        RptqDocumentObject *documentObject = [objects objectAtIndex:row];
        result = CGSizeMake([[documentObject sizewidth] floatValue], [[documentObject sizeheight] floatValue]);
    } else {
        result = CGSizeZero;
    }
    
    return result;
}

#pragma mark - Collection View Data Source

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger row = [indexPath row];
    
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    
    static NSString *tileReuseIdentifier = @"MTCollectionViewCellElement";
    UICollectionViewCell *cell = [[collectionView dequeueReusableCellWithReuseIdentifier:tileReuseIdentifier
                                                                                forIndexPath:indexPath] retain];
    
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[self objectID] fromObjectContext:managedObjectContext];
    
    NSOrderedSet *objects = [documentSection hasObjects];

    if ([objects count] > row) {

        RptqDocumentObject *documentObject = [objects objectAtIndex:row];
        switch ([documentObject getType]) {
            case MNSObjectTypeLabel: {

                break;
            }
            case MNSObjectTypeLabelDataField: {
                
                RptqDocumentObjectLabelDataField *documentObjectCast = documentObject.isLabelDataField;
                        CGRect f = CGRectMake(0, 0, [[documentObjectCast.parentObjectLabelDataField sizewidth] floatValue], [[documentObjectCast.parentObjectLabelDataField sizeheight] floatValue]);
                ElementView *newView = [[ElementView alloc] initWithFrame: f inSectionView:self ofDesignerView:[[self designerViewController] designScrollView]];
                [newView setBounds: f];
                [newView setStringElm: documentObjectCast.parentObjectLabelDataField.isLabelDataField.text];
                [newView setMultipleTouchEnabled: YES];
                [newView setExclusiveTouch: YES];
                [newView setObjectID: [documentObjectCast objectID]];
                [newView setDelegate: [self designerViewController]];
                [newView setTag: [[documentObjectCast objectID] hash]];
                [cell setBounds: CGRectMake(CGPointZero.x, CGPointZero.y, f.size.width, f.size.height)];
                [[cell contentView]  setBounds:CGRectMake(CGPointZero.x, CGPointZero.y, f.size.width, f.size.height)];
                
                [[cell contentView] addSubview:newView];
                
                [cell setBackgroundColor:[UIColor redColor]];
                [[cell contentView] setBackgroundColor:[UIColor blueColor]];
                
                [newView release];

                break;
            }
            case MNSObjectTypeLabelFormula: {
                break;
            }
            case MNSObjectTypeLabelLabelLink: {
                break;
            }
            default: {
                break;
            }
        }
    }
    
    return [cell autorelease];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[self objectID] fromObjectContext:[[AppDelegate activeDocument] managedObjectContext]];
    NSOrderedSet *objects = [documentSection hasObjects];
    NSLog(@"Objects in section: %d", [objects count]);
    return [objects count];
}

/*
 - (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
 viewForSupplementaryElementOfKind:(NSString *)kind
 atIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

#pragma mark - Collection View Delegate
/*
- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
    
}*/

@end