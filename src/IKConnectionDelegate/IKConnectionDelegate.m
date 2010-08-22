//
//  IKConnectionDelegate.m
//  IKConnectionDelegate
//
//  Created by Ilya Kulakov on 11.08.10.
//  Copyright 2010. All rights reserved.

#import <dispatch/dispatch.h>
#import "IKConnectionDelegate.h"


@interface IKConnectionDelegate (/* Private Stuff Here */)

@property (copy) IKConnectionProgressBlock downloadProgress;
@property (copy) IKConnectionProgressBlock uploadProgress;
@property (copy) IKConnectionCompletionBlock completion;
@property (retain) NSMutableData *data;
@property (retain) NSURLResponse *response;
@property (assign) BOOL isFinished;
@property (retain) NSURLConnection *_connection;

@end

@implementation IKConnectionDelegate
@synthesize downloadProgress;
@synthesize uploadProgress;
@synthesize completion;
@synthesize data;
@synthesize response;
@synthesize isFinished;
@synthesize _connection;

+ (IKConnectionDelegate *)connectionDelegateWithDownloadProgress:(IKConnectionProgressBlock)aDownloadProgress
                                                  uploadProgress:(IKConnectionProgressBlock)anUploadProgress
                                                      completion:(IKConnectionCompletionBlock)aCompletion;
{
    return [[[self alloc] initWithDownloadProgress:aDownloadProgress uploadProgress:anUploadProgress completion:aCompletion] autorelease];
}


- (IKConnectionDelegate *)initWithDownloadProgress:(IKConnectionProgressBlock)aDownloadProgress
                                    uploadProgress:(IKConnectionProgressBlock)anUploadProgress
                                        completion:(IKConnectionCompletionBlock)aCompletion
{
    if (self = [super init]) {
        self.downloadProgress = aDownloadProgress;
        self.uploadProgress = anUploadProgress;
        self.completion = aCompletion;
        data = [NSMutableData new];
    }
    return self;
}


- (void)dealloc {
    [downloadProgress release];
    [uploadProgress release];
    [completion release];
    [data release];
    [response release];
    [super dealloc];
}


#pragma mark NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)aResponse {
    
    NSAssert(_connection == nil || _connection == connection, @"You cannot use one IKConnectionDelegate more than once");
    
    if (_connection == nil) {
        _connection = connection;
    }
    
    self.response = aResponse;
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)aData {
    [data appendData:aData];
    if (downloadProgress != nil) {
        downloadProgress([data length], [response expectedContentLength]);
    }
}


- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten 
 totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    if (uploadProgress != nil) {
        uploadProgress(totalBytesWritten, totalBytesExpectedToWrite);
    }
}


- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
    NSAssert(_connection == nil || _connection == connection, @"You cannot use one IKConnectionDelegate more than once");
    
	if ([challenge previousFailureCount] > 0) {
		[[challenge sender] cancelAuthenticationChallenge:challenge];
	}
	else {
		[[challenge sender] useCredential:[challenge proposedCredential] forAuthenticationChallenge:challenge];
	}
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    self.isFinished = YES;
    if (completion != nil) {
        completion(data, response, nil);
    }
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)anError {
    self.isFinished = YES;
    if (completion != nil) {
        completion(data, response, anError);
    }
}

@end
