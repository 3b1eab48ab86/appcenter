#import "SelectionPage.h"
#import "SpringBoard.h"
#import "Tweak.h"
#import "UIImage+Tint.h"

@implementation ACIconButton

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    UIImage *image = [UIImage imageWithContentsOfFile:@"/Library/Application Support/App Center/appcenter.png"];
    [self setGlyphImage:image selectedGlyphImage:image name:@"ACIconButton"];
  }
  return self;
}

- (CGSize)intrinsicContentSize {
  return CGSizeMake(25, 25);
}

@end

@implementation ACAppIconCell

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {

    self.contentView.layer.cornerRadius = 12;

    self.button = [CCUIControlCenterButton roundRectButton];

    self.button.delegate = self;
    self.button.userInteractionEnabled = false;
    self.button.animatesStateChanges = false;
    self.button.translatesAutoresizingMaskIntoConstraints = false;

    [self.contentView addSubview:self.button];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[button]|" options:nil metrics:nil views:@{ @"button" : self.button }]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[button]|" options:nil metrics:nil views:@{ @"button" : self.button }]];

    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [%c(SBIconView) defaultIconImageSize].width * 0.80, [%c(SBIconView) defaultIconImageSize].height * 0.80)];
    self.imageView.center = CGPointMake(self.contentView.bounds.size.width / 2, (self.contentView.bounds.size.height * 0.80) / 2);
    [self.button addSubview:self.imageView];
    [self.imageView release];

    CGPoint center = self.imageView.center;
    center.x = self.bounds.size.width / 2;
    self.imageView.center = center;

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.adjustsFontSizeToFitWidth = false;
    self.titleLabel.font = [UIFont systemFontOfSize:12];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = false;

    [self.button addSubview:self.titleLabel];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[label]|" options:nil metrics:nil views:@{ @"label" : self.titleLabel }]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[imageView][label]|" options:nil metrics:nil views:@{ @"label" : self.titleLabel, @"imageView" : self.imageView }]];
  }
  return self;
}

- (id)controlCenterSystemAgent {
  return nil;
}

- (void)buttonTapped:(CCUIControlCenterButton *)arg1 {

}

- (void)button:(CCUIControlCenterButton *)arg1 didChangeState:(long long)arg2 {
  if (arg2 == 0) {
    self.titleLabel.textColor = [UIColor whiteColor];
  } else {
    self.titleLabel.textColor = [UIColor blackColor];
  }
}

- (BOOL)isInternal {
  return false;
}

