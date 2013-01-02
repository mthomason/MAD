//
//  ReportDesignerTableViewController.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MUIViewControllerReportDesigner.h"
#import "MTCollectionViewCellElement.h"
#import "SectionEnumerator.h"
#import "AppDelegate.h"
#import "UIView+StringTag.h"
#import "UICollectionView+Extras.h"
#import "UIView+NSObjectIdTag.h"
#import "RptqDocumentObjectLabelDataField+Extras.h"
#import "UICollectionViewCell+Reuse.h"
#import "UICollectionReusableView+Reuse.h"
#import "MTCollectionReuseableViewDefault.h"
#import "MTCollectionReusableViewFloatingLabel.h"
#import "MTElementView.h"
#import "MTCollectionViewSection.h"
#import "MTFont.h"

@interface MUIViewControllerReportDesigner()
    <FontSettingsTableViewControllerDelegate,
        UITableViewControllerFontSelectorDelegate>

@property (assign) BOOL formualInformationViewIsVisable;
@property (assign) BOOL imageInformationViewIsVisable;
@property (assign) BOOL labelInformationViewIsVisable;

@property (nonatomic, retain) NSMutableArray *scrollViewFrames;

// MARK: Needed for the toolbox.
@property (nonatomic, retain) UIToolbar *toolboxToolbar;
@property (nonatomic, retain) UIScrollView *toolboxScrollView;
@property (nonatomic, retain) UIView *toolboxBackgroundView;
@property (nonatomic, retain) NSArray *toolboxToolbarItemsPrimary;
@property (nonatomic, retain) NSArray *toolboxToolbarItemsFontChooser;

@property (retain, nonatomic) UITableViewControllerFontSettings *tableViewControllerTextLayoutSettings;
@property (retain, nonatomic) UITableViewControllerFontSelector *tableViewControllerFontSelector;

@property (assign) BOOL toolboxIsVisible;

@end

@implementation MUIViewControllerReportDesigner

#pragma mark - UITableViewControllerFontSelectorDelegate

- (void)uITableViewControllerDidUpdateFontToFontWithName:(NSString *)fontName {
    CGFloat currentPointSize = [[[[self tableViewControllerTextLayoutSettings] labelFontName] font] pointSize];
    MTFont *font = [[MTFont alloc] initWithFamilyName:fontName andPointSize:currentPointSize];
    [[[self tableViewControllerTextLayoutSettings] labelFontName] setFont:[font font]];
    [[[self tableViewControllerTextLayoutSettings] labelFontName] setText:[font name]];

    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    for (NSManagedObjectID *objectId in [self selectedObjectIds]) {
        RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:objectId fromObjectContext:managedObjectContext];
        [documentObject setFontname:[font name]];
    }
    [[AppDelegate activeDocument] saveContext];
    [font release];
    [[self navigationBarToolbox] popNavigationItemAnimated:YES];
}

#pragma mark - FontSettingsTableViewControllerDelegate

- (void)fontSettingsTableViewControllerDidSelectFontList:(UITableViewControllerFontSettings *)controller {
    [[self navigationBarToolbox] pushNavigationItem:[self navigationItemFontChooser] animated:YES];
    
}

#pragma mark - NSObject

- (void)dealloc {
    [_navigationItemStyle release];
    [_navigationItemLayout release];
    [_navigationItemFontChooser release];
    
    [_tableViewControllerTextLayoutSettings release];
    [_tableViewControllerFontSelector release];
    
    [_toolboxBackgroundView release];
    [_toolboxScrollView release];
    [_toolboxToolbarItemsFontChooser release];
    [_toolboxToolbarItemsPrimary release];
    [_toolboxToolbar release];

    [_scrollViewFrames release];
    [_sections release];
    [_toolbox release];
    [_settingsPopoverController release];
    [_designScrollView release];
    [_informationButton release];
    [_barButtonItemInfo release];
    [_barButtonItemSettings release];
    [_barButtonItemObjects release];
    [_toolbarBottom release];
    [_toolbarTop release];
    [_toolboxView release];
    [_toolboxContainerView release];
    [_navigationBarToolbox release];
    [super dealloc];
}

#pragma mark - UIViewController

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)awakeFromNib {

}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    //CGFloat paperWidth = CGFloatPointsForInches(8.5000f);
    
    [self setToolboxIsVisible:NO];
    
    CGPoint origin = CGPointMake(5.0000f, 5.0000f);
    //CGRect frame = CGRectMake(origin.x, origin.y, paperWidth, CGSizeZero.height);
    CGRect frame = CGRectMake(origin.x, origin.y, self.view.frame.size.width - 10.0000f, CGSizeZero.height);
    
    SectionEnumerator *enumerator = [[SectionEnumerator alloc] initWithManagedDocumentQuery:[[AppDelegate activeDocument] document]];
    NSInteger ctr = 0;
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:[enumerator count]];
    [self setSections: dict];
    [dict release];
    
    frame.size.height = 22.0000f;
    
    NSString *collectionViewReuseId = [MTCollectionViewCellElement reuseIdentifier];
    

    //NSString *supplmentaryViewReuseIdHeader = [MTCollectionReuseableViewDefault reuseIdentifier];
    //NSString *supplmentaryViewReuseIdFloatingLabel = [MTCollectionReusableViewFloatingLabel reuseIdentifier];
    
