#import "IKConnectionDelegateViewController.h"
#import "IKConnectionDelegate.h"

@implementation IKConnectionDelegateViewController
@synthesize imageView;
@synthesize progressView;
@synthesize label;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    IKConnectionProgressBlock downloadProgress = ^(NSUInteger downloadedLength, NSUInteger maximumLength) {
        float progress = ((float)downloadedLength)/maximumLength;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.label.text = [NSString stringWithFormat:@"%.2f%%", progress * 100];
            self.progressView.progress = progress;
        });
    };
    
    IKConnectionProgressBlock uploadProgress = ^(NSUInteger uploadedLength, NSUInteger maximumLength) {
        float progress = ((float)uploadedLength)/maximumLength;
        NSLog(@"%@", [NSString stringWithFormat:@"%.2f%%", progress * 100]);
    };
    
    IKConnectionCompletionBlock completion = ^(NSData *data, NSURLResponse *response, NSError *error) {
        UIImage *image = [UIImage imageWithData:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error == nil) {
                self.imageView.image = image;
                
                [UIView beginAnimations:nil context:NULL];
                [UIView setAnimationDuration:1.0f];
                self.label.alpha = 0.0f;
                self.progressView.alpha = 0.0f;
                self.imageView.alpha = 1.0f;
                [UIView commitAnimations];
            }
            else {
                UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Cannot Download Image"
                                                                    message:[error localizedDescription]
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                [errorAlert show];
                [errorAlert release];
            }

        });
    };
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.motivatedsista.com/wp-content/uploads/2010/07/fear.bmp"]];
    [NSURLConnection connectionWithRequest:request delegate:[IKConnectionDelegate connectionDelegateWithDownloadProgress:downloadProgress
                                                                                                          uploadProgress:uploadProgress
                                                                                                              completion:completion]];
}


- (void)viewDidUnload {
    self.imageView = nil;
    self.progressView = nil;
    self.label = nil;
    [super viewDidUnload];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


- (void)dealloc {
    [imageView release];
    [progressView release];
    [label release];
    [super dealloc];
}


@end
