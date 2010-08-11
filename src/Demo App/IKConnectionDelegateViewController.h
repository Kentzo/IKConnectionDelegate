#import "IKConnectionDelegate.h"

@interface IKConnectionDelegateViewController : UIViewController {
    UIImageView *imageView;
    UIProgressView *progressView;
    UILabel *label;
@private 
    IKConnectionDelegate *_delegate;
}

@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) IBOutlet UIProgressView *progressView;
@property (nonatomic, retain) IBOutlet UILabel *label;

@end
