//
//  IKConnectionDelegate.m
//  IKConnectionDelegate
//
//  Created by Ilya Kulakov on 11.08.10.
//  Copyright 2010. All rights reserved.

#import "IKConnectionDelegate.h"


@interface IKConnectionDelegate (/* Private */)

@property (copy) IKConnectionProgressBlock downloadProgress;
@property (copy) IKConnectionProgressBlock uploadProgress;
@property (copy) IKConnectionCompletionBlock completion;
@property (copy) IKAuthenticationChallengerBlock challenger;
@property (retain) NSMutableData *data;
@property (retain) NSURLResponse *response;
@property (assign) BOOL isFinished;
@property (retain) NSURLConnection *_connection;

- (void)_doActionWithConnection:(NSURLConnection *)aConnection;

/*!
 @result YES if current execution should be interrupted. Otherwise NO.
 */
- (BOOL)_shouldBreak;

@end

@implementation IKConnectionDelegate
@synthesize downloadProgress;
@synthesize uploadProgress;
@synthesize completion;
@synthesize challenger;
@synthesize data;
@synthesize response;
@synthesize isFinished;
@synthesize _connection;

+ (IKConnectionDelegate *)connectionDelegateWithDownloadProgress:(IKConnectionProgressBlock)aDownloadProgress
                                                  uploadProgress:(IKConnectionProgressBlock)anUploadProgress
                                                      completion:(IKConnectionCompletionBlock)aCompletion
                                                      challenger:(IKAuthenticationChallengerBlock)aChallenger
                                                           group:(dispatch_group_t)aGroup
                                                      groupQueue:(dispatch_queue_t)aGroupQueue
{
    return [[[self alloc] initWithDownloadProgress:aDownloadProgress uploadProgress:anUploadProgress completion:aCompletion challenger:aChallenger group:aGroup groupQueue:aGroupQueue] autorelease];
}


+ (IKConnectionDelegate *)connectionDelegateWithDownloadProgress:(IKConnectionProgressBlock)aDownloadProgress
                                                  uploadProgress:(IKConnectionProgressBlock)anUploadProgress
                                                      completion:(IKConnectionCompletionBlock)aCompletion
                                                      challenger:(IKAuthenticationChallengerBlock)aChallenger
{
    return [self connectionDelegateWithDownloadProgress:aDownloadProgress
                                         uploadProgress:anUploadProgress
                                             completion:aCompletion
                                             challenger:aChallenger
                                                  group:NULL
                                             groupQueue:NULL];
}


- (IKConnectionDelegate *)initWithDownloadProgress:(IKConnectionProgressBlock)aDownloadProgress
                                    uploadProgress:(IKConnectionProgressBlock)anUploadProgress
                                        completion:(IKConnectionCompletionBlock)aCompletion
                                        challenger:(IKAuthenticationChallengerBlock)aChallenger
                                             group:(dispatch_group_t)aGroup
                                        groupQueue:(dispatch_queue_t)aGroupQueue
{
    if ((self = [super init])) {
        self.downloadProgress = aDownloadProgress;
        self.uploadProgress = anUploadProgress;
        self.completion = aCompletion;
        self.challenger = aChallenger;
        _group = aGroup;
        if (_group != NULL) {
            dispatch_retain(_group);
            dispatch_group_enter(_group);
            _groupQueue = aGroupQueue;
            if (_groupQueue == NULL) {
                _groupQueue = dispatch_get_main_queue();
            }
            dispatch_retain(_groupQueue);
            dispatch_set_context(_group, (void *)IKNoneGroupAction);
        }
        data = [NSMutableData new];
    }
    return self;
}


- (IKConnectionDelegate *)initWithDownloadProgress:(IKConnectionProgressBlock)aDownloadProgress
                                    uploadProgress:(IKConnectionProgressBlock)anUploadProgress
                                        completion:(IKConnectionCompletionBlock)aCompletion
                                        challenger:(IKAuthenticationChallengerBlock)aChallenger
{
    return [self initWithDownloadProgress:aDownloadProgress
                           uploadProgress:anUploadProgress
                               completion:aCompletion
                               challenger:aChallenger
                                    group:NULL
                               groupQueue:NULL];
}


- (void)dealloc {
    [downloadProgress release];
    [uploadProgress release];
    [completion release];
    [challenger release];
    [data release];
    [response release];
    if (_group != NULL) {
        dispatch_group_leave(_group);
        dispatch_release(_group);
        dispatch_release(_groupQueue);
    }
    [super dealloc];
}