//    UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Info", @"Info")
//                                                      action:@selector(customAction:)];
//    [[UIMenuController sharedMenuController] setMenuItems:[NSArray arrayWithObject:menuItem]];
    
    for (RptqDocumentSection *sec in enumerator) {

        if (ctr > 0) frame.origin.y += frame.size.height + 10.0000f;
        frame.size.height = [[sec height] floatValue];
        
        [[self scrollViewFrames] addObject:[NSValue valueWithCGRect:frame]];

        MTCollectionViewFlowLayoutDesignerSection *layout = [[MTCollectionViewFlowLayoutDesignerSection alloc] init];
        
        [layout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
        
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:layout];
        
        [collectionView registerClass:[MTCollectionViewCellElement class]
           forCellWithReuseIdentifier: collectionViewReuseId];

        /*
        [collectionView registerClass:[MTCollectionReuseableViewDefault class]
           forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                  withReuseIdentifier:supplmentaryViewReuseIdHeader];

        [collectionView registerClass:[MTCollectionReuseableViewDefault class]
           forSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                  withReuseIdentifier:supplmentaryViewReuseIdHeader];

        [collectionView registerClass:[MTCollectionReusableViewFloatingLabel class]
           forSupplementaryViewOfKind:MTCollectionElementKindSectionLabel
                  withReuseIdentifier:supplmentaryViewReuseIdFloatingLabel];
         */
        [collectionView setTag:[[sec identifier] integerValue]];
        [collectionView setDelegate:self];
        [collectionView setDataSource:self];
        [collectionView setBackgroundColor:[UIColor whiteColor]];
        [[collectionView layer] setCornerRadius:5.0000f];
        [collectionView setClipsToBounds:YES];
        [collectionView setObjectIdTag:[sec objectID]];
        [collectionView setAutoresizingMask: UIViewAutoresizingFlexibleWidth];
        [collectionView setAllowsSelection:YES];
        [collectionView setAllowsMultipleSelection:YES];
        UIView *backgroundView = [[UIView alloc] initWithFrame:[collectionView frame]];

        CGFloat labelHeight = 14.0000f;
        CGFloat labelWidth = 70.0000f;
        CGRect labelFrame = CGRectMake((frame.origin.x + frame.size.width) - labelWidth,
                                       (frame.origin.y + frame.size.height) - labelHeight,
                                       labelWidth,
                                       labelHeight);
        
        UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
        [label setTextAlignment:NSTextAlignmentCenter];
        [[label layer] setCornerRadius:5.0000f];
        [label setFont:[UIFont systemFontOfSize:8.0000f]];
        [label setText:[sec localizedDisplayName]];
        [label setBackgroundColor:[UIColor edaYellow]];
        [label setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
        [collectionView setBackgroundView:backgroundView];
        

        [[self designScrollView] addSubview:collectionView];
        [self setCollectionView:collectionView forSection:sec];

        [[self designScrollView] addSubview:label];
        

        
        [label release];

        [layout release];
        [collectionView release];
        [backgroundView release];

        ctr++;
    }
    

    [enumerator release];
    
    [[self designScrollView] setScrollEnabled:YES];
    
    [[self designScrollView] setContentSize:self.view.frame.size];
    [[self designScrollView] setBackgroundColor: [UIColor scrollViewTexturedBackgroundColor]];
}

- (UICollectionView *)getCollectionViewForRptqSection:(RptqDocumentSection *)documentSection {
    return [[self sections] objectForKey:[[[documentSection objectID] URIRepresentation] absoluteString]];
}

- (void)setCollectionView:(UICollectionView *)collectionView forSection:(RptqDocumentSection *)documentSection {
    [[self sections] setValue:collectionView forKey:[[[documentSection objectID] URIRepresentation] absoluteString]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contextChanged:)
                                                 name:NSManagedObjectContextObjectsDidChangeNotification
                                               object:managedObjectContext];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSManagedObjectContextObjectsDidChangeNotification
                                                  object:managedObjectContext];
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showSettings"]) {
        UINavigationController *navController = [[segue destinationViewController] retain];
        if (navController) {
            if ([[navController viewControllers] count] > 0) {
                UITableViewControllerSettings *tvcSettings = [[[navController viewControllers] objectAtIndex: 0] retain];
                [tvcSettings setDelegate:self];
                [tvcSettings release];
            }
        }
        [navController release];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            UIPopoverController *popoverController = [(UIStoryboardPopoverSegue *)segue popoverController];
            [self setSettingsPopoverController: popoverController];
            popoverController.delegate = self;
        }
    } else if ([[segue identifier] isEqualToString:@"showObjects"]) {
        MUIViewControllerObjectSelector *viewControllerObjectSelector = [segue destinationViewController];
        [viewControllerObjectSelector setObjectSelectorDelegate:self];
    } else if ([[segue identifier] isEqualToString:@"showReportViewerFromDesign"]) {
        MUIViewControllerReportViewer *viewControllerReportViewer = [segue destinationViewController];
        [viewControllerReportViewer setDelegate:self];
    }
}

#pragma mark - Core Data Notifications

- (void)contextChanged:(NSNotification *)notification {
    
}

#pragma mark - Actions

- (void)cut:(id)sender {
    NSLog(@"Fake a cut.");
}

- (void)copy:(id)sender {
    NSLog(@"Fake a copy.");
}

- (void)select:(id)sender {
    NSLog(@"Fake a select.");
}

- (void)selectAll:(id)sender {
    NSLog(@"Fake a select all.");
}

- (void)paste:(id)sender {
    NSLog(@"Fake a paste.");
}

