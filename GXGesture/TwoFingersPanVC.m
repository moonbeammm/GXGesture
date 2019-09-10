//
//  TwoFingersPanVC.m
//  Testa
//
//  Created by sgx on 2019/9/6.
//  Copyright © 2019 sgx. All rights reserved.
//

#import "TwoFingersPanVC.h"

static CGFloat kMaxScale = 5.0; // 最大放大/最小缩小 系数;
static CGFloat kMediaViewWH = 200;

@interface TwoFingersPanVC ()

@property (nonatomic, strong) UIImageView *currentPlayerView;
@property (nonatomic, strong) UIPanGestureRecognizer *twoFingersPanGesture;

@property (nonatomic, strong) NSArray *twoFingersStartPoints;
@property (nonatomic, assign) CGFloat twoFingersCentroidRadius, twoFingersStartAngle;
@property (nonatomic, assign) CGFloat twoFingersTotalRotation;

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIView *bgView;

@end

@implementation TwoFingersPanVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view addSubview:self.bgView];
    [self.view addSubview:[self currentPlayerView]];
    [self.view addSubview:self.label];
    
    self.currentPlayerView.frame = CGRectMake(0, 0, kMediaViewWH, kMediaViewWH);
    self.currentPlayerView.center = self.view.center;
    self.bgView.frame = self.currentPlayerView.frame;
    self.label.frame = CGRectMake(0, 100, 1000, 50);
    
    [self.view addGestureRecognizer:self.twoFingersPanGesture];
}

- (UIPanGestureRecognizer *)twoFingersPanGesture {
    if (!_twoFingersPanGesture) {
        _twoFingersPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(twoFingersPan:)];
        _twoFingersPanGesture.minimumNumberOfTouches = 2;
        _twoFingersPanGesture.maximumNumberOfTouches = 2;
    }
    return _twoFingersPanGesture;
}
- (UIImageView *)currentPlayerView {
    if (!_currentPlayerView) {
        _currentPlayerView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"timg.jpeg"]];
    }
    return _currentPlayerView;
}
- (UIView *)bgView {
    if (!_bgView) {
        _bgView = [UIView new];
        _bgView.backgroundColor = [UIColor redColor];
    }
    return _bgView;
}
- (UILabel *)label {
    if (!_label) {
        _label = [UILabel new];
        _label.font = [UIFont systemFontOfSize:12];
        _label.textColor = [UIColor blackColor];
        _label.backgroundColor = [UIColor redColor];
    }
    return _label;
}
- (void)twoFingersPan:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        // 两个手指在屏幕上的坐标
        self.twoFingersStartPoints = [self fingerPoints:gesture];
        if (self.twoFingersStartPoints.count != 2) {
            self.twoFingersStartPoints = nil;
            return;
        }
        
        // ab两点的直线距离
        self.twoFingersCentroidRadius = [self pointsDistance:self.twoFingersStartPoints];
        // ab两个点连线与x轴角度
        self.twoFingersStartAngle = [self twoFingersAngle:self.twoFingersStartPoints];
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        NSArray *newFingerPoints = [self fingerPoints:gesture];
        if (newFingerPoints.count != 2 || self.twoFingersStartPoints.count != 2) {
            return;
        }
        
        // scale
        // 新的ab两点的直线距离
        CGFloat newTwoFingersCentroidRadius = [self pointsDistance:newFingerPoints];
        // 缩放比例
        CGFloat scale = newTwoFingersCentroidRadius / self.twoFingersCentroidRadius;
        self.twoFingersCentroidRadius = newTwoFingersCentroidRadius;
        
        // rotation
        // 新的ab两个点连线与x轴角度
        CGFloat endAngle = [self twoFingersAngle:newFingerPoints];
        // 旋转了多少度
        CGFloat rotationAngle = endAngle - self.twoFingersStartAngle;
        self.twoFingersTotalRotation += rotationAngle;
        self.twoFingersStartAngle = endAngle;
        
        [self currentPlayerView].layer.transform = CATransform3DScale([self currentPlayerView].layer.transform, scale, scale, 1.0);
        [self currentPlayerView].layer.transform = CATransform3DRotate([self currentPlayerView].layer.transform, rotationAngle, 0, 0, 1.0);
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        if (@available(iOS 10.0, *)) { // 震动反馈
            UIImpactFeedbackGenerator *feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
            [feedbackGenerator impactOccurred];
        }
        
        // rotation
        // fmod(x,y): 即x/y的余数
        // 三指手势旋转，可将画面以90、180、270、360度旋转
        self.twoFingersTotalRotation = fmod(self.twoFingersTotalRotation, 2 * M_PI);
        if (self.twoFingersTotalRotation < 0) {
            self.twoFingersTotalRotation += 2 * M_PI;
        }
        CGFloat angle = 0.0;
        if (self.twoFingersTotalRotation >= 0 && self.twoFingersTotalRotation < M_PI_4) { // 0~PI/4
            angle = -self.twoFingersTotalRotation;
            self.twoFingersTotalRotation = 0;
        } else if (self.twoFingersTotalRotation >= M_PI_4 && self.twoFingersTotalRotation < 3 * M_PI_4) { // PI/4~3PI/4
            angle = M_PI_2 - self.twoFingersTotalRotation;
            self.twoFingersTotalRotation = M_PI_2;
        } else if (self.twoFingersTotalRotation >= 3 * M_PI_4 && self.twoFingersTotalRotation < 5 * M_PI_4) { // 3PI/4~5PI/4
            angle = M_PI - self.twoFingersTotalRotation;
            self.twoFingersTotalRotation = M_PI;
        } else if (self.twoFingersTotalRotation >= 5 * M_PI_4 && self.twoFingersTotalRotation < 7 * M_PI_4) { // 5PI/4~7PI/4
            angle = 3 * M_PI_2 - self.twoFingersTotalRotation;
            self.twoFingersTotalRotation = 3 * M_PI_2;
        } else if (self.twoFingersTotalRotation >= 7 * M_PI_4 && self.twoFingersTotalRotation < 2 * M_PI) { // 7PI/4~2PI
            angle = 2 * M_PI - self.twoFingersTotalRotation;
            self.twoFingersTotalRotation = 0;
        }
        
        [UIView animateWithDuration:0.3 animations:^{
            [self currentPlayerView].layer.transform = CATransform3DRotate([self currentPlayerView].layer.transform, angle, 0, 0, 1.0);
        } completion:^(BOOL finished) {
            CGFloat scale = 1.0;
            CGFloat mediaViewWidth = MAX(CGRectGetWidth([self currentPlayerView].frame), CGRectGetHeight([self currentPlayerView].frame));
            CGFloat originMediaViewWidth = kMediaViewWH;
            if (mediaViewWidth > kMaxScale * originMediaViewWidth) { // 最多放大5倍
                scale = kMaxScale * originMediaViewWidth / mediaViewWidth;
            } else if (mediaViewWidth * 1 < originMediaViewWidth) { // 最多缩小5倍
                scale = originMediaViewWidth / (mediaViewWidth * 1);
            }
            if (scale != 1.0) {
                [UIView animateWithDuration:0.3 animations:^{
                    [self currentPlayerView].layer.transform = CATransform3DScale([self currentPlayerView].layer.transform, scale, scale, 1.0);
                }];
            }
        }];
    } else if (gesture.state == UIGestureRecognizerStateCancelled ||
               gesture.state == UIGestureRecognizerStateFailed) {
        
    }
}

