//
//  MADFilesController.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MADFilesController, MADFileInfo;
@protocol MADListCoordinator;

/*!
 * The \c AAPLListsControllerDelegate protocol enables an \c AAPLListsController object to notify other
 * objects of changes to available \c MADFileInfo objects. This includes "will change content" events,
 * "did change content" events, inserts, removes, updates, and errors. Note that the \c AAPLListsController
 * can call these methods on an aribitrary queue. If the implementation in these methods require UI
 * manipulations, you should respond to the changes on the main queue.
 */
@protocol MADFilesControllerDelegate <NSObject>

@optional

/*!
 * Notifies the receiver of this method that the lists controller will change it's contents in some
 * form. This method is *always* called before any insert, remove, or update is received. In this method,
 * you should prepare your UI for making any changes related to the changes that you will need to reflect
 * once they are received. For example, if you have a table view in your UI that needs to respond to
 * changes to a newly inserted \c MADFileInfo object, you would want to call your table view's
 * \c -beginUpdates method. Once all of the updates are performed, your \c -listsControllerDidChangeContent:
 * method will be called. This is where you would to call your table view's \c -endUpdates method.
 *
 * @param listsController The \c AAPLListsController instance that will change its content.
 */
- (void)listsControllerWillChangeContent:(MADFilesController *)listsController;

/*!
 * Notifies the receiver of this method that the lists controller is tracking a new \c MADFileInfo
 * object. Receivers of this method should update their UI accordingly.
 *
 * @param listsController The \c AAPLListsController instance that inserted the new \c MADFileInfo.
 * @param listInfo The new \c MADFileInfo object that has been inserted at \c index.
 * @param index The index that \c listInfo was inserted at.
 */
- (void)listsController:(MADFilesController *)listsController didInsertListInfo:(MADFileInfo *)listInfo atIndex:(NSInteger)index;

/*!
 * Notifies the receiver of this method that the lists controller is no longer tracking \c listInfo.
 * Receivers of this method should update their UI accordingly.
 *
 * @param listsController The \c AAPLListsController instance that removed \c listInfo.
 * @param listInfo The removed \c MADFileInfo object.
 * @param index The index that \c listInfo was removed at.
 */
- (void)listsController:(MADFilesController *)listsController didRemoveListInfo:(MADFileInfo *)listInfo atIndex:(NSInteger)index;

/*!
 * Notifies the receiver of this method that the lists controller received a message that \c listInfo
 * has updated its content. Receivers of this method should update their UI accordingly.
 *
 * @param listsController The \c AAPLListsController instance that was notified that \c listInfo has
 *                       been updated.
 * @param listInfo The \c MADFileInfo object that has been updated.
 * @param index The index of \c listInfo, the updated \c MADFileInfo.
 */
- (void)listsController:(MADFilesController *)listsController didUpdateListInfo:(MADFileInfo *)listInfo atIndex:(NSInteger)index;

/*!
 * Notifies the receiver of this method that the lists controller did change it's contents in some form.
 * This method is *always* called after any insert, remove, or update is received. In this method, you
 * should finish off changes to your UI that were related to any insert, remove, or update. For an example
 * of how you might handle a "did change" contents call, see the discussion for \c -listsControllerWillChangeContent:.
 *
 * @param listsController The \c AAPLListsController instance that did change its content.
 */
- (void)listsControllerDidChangeContent:(MADFilesController *)listsController;

/*!
 * Notifies the receiver of this method that an error occured when creating a new \c MADFileInfo object.
 * In implementing this method, you should present the error to the user. Do not rely on the \c MADFileInfo
 * instance to be valid since an error occured in creating the object.
 *
 * @param listsController The \c AAPLListsController that is notifying that a failure occured.
 * @param listInfo The \c MADFileInfo that represents the list that couldn't be created.
 * @param error The error that occured.
 */
- (void)listsController:(MADFilesController *)listsController didFailCreatingListInfo:(MADFileInfo *)listInfo withError:(NSError *)error;

/*!
 * Notifies the receiver of this method that an error occured when removing an existing \c MADFileInfo
 * object. In implementing this method, you should present the error to the user.
 *
 * @param listsController The \c AAPLListsController that is notifying that a failure occured.
 * @param listInfo The \c MADFileInfo that represents the list that couldn't be removed.
 * @param error The error that occured.
 */
- (void)listsController:(MADFilesController *)listsController didFailRemovingListInfo:(MADFileInfo *)listInfo withError:(NSError *)error;

@end