- (void)delete:(id)sender {
    NSLog(@"Fake a delete.");
}

- (void)toggleUnderline:(id)sender {
    NSLog(@"Fake a delete.");
    
}

- (void)toggleItalics:(id)sender {
    NSLog(@"Fake a delete.");
    
}

- (void)toggleBoldface:(id)sender {
    NSLog(@"Fake a delete.");
    
}

- (void)showFontChooser:(id)sender {
    
}

- (void)hideFontChooser:(id)sender {
    
}

- (void)customAction:(id)sender {
    NSLog(@"custom action! %@", sender);
}

- (void)openReport:(NSURL *)url {
    UIManagedDocumentPreferencesUser *trvFile = [[UIManagedDocumentPreferencesUser alloc] initWithFileURL:url];
    
    [trvFile release];
}

- (void)openTemplate:(NSURL *)url {
    
    NSString *origionalFileName = [[url lastPathComponent] retain];
    
    NSURL *urlLibraryTemplate = [[NSFileManager applicationLibraryTemplatesDirectoryUrl] retain];
    NSURL *urlFilenameWithoutExtention = [[[urlLibraryTemplate URLByAppendingPathComponent:origionalFileName] URLByDeletingPathExtension] retain];
    
    NSURL *templateDestination = [[urlFilenameWithoutExtention URLByAppendingPathExtension:TRVDATA_PATH_EXTENSION] retain];
    NSString *templateDestinationName = [[templateDestination lastPathComponent] retain];
    
    BOOL fileWritten = NO;
    
    NSInteger ctr = 0;
    while (!fileWritten) {
        NSError *error;
        fileWritten = [[NSFileManager defaultManager] copyItemAtURL:url toURL:templateDestination error:&error];
        if (!fileWritten) {
            [templateDestination release];
            NSString *p = [[[urlFilenameWithoutExtention path] stringByAppendingFormat:@" %d", (ctr + 1)] retain];
            templateDestination = [[urlFilenameWithoutExtention URLByAppendingPathExtension:TRVDATA_PATH_EXTENSION] retain];
            [p release];
        }
    }
    [urlFilenameWithoutExtention release];
    [urlLibraryTemplate release];
    [templateDestinationName release];
    [origionalFileName release];
    
    
    //Now that we copied the file, we open it.  Yay!
    [self openReport:templateDestination];
    
    [templateDestination release];
}

- (IBAction)done:(id)sender {
    [[self delegate] viewControllerDidFinish:self];
}

- (IBAction)showObjects:(id)sender {
    [self performSegueWithIdentifier:@"showObjects" sender:sender];
}

- (IBAction)showSettings:(id)sender {
    [self performSegueWithIdentifier:@"showSettings" sender:sender];
}

- (IBAction)info:(id)sender {
    /*
    //Make sure there are no information views open
    [[self informationButton] setEnabled: NO];
    
    UIStoryboard *sbLblControl = [[UIStoryboard storyboardWithName:STORYBOARD_NAME() bundle:nil] retain];
    UIViewControllerToolbox *lblControl = [[sbLblControl instantiateViewControllerWithIdentifier:@"LabelViewController"] retain];
    [self setToolbox:lblControl];
    [lblControl release];
    [sbLblControl release];
    
    [[self toolbox] setDelegate: self];
    [[[self toolbox] view] setFrame:[self toolboxOffScreen]];
    [[self view] addSubview:[[self toolbox] view]];
    
    [UIView animateWithDuration: MNSAnimationDurationShowFromBottomHalf
                     animations: ^{
                         [[[self toolbox] view] setFrame: [self toolboxOnScreen]];
                         [[self designScrollView] setFrame:[self designScrollViewWithToolbox]];
                     } completion:^(BOOL finished) {
                         
                     }];
     */
    [self showToolbox:sender];
}

