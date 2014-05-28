#import "AdefyMainViewController.h"
#import "AdefyViewStyles.h"

@implementation AdefyMainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  // Tweak visuals, make it pop :D
  styleButton(self.DemosButton);
  styleButton(self.ViewWebsiteButton);
  styleButton(self.BrochureButton);

  // Dark brochure button
  UIColor* darkBlueColor = [UIColor colorWithRed:0.03921568627f
                                           green:0.14117647058f
                                            blue:0.18039215686f
                                           alpha:1.0f];

  self.BrochureButton.layer.borderColor = [darkBlueColor CGColor];
  self.BrochureButton.titleLabel.textColor = darkBlueColor;
  self.LearnMoreLabel.textColor = darkBlueColor;

  // Setup fonts
  self.DemosButton.titleLabel.font = [UIFont fontWithName:@"ProximaNova-Regular" size:16];
  self.ViewWebsiteButton.titleLabel.font = [UIFont fontWithName:@"ProximaNova-Regular" size:16];
  self.BrochureButton.titleLabel.font = [UIFont fontWithName:@"ProximaNova-Regular" size:20];

  self.ShowcaseLabel.font = [UIFont fontWithName:@"ProximaNova-Regular" size:20];
  self.LogoLabel.font = [UIFont fontWithName:@"OleoScript-Regular" size:64];

  // Hook up buttons
  [self.ViewWebsiteButton addTarget:self action:@selector(openWebsite) forControlEvents:UIControlEventTouchUpInside];
  [self.BrochureButton addTarget:self action:@selector(openBrochure) forControlEvents:UIControlEventTouchUpInside];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

- (void) openWebsite {
  NSURL *url = [[ NSURL alloc ] initWithString: @"https://www.adefy.com" ];
  [[UIApplication sharedApplication] openURL:url];
}

- (void) openBrochure {
  NSURL *url = [[ NSURL alloc ] initWithString: @"https://www.adefy.com/brochure_adefy.pdf" ];
  [[UIApplication sharedApplication] openURL:url];
}

- (void)viewWillAppear:(BOOL)animated {
  [self.navigationController setNavigationBarHidden:YES animated:animated];
  [super viewWillAppear:animated];
}

@end
