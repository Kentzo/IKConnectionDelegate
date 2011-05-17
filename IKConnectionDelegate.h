//
//  IKConnectionDelegate.h
//  IKConnectionDelegate
//
//  Created by Ilya Kulakov on 11.08.10.
//  Copyright 2010. All rights reserved.

#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>


typedef enum {
    IKNoneGroupAction = 0,
    IKCancelGroupAction = 0x1,
    IKUndefinedAction = 0xFFFFFFFF
} IKConnectionDelegateGroupAction;


/*!
 @param loadedDataLength    Length of data which is already loaded.
 @param maximumLength       The expected length of data.
 @discussion                For download progress can return NSURLResponseUnknownLength if the length cannot be determined.
                            For upload progress maximumLength may change during the upload if the request needs to be retransmitted due to a lost connection or an authentication challenge from the server.
 */
typedef void (^IKConnectionProgressBlock)(NSUInteger loadedDataLength, long long maximumLength);

/*!
 @param data        Downloaded data.
 @param response    The URL response for the connection's request.
 @param error       An error object containing details of why the connection failed to load the request successfully. nil if no error is occured.
 @discussion        Look up connectionDidFinishLoading: and connection:didFailWithError: in the Apple documentation.
 */
typedef void (^IKConnectionCompletionBlock)(NSData *data, NSURLResponse *response, NSError *error);

/*!
 @param connection  The connection sending the message.
 @param challenge   The challenge that connection must authenticate in order to download its request.
 @discussion        Look up connection:didReceiveAuthenticationChallenge: in the Apple documentation.
 */
typedef void (^IKAuthenticationChallengerBlock)(NSURLConnection *connection, NSURLAuthenticationChallenge *challenge);

/*!
 @discussion You can use aGroup to specify dispatch group for blocks. That could be useful if you need to be notified when all connections are done.
 */
@interface IKConnectionDelegate : NSObject {
    IKConnectionProgressBlock downloadProgress;
    IKConnectionProgressBlock uploadProgress;
    IKConnectionCompletionBlock completion;
    IKAuthenticationChallengerBlock challenger;
    NSMutableData *data;
    NSURLResponse *response;
    BOOL isFinished;
    NSURLConnection *_connection;
    dispatch_group_t _group;
    dispatch_queue_t _groupQueue;
}

/*!
 @abstract Executes a given block after connection downloads data incrementally.
 */
@property (copy, readonly) IKConnectionProgressBlock downloadProgress;

/*!
 @abstract Executes a given block after connection uploads data incrementally.
 */
@property (copy, readonly) IKConnectionProgressBlock uploadProgress;

/*!
 @abstract Executes a given block after connection has finished loading or failed to load its request successfully.
 */
@property (copy, readonly) IKConnectionCompletionBlock completion;

/*!
 @abstract Executes a given block when a connection must authenticate a challenge in order to download its request.
 */
@property (copy, readonly) IKAuthenticationChallengerBlock challenger;

/*!
 @abstract Downloaded data.
 */
@property (retain, readonly) NSMutableData *data;

/*!
 @abstract Response for the connection.
 */
@property (retain, readonly) NSURLResponse *response;

/*!
 @abstract Returns a Boolean value indicating whether the operation is done downloading/uploading. Observable.
 */
@property (assign, readonly) BOOL isFinished;

/*!
 @abstract                  Creates and returns an autoreleased IKConnectionDelegate object.
 @param aDownloadProgress   Executes a given block after connection downloads data incrementally.
 @param anUploadProgress    Executes a given block after connection uploads data incrementally.
 @param aCompletion         Executes a given block after connection has finished loading or failed to load its request successfully.
 @param aChallenger         Executes a given block when a connection must authenticate a challenge in order to download its request.
 @param aGroup              A GCD group to execute blocks. May be NULL.
 @param aGroupQueue         A GCD queue to execute blocks if aGroup isn't NULL. May be NULL.
 @discussion                Copies given blocks. Retains given group and group's queue.

                            Delegate explicity enters to the group (using dispatch_group_enter) when it's initialized and explicity leaves the group (using dispatch_group_leave) when it's deallocated.
                            If aGroupQueue is NULL main queue is used.
 */