- (IBAction)showToolbox:(id)sender {
    if (![self toolboxIsVisible]) {
        [self setToolboxIsVisible:YES];
        [[self informationButton] setEnabled: NO];
        
        NSSet *selectItemIds = [self selectedObjectIds];

        MTMargin margin = MTMarginMake(5.0000f, 5.00000f, 5.0000f, 5.0000f);
    
        
        if (![self tableViewControllerFontSelector]) {
            
            
            UIStoryboard *sbFontTableView = [[UIStoryboard storyboardWithName:STORYBOARD_NAME() bundle:nil] retain];
            
            UITableViewControllerFontSettings *tb1 = [sbFontTableView instantiateViewControllerWithIdentifier:@"FontSettingsTableViewController"];
            [tb1 setDelegate: self];
            [self setTableViewControllerTextLayoutSettings:tb1];
            
            UITableViewControllerFontSelector *tb2 = [sbFontTableView instantiateViewControllerWithIdentifier:@"FontListSettingsTableViewController"];
            [tb2 setDelegate: self];
            [self setTableViewControllerFontSelector:tb2];
        }
        
        CGFloat designViewWidth = [[self view] bounds].size.width;
        CGFloat designViewHeight = [[self view] bounds].size.height - [[self toolbarTop] bounds].size.height - [[self toolboxView] bounds].size.height;
        CGRect designViewBounds = CGRectMake(CGPointZero.x, CGPointZero.y, designViewWidth, designViewHeight);
        
        CGFloat designViewOriginX = [[self designScrollView] frame].origin.x;
        CGFloat designViewOriginY = [[self designScrollView] frame].origin.y;
        CGRect designViewRectToCenter = CGRectMake(designViewOriginX, designViewOriginY, designViewBounds.size.width, designViewBounds.size.height);
        CGPoint designViewCenter = CGCenterOfRect(designViewRectToCenter);
        
        CGFloat toolboxOriginX = CGPointZero.x;
        CGFloat toolboxOriginY = designViewOriginY + designViewHeight;
        CGRect toolboxRectToCenter = CGRectMake(toolboxOriginX, toolboxOriginY, [[self toolboxView] bounds].size.width, [[self toolboxView] bounds].size.height);
        CGPoint toolboxCenter = CGCenterOfRect(toolboxRectToCenter);

        [[[self tableViewControllerTextLayoutSettings] tableView] setFrame: [[self toolboxContainerView] bounds]];
        [[[self tableViewControllerTextLayoutSettings] tableView] setBounds: [[self toolboxContainerView] bounds]];
        [[self tableViewControllerTextLayoutSettings] initalizeDocumentObjects:[self selectedObjectIds]];
        [[self toolboxContainerView] addSubview:[[self tableViewControllerTextLayoutSettings] tableView]];
        [UIView animateWithDuration: MNSAnimationDurationShowFromBottomHalf
                         animations: ^{
                             [[self designScrollView] setBounds: designViewBounds];
                             [[self designScrollView] setCenter:designViewCenter];
                             [[self toolboxView] setBounds:[[self toolboxView] bounds]];
                             [[self toolboxView] setCenter:toolboxCenter];
                             [[self view] bringSubviewToFront:[self toolboxView]];
                         } completion:^(BOOL finished) {
                             //[[self toolboxBackgroundView] removeFromSuperview];
                             //[[[self tableViewControllerTextLayoutSettings] tableView] setFrame:[[self toolboxContainerView] frame]];
                         }];
        
        
    }
}

- (IBAction)hideToolbox:(id)sender {
    if ([self toolboxIsVisible]) {
        [self setToolboxIsVisible:NO];
        
        CGFloat designViewWidth = [[self view] bounds].size.width;
        CGFloat designViewHeight = [[self view] bounds].size.height - [[self toolbarBottom] bounds].size.height - [[self toolbarTop] bounds].size.height;
        CGRect designViewBounds = CGRectMake(CGPointZero.x, CGPointZero.y, designViewWidth, designViewHeight);
        
        CGFloat designViewCenterX = [[self designScrollView] frame].origin.x;
        CGFloat designViewCenterY = [[self designScrollView] frame].origin.y;
        CGRect designViewRectToCenter = CGRectMake(designViewCenterX, designViewCenterY, designViewBounds.size.width, designViewBounds.size.height);
        CGPoint designViewCenter = CGCenterOfRect(designViewRectToCenter);
        
        //[[self designScrollView] setBounds: designViewBounds];
        //[[self designScrollView] setCenter:designViewCenter];
        
        CGFloat toolboxOriginX = CGPointZero.x;
        CGFloat toolboxOriginY = CGPointZero.y + [[self view] bounds].size.height;
        CGRect toolboxRectToCenter = CGRectMake(toolboxOriginX, toolboxOriginY, [[self toolboxView] bounds].size.width, [[self toolboxView] bounds].size.height);
        CGPoint toolboxCenter = CGCenterOfRect(toolboxRectToCenter);
        
        [UIView animateWithDuration: MNSAnimationDurationShowFromBottomHalf
                         animations: ^{
                             [[self designScrollView] setBounds: designViewBounds];
                             [[self designScrollView] setCenter:designViewCenter];
                             [[self toolboxView] setBounds:[[self toolboxView] bounds]];
                             [[self toolboxView] setCenter:toolboxCenter];
                         } completion:^(BOOL finished) {
                             [[[self tableViewControllerTextLayoutSettings] tableView] removeFromSuperview];
                             [[self informationButton] setEnabled: YES];
                         }];
    }
}

#pragma mark - UIMenuController required methods

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    NSLog(@"Action %@ with %@", NSStringFromSelector(action), sender);
    return action == @selector(cut:) ||
            action == @selector(copy:) ||
            action == @selector(paste:) ||
            action == @selector(delete:) ||
            action == @selector(select:) ||
            action == @selector(selectAll:) ||
            action == @selector(toggleBoldface:) ||
            action == @selector(toggleItalics:) ||
            action == @selector(toggleUnderline:) ||
            action == @selector(customAction:) ||
            [super canPerformAction:action withSender:sender];
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

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger row = [indexPath row];
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag] fromObjectContext:managedObjectContext];
    
    NSOrderedSet *objects = [documentSection hasObjects];
    
    CGSize result;
    
    if ([objects count] > row) {
        
        RptqDocumentObject *documentObject = [objects objectAtIndex:row];
        result = CGSizeMake([[documentObject sizewidth] floatValue], [[documentObject sizeheight] floatValue]);
    } else {
        result = CGSizeZero;
    }
    NSLog(@"Size for item at %@: %@", indexPath, NSStringFromCGSize(result));
    return result;
}

#pragma mark - Collection View Data Source

