//
//  IKConnectionDelegate.h
//  IKConnectionDelegate
//
//  Created by Ilya Kulakov on 11.08.10.
//  Copyright 2010. All rights reserved.

#import <Foundation/Foundation.h>


/*
 @param loadedDataLength Length of data that is already loaded.
 @param maximumLength The expected length of data. 
 @discussion For download progress can return NSURLResponseUnknownLength if the length cannot be determined. 
 For upload progress maximumLength may change during the upload if the request needs to be retransmitted due to a lost connection or an authentication challenge from the server.
 */
typedef void (^IKConnectionProgressBlock)(NSUInteger loadedDataLength, NSUInteger maximumLength);

/*
 @param data Downloaded data.
 @param response The URL response for the connection's request.
 @param error An error object containing details of why the connection failed to load the request successfully. nil if no error is occured.
 */
typedef void (^IKConnectionCompletionBlock)(NSData *data, NSURLResponse *response, NSError *error);

@interface IKConnectionDelegate : NSObject {
    IKConnectionProgressBlock downloadProgress;
    IKConnectionProgressBlock uploadProgress;
    IKConnectionCompletionBlock completion;
    dispatch_queue_t queue;
    NSMutableData *data;
    NSURLResponse *response;
    BOOL isFinished;
@private
    NSURLConnection *_connection;
}

/*
 @abstract Executes a given block after connection downloads data incrementally.
 */
@property (copy, readonly) IKConnectionProgressBlock downloadProgress;
/*
 @abstract Executes a given block after connection uploads data incrementally.
 */
@property (copy, readonly) IKConnectionProgressBlock uploadProgress;
/*
 @abstract Executes a given block after connection has finished loading or failed to load its request successfully.
 */
@property (copy, readonly) IKConnectionCompletionBlock completion;
/*
 @abstract Downloaded data.
 */
@property (retain, readonly) NSMutableData *data;
/*
 @abstract Response for the connection.
 */
@property (retain, readonly) NSURLResponse *response;
/*
 @abstract Returns a Boolean value indicating whether the operation is done downloading/uploading. Observable.
 */
@property (assign, readonly) BOOL isFinished;

/*
 @abstract Creates and returns an autoreleased IKConnectionDelegate object.
 @param aDownloadProgress Executes a given block after connection downloads data incrementally.
 @param anUploadProgress Executes a given block after connection uploads data incrementally.
 @param aCompletion Executes a given block after connection has finished loading or failed to load its request successfully.
 @discussion Copies given blocks.
 */
+ (IKConnectionDelegate *)connectionDelegateWithDownloadProgress:(IKConnectionProgressBlock)aDownloadProgress
                                                  uploadProgress:(IKConnectionProgressBlock)anUploadProgress
                                                      completion:(IKConnectionCompletionBlock)aCompletion;

/*
 @abstract Designated Initializer.
 @param aDownloadProgress Executes a given block after connection downloads data incrementally.
 @param anUploadProgress Executes a given block after connection uploads data incrementally.
 @param aCompletion Executes a given block after connection has finished loading or failed to load its request successfully.
 @discussion Copies given blocks.
 */
- (IKConnectionDelegate *)initWithDownloadProgress:(IKConnectionProgressBlock)aDownloadProgress
                                    uploadProgress:(IKConnectionProgressBlock)anUploadProgress
                                        completion:(IKConnectionCompletionBlock)aCompletion;

@end