#pragma mark NSURLConnection delegate methods

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
    [self _doActionWithConnection:connection];
    if (![self _shouldBreak]) {
        return request;
    }
    else {
        return nil;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)aResponse {
    NSAssert(_connection == nil || _connection == connection, @"You cannot use an IKConnectionDelegate instance more than once");
    [self _doActionWithConnection:connection];
    if ([self _shouldBreak]) {
        return;
    }

    if (_connection == nil) {
        _connection = connection;
    }

    self.response = aResponse;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)aData {
    [self _doActionWithConnection:connection];
    if ([self _shouldBreak]) {
        return;
    }

    [data appendData:aData];
    if (downloadProgress != nil) {
        if (_group != NULL) {
            dispatch_group_async(_group, _groupQueue, ^{
                if (![self _shouldBreak]) {
                    downloadProgress([data length], [response expectedContentLength]);
                }
            });
        }
        else {
            downloadProgress([data length], [response expectedContentLength]);
        }
    }
}


- (void)connection:(NSURLConnection *)connection
   didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    [self _doActionWithConnection:connection];
    if ([self _shouldBreak]) {
        return;
    }

    if (uploadProgress != nil) {
        if (_group != NULL) {
            dispatch_group_async(_group, _groupQueue, ^{
                if (![self _shouldBreak]) {
                    uploadProgress(totalBytesWritten, totalBytesExpectedToWrite);
                }
            });
        }
        else {
            uploadProgress(totalBytesWritten, totalBytesExpectedToWrite);
        }
    }
}


- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSAssert(_connection == nil || _connection == connection, @"You cannot use an IKConnectionDelegate instance more than once");
    [self _doActionWithConnection:connection];
    if ([self _shouldBreak]) {
        return;
    }

    if (challenger != nil) {
        if (_group != NULL) {
            dispatch_group_async(_group, _groupQueue, ^{
                if (![self _shouldBreak]) {
                    challenger(connection, challenge);
                }
            });
        }
        else {
            challenger(connection, challenge);
        }
    }
    else {
        if ([challenge previousFailureCount] > 0) {
            [[challenge sender] cancelAuthenticationChallenge:challenge];
        }
        else {
            [[challenge sender] useCredential:[challenge proposedCredential] forAuthenticationChallenge:challenge];
        }
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    self.isFinished = YES;
    [self _doActionWithConnection:connection];
    if ([self _shouldBreak]) {
        return;
    }

    if (completion != nil) {
        if (_group != NULL) {
            dispatch_group_async(_group, _groupQueue, ^{
                if (![self _shouldBreak]) {
                    completion(data, response, nil);
                }
            });
        }
        else {
            completion(data, response, nil);
        }
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)anError {
    self.isFinished = YES;
    [self _doActionWithConnection:connection];
    if ([self _shouldBreak]) {
        return;
    }

    if (completion != nil) {
        if (_group != NULL) {
            dispatch_group_async(_group, _groupQueue, ^{
                if (![self _shouldBreak]) {
                    completion(data, response, anError);
                }
            });
        }
        else {
            completion(data, response, anError);
        }
    }
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    [self _doActionWithConnection:connection];
    if ([self _shouldBreak]) {
        return nil;
    }

    return cachedResponse;
}

+ (void)setAction:(IKConnectionDelegateGroupAction)aGroupAction forGroup:(dispatch_group_t)aGroup {
    NSAssert(aGroup != NULL, @"You must set group to be able to call this method");
    NSAssert(dispatch_get_context(aGroup) == NULL || (IKConnectionDelegateGroupAction)dispatch_get_context(aGroup) == aGroupAction, @"You cannot set more than one action for a group");
    dispatch_set_context(aGroup, (void *)aGroupAction);
}

+ (IKConnectionDelegateGroupAction)actionForGroup:(dispatch_group_t)aGroup {
    int action = (int)dispatch_get_context(aGroup);
    switch (action) {
        case IKNoneGroupAction:
            return IKNoneGroupAction;
        case IKCancelGroupAction:
            return IKCancelGroupAction;
        default:
            return IKUndefinedAction;
    }
}

- (void)_doActionWithConnection:(NSURLConnection *)aConnection {
    if (_group != NULL) {
        IKConnectionDelegateGroupAction action = (IKConnectionDelegateGroupAction)dispatch_get_context(_group);
        switch (action) {
            case IKNoneGroupAction:
                break;
            case IKCancelGroupAction:
                [aConnection cancel];
                break;
            default:
                break;
        }
    }
}

- (BOOL)_shouldBreak {
    if (_group != NULL) {
        IKConnectionDelegateGroupAction action = [IKConnectionDelegate actionForGroup:_group];
        switch (action) {
            case IKNoneGroupAction:
            case IKUndefinedAction:
                return NO;
            case IKCancelGroupAction:
                return YES;
        }
    }
    else {
        return NO;
    }
}

@end