// MARK: Load the elements into the sections.

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    NSInteger row = [indexPath row];
    
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    
    UICollectionViewCell *cell = [[collectionView dequeueReusableCellWithReuseIdentifier:[MTCollectionViewCellElement reuseIdentifier]
                                                                            forIndexPath:indexPath] retain];
    
    //[[[collectionView] tag]
    
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag] fromObjectContext:managedObjectContext];
    
    NSOrderedSet *objects = [documentSection hasObjects];
    
    if ([objects count] > row) {
        
        RptqDocumentObject *documentObject = [objects objectAtIndex:row];
        switch ([documentObject getType]) {
            case MNSObjectTypeLabel: {
                
                break;
            }
            case MNSObjectTypeLabelDataField: {
                
                RptqDocumentObjectLabelDataField *documentObjectCast = documentObject.isLabelDataField;
                CGFloat elementViewWidth = [[documentObjectCast.parentObjectLabelDataField sizewidth] floatValue];
                CGFloat elementViewHeight = [[documentObjectCast.parentObjectLabelDataField sizeheight] floatValue];
                CGRect f = CGRectMake(CGPointZero.x, CGPointZero.y, elementViewWidth, elementViewHeight);

                MTElementView *newView1 = [[MTElementView alloc] initWithFrame:f andObjectId:[documentObject objectID] /*[documentObjectCast objectID]*/ inObjectContext:managedObjectContext];
                [newView1 setBackgroundColor:[UIColor whiteColor]];
                //[newView1 addSubview: label];
                [newView1 setBounds: f];
                [newView1 setMultipleTouchEnabled: YES];
                [newView1 setExclusiveTouch: YES];
                [newView1 setOpaque: YES];
                [[newView1 layer] setCornerRadius: 5.0000f];
                
                UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panPiece:)];
                [panGesture setMaximumNumberOfTouches:1];
                [panGesture setDelegate:self];
                [newView1 addGestureRecognizer:panGesture];
                [panGesture release];
                
                [cell setTag:[[[documentObjectCast parentObjectLabelDataField] identifier] integerValue] + 3838];
                [cell setBounds: CGRectMake(CGPointZero.x, CGPointZero.y, f.size.width, f.size.height)];
                [[cell contentView]  setBounds:CGRectMake(CGPointZero.x, CGPointZero.y, f.size.width, f.size.height)];
                
                [newView1 updateDisplayLabel];
                [[cell contentView] addSubview:newView1];
                [newView1 release];
                
                
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
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag]
                                                                            fromObjectContext:[[AppDelegate activeDocument] managedObjectContext]];
    NSOrderedSet *objects = [documentSection hasObjects];
    //NSLog(@"Objects in section: %d", [objects count]);
    return [objects count];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {

    MTCollectionReuseableViewDefault *result = nil;
    
    if ([kind isEqualToString:MTCollectionElementKindSectionLabel]) {
        result = [collectionView dequeueReusableSupplementaryViewOfKind: kind
                                                    withReuseIdentifier: [MTCollectionReusableViewFloatingLabel reuseIdentifier]
                                                           forIndexPath: indexPath];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0000f, 0.0000f, 100.0000f, 22.0000f)];
        [label setBackgroundColor:[UIColor edaBlackTwentyFivePercent]];
        [label setText:@"Floating Label"];
        [result addSubview:label];
        [label release];
    } else if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        result = [collectionView dequeueReusableSupplementaryViewOfKind: kind
                                                    withReuseIdentifier: [MTCollectionReuseableViewDefault reuseIdentifier]
                                                           forIndexPath: indexPath];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0000f, 0.0000f, 200.0000f, 22.0000f)];
        [label setText:@"Header"];
        [result addSubview:label];
        [label release];
    } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        result = [collectionView dequeueReusableSupplementaryViewOfKind: kind
                                                    withReuseIdentifier: [MTCollectionReuseableViewDefault reuseIdentifier]
                                                           forIndexPath: indexPath];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0000f, 0.0000f, 200.0000f, 22.0000f)];
        [label setText:@"Footer"];
        [result addSubview:label];
        [label release];
    } else {
        result = [collectionView dequeueReusableSupplementaryViewOfKind: kind
                                                    withReuseIdentifier: [MTCollectionReuseableViewDefault reuseIdentifier]
                                                           forIndexPath: indexPath];
    }
    return result;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

#pragma mark - Collection View Delegate

- (MTElementView *)elementViewAtIndexPath:(NSIndexPath *)indexPath inCollectionView:(UICollectionView *)collectionView {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    MTElementView *result = nil;
    for (MTElementView *elementView in [[cell contentView] subviews]) {
        result = elementView;
        break;
    }
    return result;
}

- (NSSet *)selectedObjectIdsInCollectionView:(UICollectionView *)collectionView {
    NSMutableSet *result = [[NSMutableSet alloc] init];
    for (NSUInteger section = 0; section < [collectionView numberOfSections]; section++) {
        for (NSUInteger item = 0; item < [collectionView numberOfItemsInSection:section]; item++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            MTElementView *elementView = [self elementViewAtIndexPath:indexPath inCollectionView:collectionView];
            if ([elementView isSelected]) {
                [result addObject:[elementView objectIdTag]];
            }
        }
    }
    return [result autorelease];
}

- (NSSet *)selectedObjectIds {
    NSMutableSet *results = [[NSMutableSet alloc] init];
    SectionEnumerator *enumerator = [[SectionEnumerator alloc] initWithManagedDocumentQuery:[[AppDelegate activeDocument] document]];
    for (RptqDocumentSection *documentSection in enumerator) {
        UIView *subview = [[self designScrollView] viewWithTag:[[documentSection identifier] integerValue]];
        if ([subview isKindOfClass:[UICollectionView class]]) {
            UICollectionView *collectionView = (UICollectionView *)subview;
            NSArray *selectedObjects = [[self selectedObjectIdsInCollectionView:collectionView] allObjects];
            [results addObjectsFromArray: selectedObjects];
        }
    }
    NSLog(@"Selected Object Ids %@", results);
    return [results autorelease];
}