@interface MADFilesController : NSObject


/*!
 * Initializes an \c AAPLListsController instance with an initial \c AAPLListCoordinator object and a
 * sort comparator (if any). If sort comparator is nil, the controller ignores sort order.
 *
 * @param listCoordinator The \c AAPLListsController object's initial \c AAPLListCoordinator.
 * @param delegateQueue The queue in which the \c AAPLListsController object invokes delegate messages. If
 \c nil, the main operation queue is used.
 * @param sortComparator The predicate that determines the strict sort ordering of the \c AAPLlistInfos
 *                       array.
 */
- (instancetype)initWithListCoordinator:(id<MADListCoordinator>)listCoordinator delegateQueue:(NSOperationQueue *)delegateQueue sortComparator:(NSComparisonResult (^)(MADFileInfo *lhs, MADFileInfo *rhs))sortComparator;

/*!
 * The \c AAPLListsController object's delegate who is responsible for responding to \c AAPLListsController
 * changes.
 */
@property (nonatomic, weak) id<MADFilesControllerDelegate> delegate;

/*!
 * @return The number of tracked \c MADFileInfo objects.
 */
@property (nonatomic, readonly) NSInteger count;

/*!
 * The current \c AAPLListCoordinator that the lists controller manages.
 */
@property (nonatomic, strong) id<MADListCoordinator> listCoordinator;

/*!
 * Begin listening for changes to the tracked \c MADFileInfo objects. This is managed by the \c listCoordinator
 * object. Be sure to balance each call to \c -startSearching with a call to \c -stopSearching.
 */
- (void)startSearching;

/*!
 * Stop listening for changes to the tracked \c MADFileInfo objects. This is managed by the \c listCoordinator
 * object. Each call to \c -startSearching should be balanced with a call to this method.
 */
- (void)stopSearching;

/*!
 * @return The \c MADFileInfo instance at a specific index. This method traps if the index is out
 *         of bounds.
 */
- (MADFileInfo *)objectAtIndexedSubscript:(NSInteger)index;

/*!
 * Removes \c listInfo from the tracked \c ListInfo instances. This method forwards the remove operation
 * directly to the list coordinator. The operation can be performed asynchronously so long as the
 * underlying \c AAPLListCoordinator instance sends the \c AAPLListsController the correct delegate
 * messages: either a \c -listCoordinatorDidUpdateContentsWithInsertedURLs:removedURLs:updatedURLs:
 * call with the removed \c MADFileInfo object, or with an error callback.
 *
 * @param listInfo The \c MADFileInfo object to remove from the list of tracked \c MADFileInfo
 *                 instances.
 */
- (void)removeListInfo:(MADFileInfo *)listInfo;

/*!
 * Attempts to create \c MADFileInfo representing \c list with the given name. If the method is succesful,
 * the lists controller adds it to the list of tracked \c MADFileInfo instances. This method forwards
 * the create operation directly to the list coordinator. The operation can be performed asynchronously
 * so long as the underlying \c AAPLListCoordinator instance sends the \c AAPLListsController the correct
 * delegate messages: either a \c -listCoordinatorDidUpdateContentsWithInsertedURLs:removedURLs:updatedURLs:
 * call with the newly inserted \c MADFileInfo, or with an error callback.
 *
 * Note: it's important that before calling this method, a call to \c -canCreateListWithName: is
 * performed to make sure that the name is a valid list name. Doing so will decrease the errors that
 * you see when you actually create a list.
 *
 * @param list The \c AAPLList object that should be used to save the initial list.
 * @param name The name of the new list.
 */
- (void)createListInfoForList:(MADFileInfo *)list withName:(NSString *)name;

/*!
 * Determines whether or not a list can be created with a given name. This method delegates to
 * \c listCoordinator to actually check to see if the list can be created with the given name. This
 * method should be called before \c -createListInfoForList:withName: is called to ensure to minimize
 * the number of errors that can occur when creating a list.
 *
 * @param name The name to check to see if it's valid or not.
 *
 * @return \c YES if the list can be created with the given name, \c NO otherwise.
 */
- (BOOL)canCreateListInfoWithName:(NSString *)name;

/*!
 * Lets the \c AAPLListsController know that \c listInfo has been udpdated. Once the change is reflected
 * in \c listInfos array, a didUpdateListInfo message is sent.
 *
 * @param listInfo The \c MADFileInfo instance that has new content.
 */
- (void)setListInfoHasNewContents:(MADFileInfo *)listInfo;

@end