+ (IKConnectionDelegate *)connectionDelegateWithDownloadProgress:(IKConnectionProgressBlock)aDownloadProgress
                                                  uploadProgress:(IKConnectionProgressBlock)anUploadProgress
                                                      completion:(IKConnectionCompletionBlock)aCompletion
                                                      challenger:(IKAuthenticationChallengerBlock)aChallenger
                                                           group:(dispatch_group_t)aGroup
                                                      groupQueue:(dispatch_queue_t)aGroupQueue;

/*!
 @abstract                  Creates and returns an autoreleased IKConnectionDelegate object.
 @param aDownloadProgress   Executes a given block after connection downloads data incrementally.
 @param anUploadProgress    Executes a given block after connection uploads data incrementally.
 @param aCompletion         Executes a given block after connection has finished loading or failed to load its request successfully.
 @param aChallenger         Executes a given block when a connection must authenticate a challenge in order to download its request.
 @discussion                Copies given blocks.
 */
+ (IKConnectionDelegate *)connectionDelegateWithDownloadProgress:(IKConnectionProgressBlock)aDownloadProgress
                                                  uploadProgress:(IKConnectionProgressBlock)anUploadProgress
                                                      completion:(IKConnectionCompletionBlock)aCompletion
                                                      challenger:(IKAuthenticationChallengerBlock)aChallenger;

/*!
 @abstract                  Designated Initializer.
 @param aDownloadProgress   Executes a given block after connection downloads data incrementally.
 @param anUploadProgress    Executes a given block after connection uploads data incrementally.
 @param aCompletion         Executes a given block after connection has finished loading or failed to load its request successfully.
 @param aChallenger         Executes a given block when a connection must authenticate a challenge in order to download its request.
 @param aGroup              A GCD group to execute blocks. May be NULL.
 @param aGroupQueue         A GCD queue to execute blocks if aGroup isn't NULL. May be NULL.
 @discussion                Copies given blocks. Retains given group and group's queue.

                            Delegate explicity enters to the group (using dispatch_group_enter) when it's initialized and explicity leaves the group (using dispatch_group_leave) when it's deallocated.
                            If aGroupQueue is NULL main queue is used.
 */
- (IKConnectionDelegate *)initWithDownloadProgress:(IKConnectionProgressBlock)aDownloadProgress
                                    uploadProgress:(IKConnectionProgressBlock)anUploadProgress
                                        completion:(IKConnectionCompletionBlock)aCompletion
                                        challenger:(IKAuthenticationChallengerBlock)aChallenger
                                             group:(dispatch_group_t)aGroup
                                        groupQueue:(dispatch_queue_t)aGroupQueue;

/*!
 @param aDownloadProgress   Executes a given block after connection downloads data incrementally.
 @param anUploadProgress    Executes a given block after connection uploads data incrementally.
 @param aCompletion         Executes a given block after connection has finished loading or failed to load its request successfully.
 @param aChallenger         Executes a given block when a connection must authenticate a challenge in order to download its request.
 @discussion                Copies given blocks.
 */
- (IKConnectionDelegate *)initWithDownloadProgress:(IKConnectionProgressBlock)aDownloadProgress
                                    uploadProgress:(IKConnectionProgressBlock)anUploadProgress
                                        completion:(IKConnectionCompletionBlock)aCompletion
                                        challenger:(IKAuthenticationChallengerBlock)aChallenger;
/*!
 @abstract      Makes all IKConnectionDelegate instances that belong to a given group do a given action.
 @discussions   Do an action only when one of the NSURLConnection delegate methods is called. You can set only one action for a group. Action is essentially a context of a group.
 */
+ (void)setAction:(IKConnectionDelegateGroupAction)aGroupAction forGroup:(dispatch_group_t)aGroup;

/*!
 @abstract  Returns current action for a given group
 */
+ (IKConnectionDelegateGroupAction)actionForGroup:(dispatch_group_t)aGroup;

@end