/*
 
 - (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 
 - (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
 
 }
 
*/

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    MTElementView *elementView = [self elementViewAtIndexPath:indexPath inCollectionView:collectionView];
    [elementView setSelected:NO];
    [[self tableViewControllerTextLayoutSettings] setSelectedDocumentObjects:[self selectedObjectIds]];
    MTLog(@"Deselect");
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    MTElementView *elementView = [self elementViewAtIndexPath:indexPath inCollectionView:collectionView];
    [elementView setHighlight:YES];
    MTLog(@"Highlight");
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    MTElementView *elementView = [self elementViewAtIndexPath:indexPath inCollectionView:collectionView];
    [elementView setSelected:YES];
    [[self tableViewControllerTextLayoutSettings] setSelectedDocumentObjects:[self selectedObjectIds]];
    MTLog(@"Select");
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    MTElementView *elementView = [self elementViewAtIndexPath:indexPath inCollectionView:collectionView];
    [elementView setHighlight:NO];
    MTLog(@"Unhighlight");
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    MTElementView *elementView = [self elementViewAtIndexPath:indexPath inCollectionView:collectionView];
    MTLog(@"Should deselect?\t%@", [elementView isSelected] ? @"YES" : @"NO");
    return [elementView isSelected];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    MTElementView *elementView = [self elementViewAtIndexPath:indexPath inCollectionView:collectionView];
    MTLog(@"Should highlight?\t%@", ![elementView highlight] ? @"YES" : @"NO");
    return ![elementView highlight];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    MTElementView *elementView = [self elementViewAtIndexPath:indexPath inCollectionView:collectionView];
    MTLog(@"Should select?\t%@", ![elementView isSelected] ? @"YES" : @"NO");
    return ![elementView isSelected];
}



- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    //NSLog(@"Can Perform Action %@?  %@", NSStringFromSelector(action), [self respondsToSelector:action] ? @"YES" : @"NO");
    return [self respondsToSelector:action];
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    
    NSInteger row = [indexPath row];
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[collectionView objectIdTag] fromObjectContext:managedObjectContext];
    NSOrderedSet *objects = [documentSection hasObjects];

    if ([objects count] > row) {
        RptqDocumentObject *documentObject = [objects objectAtIndex:row];
        [self performSelector:action withObject:documentObject];
    }
    
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

#pragma mark - Delegates

#pragma mark MUIViewControllerDelegate

- (void)viewControllerDidFinish:(id)sender {
    if ([sender isKindOfClass:[UITableViewControllerSettings class]]) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            [self dismissViewControllerAnimated:YES completion:^{
                
            }];
        } else {
            [[self settingsPopoverController] dismissPopoverAnimated:YES];
            [self setSettingsPopoverController: nil];
        }
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
}

- (void)didSelectDataField:(RptqField *)field {

    [self dismissViewControllerAnimated:YES completion:^{
        
    }];

    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];

    if (document) {
        
        
        UICollectionView *detailSection = [self getCollectionViewForRptqSection:[document hasDetailSection]];
        
        [detailSection performBatchUpdates:^{
            
            RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
            
            RptqDocumentObject *documentObject = [RptqDocumentObjectLabelDataField addNewLabelDataFeildForField:field
                                                 toDetailSectionOfDocument:document
                                                  withManagedObjectContext:managedObjectContext];
            
            // MARK: Get a permanent id on insert.  Who gives a fuck if it's slow on insert.  Let's make sure it's correct.
            if ([[documentObject objectID] isTemporaryID]) {
                NSError *error = nil;
                [managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject: documentObject] error:&error];
                if (error != nil) {
                    error = nil;
                    [managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject: documentObject] error:&error];
                    if (error != nil) {
                        [error presentErrorToUser];
                    }
                }
            }
            
            NSArray *indexPaths = [NSArray arrayWithObject: [NSIndexPath indexPathForItem:0 inSection:0]];
            [[AppDelegate activeDocument] saveContext];
            
            [detailSection insertItemsAtIndexPaths:indexPaths];
         
        } completion:^(BOOL finished) {

        }];
    }
}


- (void)labelInformationViewControllerDidFinish:(UIViewControllerToolbox *)controller {
    
    [UIView animateWithDuration: MNSAnimationDurationShowFromBottomHalf
                     animations: ^{
                         [[self designScrollView] setFrame:[self designScrollViewNormal]];
                         [[[self toolbox] view] setFrame: [self toolboxOffScreen]];
                     } completion:^(BOOL finished) {
                         [[[self toolbox] view] removeFromSuperview];
                         [[self informationButton] setEnabled: YES];
                     }];
}

#pragma mark - Gesture Recognizers

- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        UIView *piece = gestureRecognizer.view;
        CGPoint locationInView = [gestureRecognizer locationInView:piece];
        CGPoint locationInSuperview = [gestureRecognizer locationInView:piece.superview];
        
        piece.layer.anchorPoint = CGPointMake(locationInView.x / piece.bounds.size.width, locationInView.y / piece.bounds.size.height);
        piece.center = locationInSuperview;
    }
}

#pragma mark - Gesture Recognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