/// 两个手指在屏幕上的坐标
- (NSArray *)fingerPoints:(UIGestureRecognizer *)gesture {
    if (gesture.numberOfTouches != 2) {
        return nil;
    }
    CGPoint touchPoint = CGPointZero;
    NSMutableArray *fingerPoints = [NSMutableArray arrayWithCapacity:2];
    for (int i = 0; i < 2; i++) {
        touchPoint = [gesture locationOfTouch:i inView:self.view];
        [fingerPoints addObject:[NSValue valueWithCGPoint:touchPoint]];
    }
    return [fingerPoints copy];
}
/// atan2(y,x): 返回以弧度表示的 y/x 的反正切. 即与x轴的夹角
- (CGFloat)twoFingersAngle:(NSArray *)points {
    CGPoint point1 = [[points objectAtIndex:0] CGPointValue];
    CGPoint point2 = [[points objectAtIndex:1] CGPointValue];
    CGFloat twoFingersAngle = atan2(point2.y - point1.y, point2.x - point1.x);
    return twoFingersAngle;
}
/// 点a和点b的间距
- (CGFloat)pointsDistance:(NSArray *)points {
    CGPoint a = [[points objectAtIndex:0] CGPointValue];
    CGPoint b = [[points objectAtIndex:1] CGPointValue];
    // sqrtf(x) : 取x的平方根
    // powf(x,y) : 取x的y幂.
    return sqrtf(powf((b.x - a.x), 2) + powf((b.y - a.y), 2));
}


@end