- (void)configureForApplication:(NSString*)appIdentifier {
  self.appIdentifier = appIdentifier;

  SBIconModel *iconModel = [(SBIconController*)[%c(SBIconController) sharedInstance] model];
  SBIcon *icon = [iconModel expectedIconForDisplayIdentifier:appIdentifier];
  int iconFormat = [icon iconFormatForLocation:0];

  self.imageView.image = [icon getCachedIconImage:iconFormat];
  self.imageView.highlightedImage = [self.imageView.image tintedImageUsingColor:[UIColor colorWithWhite:0.0 alpha:0.3]];

  self.titleLabel.text = [[[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:self.appIdentifier] displayName];

  if ([appPages containsObject:appIdentifier]) {
    self.button.selected = true;
  } else {
    self.button.selected = false;
  }
}

@end

@implementation ACAppSelectionGridViewController

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return MIN([[[%c(SBAppSwitcherModel) sharedInstance] appcenter_model] count] + appPages.count, 9);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  ACAppIconCell *cell = (ACAppIconCell*)[self.collectionView dequeueReusableCellWithReuseIdentifier:@"AppIconCell" forIndexPath:indexPath];

  NSString *appIdentifier = nil;

  if (indexPath.row < appPages.count) {
    appIdentifier = appPages[indexPath.row];
  } else {
    appIdentifier = [[%c(SBAppSwitcherModel) sharedInstance] appcenter_model][indexPath.row - appPages.count];
  }

  [cell configureForApplication:appIdentifier];

  return cell;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

-(void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
  ACAppIconCell *cell = (ACAppIconCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
  cell.imageView.highlighted = true;
}

-(void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
  ACAppIconCell *cell = (ACAppIconCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
  cell.imageView.highlighted = false;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  CCUIControlCenterViewController *ccViewController = (CCUIControlCenterViewController*)self.parentViewController.parentViewController.parentViewController;

  NSString *appIdentifier = nil;

  ACAppIconCell *cell = (ACAppIconCell*)[self.collectionView cellForItemAtIndexPath:indexPath];

  if (indexPath.row < appPages.count) {
    appIdentifier = appPages[indexPath.row];
  } else {
    appIdentifier = [[%c(SBAppSwitcherModel) sharedInstance] appcenter_model][indexPath.row - appPages.count];
  }

  ((ACAppSelectionPageViewController*)self.parentViewController).selectedCell = cell;

  cell.button.selected = !cell.button.selected;

  [ccViewController appcenter_appSelected:appIdentifier];
}

- (void)loadView {

  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.itemSize = CGSizeMake(80, 80);

  self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];

  self.collectionView.delegate = self;
  self.collectionView.dataSource = self;

  self.collectionView.translatesAutoresizingMaskIntoConstraints = false;
  self.collectionView.backgroundColor = [UIColor clearColor];

  [self.collectionView registerClass:[ACAppIconCell class] forCellWithReuseIdentifier:@"AppIconCell"];
  self.view = self.collectionView;

  [layout release];
}

- (void)fixButtonEffects {
  if ([self collectionView:self.collectionView numberOfItemsInSection:0] > 0) {
    [[(ACAppIconCell*)[self collectionView:self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] button] _updateEffects];
  }
}

@end

@implementation ACAppSelectionContainerView

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.translatesAutoresizingMaskIntoConstraints = false;

    ACIconButton *iconButton = [[ACIconButton alloc] initWithFrame:CGRectZero];
    self.iconButton = iconButton;
    [iconButton release];

    [self.iconButton setTranslatesAutoresizingMaskIntoConstraints:false];

    UILabel *titleLabel = [[CCUIControlCenterLabel alloc] init];
    self.titleLabel = titleLabel;
    [titleLabel release];

    [self.titleLabel setAllowsDefaultTighteningForTruncation:true];
    [self.titleLabel setAdjustsFontSizeToFitWidth:true];
    [self.titleLabel setMinimumScaleFactor:(float)0x3f400000];
    [self.titleLabel setTranslatesAutoresizingMaskIntoConstraints:false];
    self.titleLabel.text = @"App Center";
    self.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];

    [self addSubview:self.iconButton];
    [self addSubview:self.titleLabel];

    NSDictionary *views = @{
      @"iconButton": self.iconButton,
      @"titleLabel": self.titleLabel
    };

    NSMutableArray *constraints = [NSMutableArray new];

    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(5)-[iconButton]" options:nil metrics:nil views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(-1)-[iconButton]" options:nil metrics:nil views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[iconButton]-(10)-[titleLabel]" options:nil metrics:nil views:views]];

    NSLayoutConstraint *labelFirstBaseline = [NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeFirstBaseline relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:17.0];
    [constraints addObject:labelFirstBaseline];

    [self addConstraints:constraints];

    [constraints release];
  }
  return self;
}

@end

@implementation ACAppSelectionPageViewController
@dynamic view;
@synthesize delegate;

- (id)initWithNibName:(NSString*)nibName bundle:(NSBundle*)bundle {
  self = [super initWithNibName:nibName bundle:bundle];
  if (self) {
    self.gridViewController = [[ACAppSelectionGridViewController alloc] initWithNibName:nil bundle:nil];
  }
  return self;
}

- (UIEdgeInsets)contentInsets {
  return UIEdgeInsetsMake(16.0, 16.0, 16.0, 16.0);
}

- (BOOL)wantsVisible {
  return YES;
}

- (void)loadView {
  ACAppSelectionContainerView *view = [[ACAppSelectionContainerView alloc] init];
  self.view = view;
  [view release];

  [self addChildViewController:self.gridViewController];
  [self.gridViewController.view setFrame:self.view.bounds];
  [self.view addSubview:self.gridViewController.view];
  [self.gridViewController didMoveToParentViewController:self];

  NSMutableArray *constraints = [NSMutableArray new];

  NSDictionary *views = @{
    @"gridView": self.gridViewController.view,
    @"iconButton": self.view.iconButton
  };

  [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[gridView]|" options:nil metrics:nil views:views]];
  [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[iconButton]-10-[gridView]|" options:nil metrics:nil views:views]];

  [self.view addConstraints:constraints];
}

- (void)controlCenterWillPresent {
  static dispatch_once_t onceToken;

  dispatch_once (&onceToken, ^{
    [self.gridViewController.collectionView reloadData];
  });
}

- (void)controlCenterDidFinishTransition {

}

- (void)controlCenterWillBeginTransition {
  [self.gridViewController fixButtonEffects];
}

- (void)controlCenterDidDismiss {
  [self.gridViewController.collectionView reloadData];
}

@end