- (void)panPiece:(UIPanGestureRecognizer *)gestureRecognizer {
    
    [self adjustAnchorPointForGestureRecognizer:gestureRecognizer];
    
    switch ([gestureRecognizer state]) {
            
            // MARK: UIPanGestureRecognizer UIGestureRecognizerStateBegan
        case UIGestureRecognizerStateBegan: {
            
            CGPoint newCenter = [gestureRecognizer locationInView:[self designScrollView]];
            [[gestureRecognizer view] setCenter: newCenter];
            
            [[self designScrollView] bringSubviewToFront: [gestureRecognizer view]];
            newCenter = [gestureRecognizer locationInView:[self designScrollView]];
            [self setScrollersEnabled: NO];
            
            [[gestureRecognizer view] setCenter: newCenter];
            [[self designScrollView] addSubview: [gestureRecognizer view]];
            
            
            {
                NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
                RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:[[gestureRecognizer view] objectIdTag] fromObjectContext:managedObjectContext];
                RptqDocumentObjectLabelDataField *datafield = [documentObject isLabelDataField];
                NSLog(@"OBJTag %@", [[gestureRecognizer view] objectIdTag]);
                NSLog(@"dataSe %@", [datafield parentObjectLabelDataField]);
                if (datafield) {
                    
                    RptqDocumentSection *section = [[datafield parentObjectLabelDataField] inSection];
                    __block UICollectionView *svSection = [self getCollectionViewForRptqSection:section];
                    
                    
                    
                    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[svSection objectIdTag] fromObjectContext:managedObjectContext];
                    
                    NSMutableOrderedSet *hasObjects = [[NSMutableOrderedSet alloc] initWithOrderedSet: [documentSection hasObjects]];
                    NSUInteger deleteIndex = 0;
                    
                    BOOL found = NO;
                    for (RptqDocumentObject *object in hasObjects) {
                        if ([[object objectID] isEqual: [[gestureRecognizer view] objectIdTag]]) {
                            found = YES;
                            break;
                        }
                        deleteIndex++;
                    }
                    if (found) {
                        [svSection performBatchUpdates:^{
                            [hasObjects removeObjectAtIndex:deleteIndex];
                            [documentSection setHasObjects:hasObjects];
                            
                            [[AppDelegate activeDocument] saveContext];
                            
                            
                            NSIndexPath *deletePath = [NSIndexPath indexPathForItem: deleteIndex inSection: 0];
                            NSLog(@"Delete %@", deletePath);
                            [svSection deleteItemsAtIndexPaths: [NSArray arrayWithObject:deletePath]];
                            
                        } completion:^(BOOL finished) {
                            
                        }];
                    }
                }
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {     // MARK: UIPanGestureRecognizer UIGestureRecognizerStateChanged
            CGPoint newCenter = [gestureRecognizer locationInView:[self designScrollView]];
            [[gestureRecognizer view] setCenter: newCenter];
            break;
        }
        case UIGestureRecognizerStatePossible: {    // MARK: UIPanGestureRecognizer UIGestureRecognizerStatePossible
            break;
        }
        case UIGestureRecognizerStateCancelled:     // MARK: UIPanGestureRecognizer UIGestureRecognizerStateCancelled
        case UIGestureRecognizerStateFailed:        // MARK: UIPanGestureRecognizer UIGestureRecognizerStateFailed
        case UIGestureRecognizerStateEnded: {       // MARK: UIPanGestureRecognizer UIGestureRecognizerStateEnded
            
            
            // MARK: Remove the element from one section and place it into the next new section
            
            CGPoint newCenter = [gestureRecognizer locationInView:[self designScrollView]];
            __block UICollectionView *newParent = nil;
            
            // MARK: Try to find the section to place the element view into.
            BOOL addedToNewParent = NO;
            for (UICollectionView *view in [[self designScrollView] subviews]) {
                if (CGRectContainsPoint([view frame], [[gestureRecognizer view] center]) && ![view isEqual:self]) {
                    if ([view isKindOfClass:[UICollectionView class]]) {
                        newParent = [[view retain] autorelease];
                        addedToNewParent = YES;
                        newCenter = [gestureRecognizer locationInView:newParent];
                        [[gestureRecognizer view] setCenter: newCenter];
                        break;
                    }
                }
            }
            if (!addedToNewParent) {
                for (UICollectionView *view in [[self designScrollView] subviews]) {
                    if ([view isKindOfClass: [UICollectionView class]]) {
                        newParent = [[view retain] autorelease];
                        addedToNewParent = YES;
                        newCenter = CGPointMake([gestureRecognizer view].frame.size.width / 2.0000f, [gestureRecognizer view].frame.size.height / 2.0000f);
                        [[gestureRecognizer view] setCenter: newCenter];
                        break;
                    }
                }
            }
            
            
            
            if (addedToNewParent) {
                newCenter = CGPointRoundPointToGrid(newCenter);
                [[gestureRecognizer view] setCenter: newCenter];
                
                
                NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
                
                RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:[[gestureRecognizer view] objectIdTag]
                                                                             fromObjectContext:managedObjectContext];
                
                RptqDocumentObjectLabelDataField *datafield = [documentObject isLabelDataField];
                
                if (datafield) {
                    
                    documentObject.originx = @([gestureRecognizer view].frame.origin.x);
                    documentObject.originy = @([gestureRecognizer view].frame.origin.y);
                    documentObject.sizewidth = @([gestureRecognizer view].frame.size.width);
                    documentObject.sizeheight = @([gestureRecognizer view].frame.size.height);
                    
                    CGPoint newCenter = [[gestureRecognizer view] center];
                    [[gestureRecognizer view] removeFromSuperview];
                    
                    RptqDocumentSection *documentSection = [RptqDocumentSection getDocumentSectionForObjectID:[newParent objectIdTag]
                                                                                            fromObjectContext:managedObjectContext];
                    NSIndexPath *indexPath = [newParent indexPathForItemAtPoint:newCenter];
                    if (indexPath == nil) {
                        indexPath = [newParent indexOfAlienViewWithCenterPoint:newCenter];
                        if (indexPath == nil) {
                            indexPath = [NSIndexPath indexPathForItem:[newParent numberOfItemsInSection: 0] inSection:0];
                        }
                    }
                    
                    NSArray *indexPaths = [NSArray arrayWithObject: indexPath];
                    
                    // MARK: Add this to the data context and to the container for the sections collection view.
                    [newParent performBatchUpdates:^{
                        NSMutableOrderedSet *hasObjects = [[NSMutableOrderedSet alloc] initWithOrderedSet:[documentSection hasObjects]];
                        [hasObjects insertObject:documentObject atIndex:[indexPath item]];
                        [documentSection setHasObjects:hasObjects];
                        [[AppDelegate activeDocument] saveContext];
                        
                        [newParent insertItemsAtIndexPaths:indexPaths];
                        
                    } completion:^(BOOL finished) {
                    }];
                    
                }
                
            }
            [self setScrollersEnabled:YES];
            [[gestureRecognizer view] setNeedsDisplay];
            break;
        }
        default:
            break;
    }
}

- (void)setScrollersEnabled:(BOOL)enabled {
    @synchronized([self designScrollView]) {
        if ([[self designScrollView] respondsToSelector:@selector(setScrollEnabled:)]) {
            [[self designScrollView] setScrollEnabled:enabled];
            [[self designScrollView] flashScrollIndicators];
            for (UICollectionView *collectionView in [[self designScrollView] subviews]) {
                if ([collectionView isKindOfClass: [UICollectionView class]]) {
                    [collectionView setScrollEnabled:enabled];
                    [collectionView flashScrollIndicators];
                }
            }
        }
    }
}

- (void)viewDidUnload {
    [self setToolbarBottom:nil];
    [self setToolbarTop:nil];
    [self setToolboxView:nil];
    [self setToolboxContainerView:nil];
    [self setNavigationBarToolbox:nil];
    [super viewDidUnload];
}

#pragma mark - UINavigationBarDelegate

- (void)navigationBar:(UINavigationBar *)navigationBar didPopItem:(UINavigationItem *)item {

    if ([item isEqual:[self navigationItemFontChooser]]) {
    } else if ([item isEqual:[self navigationItemLayout]]) {
    } else if ([item isEqual:[self navigationItemStyle]]) {
    }
    
}

- (void)navigationBar:(UINavigationBar *)navigationBar didPushItem:(UINavigationItem *)item {

}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {
    BOOL shouldPopItem = NO;

    if ([item isEqual:[self navigationItemFontChooser]]) {
        shouldPopItem = YES;
        
        CGRect offScreen = CGRectMake([[[self tableViewControllerFontSelector] tableView] frame].origin.x + [[[self tableViewControllerFontSelector] tableView] frame].size.width, [[[self tableViewControllerFontSelector] tableView] frame].origin.y,
                                      [[[self tableViewControllerFontSelector] tableView] frame].size.width, [[[self tableViewControllerFontSelector] tableView] frame].size.height);
        
        [[[self tableViewControllerFontSelector] tableView] setFrame: [[self toolboxContainerView] bounds]];
        
        
        [UIView animateWithDuration:0.3000f animations:^{
            [[[self tableViewControllerFontSelector] tableView] setFrame: offScreen];
        } completion:^(BOOL finished) {
            [[[self tableViewControllerFontSelector] tableView] removeFromSuperview];
        }];
    } else if ([item isEqual:[self navigationItemLayout]]) {

    } else if ([item isEqual:[self navigationItemStyle]]) {
    
    }
    
    return shouldPopItem;
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPushItem:(UINavigationItem *)item {
    BOOL shouldPushItem = NO;
    
    if ([item isEqual:[self navigationItemFontChooser]]) {
        shouldPushItem = YES;
        
        [[[self tableViewControllerFontSelector] tableView] setFrame: [[self toolboxContainerView] bounds]];
        [[[self tableViewControllerFontSelector] tableView] setBounds: [[self toolboxContainerView] bounds]];
        CGRect newRect = [[[self tableViewControllerFontSelector] tableView] frame];
        CGRect newRectOffscreen = CGRectMake(CGPointZero.x + [[self toolboxContainerView] bounds].size.width, [[[self tableViewControllerFontSelector] tableView] frame].origin.y, [[[self tableViewControllerFontSelector] tableView] frame].size.width, [[[self tableViewControllerFontSelector] tableView] frame].size.height);
        
        [[[self tableViewControllerFontSelector] tableView] setFrame: newRectOffscreen];
        [[self toolboxContainerView] addSubview:[[self tableViewControllerFontSelector] tableView]];

        
        [UIView animateWithDuration:0.3000f animations:^{
            [[[self tableViewControllerFontSelector] tableView] setFrame:newRect];
        } completion:^(BOOL finished) {
            
        }];
    } else if ([item isEqual:[self navigationItemLayout]]) {
    } else if ([item isEqual:[self navigationItemStyle]]) {
    }
    return shouldPushItem;
}

@end