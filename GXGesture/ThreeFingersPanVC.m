//
//  ThreeFingersPanVC.m
//  Testa
//
//  Created by sgx on 2019/9/6.
//  Copyright © 2019 sgx. All rights reserved.
//

#import "ThreeFingersPanVC.h"

@interface ThreeFingersPanVC ()
@property (nonatomic, strong) UIImageView *currentPlayerView;
@property (nonatomic, strong) UIPanGestureRecognizer *threeFingersPanGesture;
// three fingers gesture
@property (nonatomic, strong) NSMutableArray *threeFingersStartPoints;
@property (nonatomic, assign) CGFloat threeFingersStartCentroidRadius, threeFingersStartAngle;
@property (nonatomic, assign) NSUInteger threeFingersRotationIndex1, threeFingersRotationIndex2;
@property (nonatomic, assign) CGFloat threeFingersTotalRotation, threeFingersStandardRotation;
@property (nonatomic, assign) CATransform3D threeFingersTransform;
@end

@implementation ThreeFingersPanVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view addSubview:[self currentPlayerView]];
    
    self.currentPlayerView.frame = CGRectMake(0, 0, 200, 200);
    self.currentPlayerView.center = self.view.center;
    
    [self.view addGestureRecognizer:self.threeFingersPanGesture];
}


- (UIPanGestureRecognizer *)threeFingersPanGesture {
    if (!_threeFingersPanGesture) {
        _threeFingersStartPoints = [NSMutableArray new];
        _threeFingersTransform = CATransform3DIdentity;
        
        _threeFingersPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(threeFingersPan:)];
        _threeFingersPanGesture.minimumNumberOfTouches = 3;
        _threeFingersPanGesture.maximumNumberOfTouches = 3;
    }
    return _threeFingersPanGesture;
}
- (UIImageView *)currentPlayerView {
    if (!_currentPlayerView) {
        _currentPlayerView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"timg.jpeg"]];
    }
    return _currentPlayerView;
}
- (void)threeFingersPan:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self.threeFingersStartPoints removeAllObjects];
        if (gesture.numberOfTouches == 3) {
            CGPoint touchPoint = CGPointZero;
            for (int i = 0; i < 3; i++) {
                touchPoint = [gesture locationOfTouch:i inView:self.view];
                [self.threeFingersStartPoints addObject:[NSValue valueWithCGPoint:touchPoint]];
            }

            // 中心点到abc三个点的距离的平均值
            self.threeFingersStartCentroidRadius = [self triangleCentroidRadius:self.threeFingersStartPoints];
            if (MAXFLOAT == self.threeFingersStartCentroidRadius) {
                [self.threeFingersStartPoints removeAllObjects];
                return;
            }

            CGFloat ab = [self pointsDistanceFrom:[[self.threeFingersStartPoints objectAtIndex:0] CGPointValue] to:[[self.threeFingersStartPoints objectAtIndex:1] CGPointValue]];
            CGFloat bc = [self pointsDistanceFrom:[[self.threeFingersStartPoints objectAtIndex:1] CGPointValue] to:[[self.threeFingersStartPoints objectAtIndex:2] CGPointValue]];
            CGFloat ca = [self pointsDistanceFrom:[[self.threeFingersStartPoints objectAtIndex:2] CGPointValue] to:[[self.threeFingersStartPoints objectAtIndex:0] CGPointValue]];
            if (ab >= bc && ab >= ca) {
                self.threeFingersRotationIndex1 = 0;
                self.threeFingersRotationIndex2 = 1;
            } else if (bc >= ab && bc >= ca) {
                self.threeFingersRotationIndex1 = 1;
                self.threeFingersRotationIndex2 = 2;
            } else {
                self.threeFingersRotationIndex1 = 0;
                self.threeFingersRotationIndex2 = 2;
            }
            CGPoint point1 = [[self.threeFingersStartPoints objectAtIndex:self.threeFingersRotationIndex1] CGPointValue];
            CGPoint point2 = [[self.threeFingersStartPoints objectAtIndex:self.threeFingersRotationIndex2] CGPointValue];
            // atan2(y,x): 返回以弧度表示的 y/x 的反正切. 即与x轴的夹角
            self.threeFingersStartAngle = atan2(point2.y - point1.y, point2.x - point1.x);
            NSLog(@"sgx >>> point1: %lf %lf  point2: %lf %lf",point1.x,point1.y,point2.x,point2.y);
            NSLog(@"sgx >>> start  : startAngle: %lf     y:%lf x:%lf",self.threeFingersStartAngle,(point2.y-point1.y),point2.x-point1.x);
        }
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        if (gesture.numberOfTouches == 3 && self.threeFingersStartPoints.count == 3) {
            CGPoint touchPoint = CGPointZero;
            NSMutableArray *points = [NSMutableArray new];
            for (int i = 0; i < 3; i++) {
                touchPoint = [gesture locationOfTouch:i inView:self.view];
                [points addObject:[NSValue valueWithCGPoint:touchPoint]];
            }

            // pinch
            CGFloat centroidRadius = [self triangleCentroidRadius:points];
            if (MAXFLOAT == centroidRadius) {
                return;
            }

            CGFloat scale = centroidRadius / self.threeFingersStartCentroidRadius;
            self.threeFingersStartCentroidRadius = centroidRadius;
            [self currentPlayerView].layer.transform = CATransform3DScale([self currentPlayerView].layer.transform, scale, scale, 1.0);

            // rotation
            CGPoint point1 = [[points objectAtIndex:self.threeFingersRotationIndex1] CGPointValue];
            CGPoint point2 = [[points objectAtIndex:self.threeFingersRotationIndex2] CGPointValue];
            CGFloat endAngle = atan2(point2.y - point1.y, point2.x - point1.x);
            CGFloat rotationAngle = endAngle - self.threeFingersStartAngle;
            self.threeFingersTotalRotation += rotationAngle;
            self.threeFingersStartAngle = endAngle;

            [self currentPlayerView].layer.transform = CATransform3DRotate([self currentPlayerView].layer.transform, rotationAngle, 0, 0, 1.0);


            // pan
            [self currentPlayerView].center = [self currentPlayerView].superview.center;
        }
    } else if (gesture.state == UIGestureRecognizerStateEnded) {

        if (@available(iOS 10.0, *)) {
            UIImpactFeedbackGenerator *feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
            [feedbackGenerator impactOccurred];
        }

        // 三指手势旋转，可将画面以90、180、270、360度旋转
        self.threeFingersTotalRotation = fmod(self.threeFingersTotalRotation, 2 * M_PI);
        if (self.threeFingersTotalRotation < 0) {
            self.threeFingersTotalRotation += 2 * M_PI;
        }
        CGFloat angle = 0.0;
        if (self.threeFingersTotalRotation >= 0 && self.threeFingersTotalRotation < M_PI_4) { // 0~PI/4
            angle = -self.threeFingersTotalRotation;
            self.threeFingersTotalRotation = 0;
        } else if (self.threeFingersTotalRotation >= M_PI_4 && self.threeFingersTotalRotation < 3 * M_PI_4) { // PI/4~3PI/4
            angle = M_PI_2 - self.threeFingersTotalRotation;
            self.threeFingersTotalRotation = M_PI_2;
        } else if (self.threeFingersTotalRotation >= 3 * M_PI_4 && self.threeFingersTotalRotation < 5 * M_PI_4) { // 3PI/4~5PI/4
            angle = M_PI - self.threeFingersTotalRotation;
            self.threeFingersTotalRotation = M_PI;
        } else if (self.threeFingersTotalRotation >= 5 * M_PI_4 && self.threeFingersTotalRotation < 7 * M_PI_4) { // 5PI/4~7PI/4
            angle = 3 * M_PI_2 - self.threeFingersTotalRotation;
            self.threeFingersTotalRotation = 3 * M_PI_2;
        } else if (self.threeFingersTotalRotation >= 7 * M_PI_4 && self.threeFingersTotalRotation < 2 * M_PI) { // 7PI/4~2PI
            angle = 2 * M_PI - self.threeFingersTotalRotation;
            self.threeFingersTotalRotation = 0;
        }

        [UIView animateWithDuration:0.3 animations:^{
            [self currentPlayerView].layer.transform = CATransform3DRotate([self currentPlayerView].layer.transform, angle, 0, 0, 1.0);
        }];
        self.threeFingersStandardRotation = self.threeFingersTotalRotation;

        // 仅在画面放大时可以拖动至边界，画面缩小或者正常画面下有拖动效果，无法实际拖动
        UIView *mediaSuperView = [self currentPlayerView].superview;
        CGRect mediaViewFrame = [self currentPlayerView].frame;
        if (CGRectGetHeight(mediaViewFrame) <= CGRectGetHeight(mediaSuperView.bounds)) {
            [UIView animateWithDuration:0.3 animations:^{
                [self currentPlayerView].center = [self currentPlayerView].superview.center;//center;
            }];
        } else {
            CGFloat moveX = 0.0, moveY = 0.0;
            if (CGRectGetWidth(mediaViewFrame) <= CGRectGetWidth(mediaSuperView.bounds)) {
                moveX = CGRectGetMidX(mediaSuperView.bounds) - CGRectGetMidX(mediaViewFrame);
            } else {
                if (CGRectGetMinX(mediaViewFrame) > 0) {
                    moveX = -CGRectGetMinX(mediaViewFrame);
                } else if (CGRectGetMaxX(mediaViewFrame) < mediaSuperView.bounds.size.width) {
                    moveX = CGRectGetWidth(mediaSuperView.bounds) - CGRectGetMaxX(mediaViewFrame);
                }
            }
            if (CGRectGetMinY(mediaViewFrame) > 0) {
                moveY = -CGRectGetMinY(mediaViewFrame);
            } else if (CGRectGetMaxY(mediaViewFrame) < mediaSuperView.bounds.size.height) {
                moveY = CGRectGetHeight(mediaSuperView.bounds) - CGRectGetMaxY(mediaViewFrame);
            }
            [UIView animateWithDuration:0.3 animations:^{
                [self currentPlayerView].center = [self currentPlayerView].superview.center;//center;
            }];
        }

        // 放大缩小倍数最大为5
        CGFloat maxLenght = CGRectGetWidth(mediaViewFrame) > CGRectGetHeight(mediaViewFrame) ? CGRectGetWidth(mediaViewFrame) : CGRectGetHeight(mediaViewFrame);
        CGFloat scale = 1.0;
        if (maxLenght > 5 * CGRectGetWidth(mediaSuperView.bounds)) {
            scale = 5 * CGRectGetWidth(mediaSuperView.bounds) / maxLenght;
        } else if (maxLenght * 5 < CGRectGetWidth(mediaSuperView.bounds)) {
            scale = CGRectGetWidth(mediaSuperView.bounds) / (maxLenght * 5);
        }
        if (scale != 1.0) {
            [UIView animateWithDuration:0.3 animations:^{
                [self currentPlayerView].layer.transform = CATransform3DScale([self currentPlayerView].layer.transform, scale, scale, 1.0);
            }];
        }
    } else if (gesture.state == UIGestureRecognizerStateCancelled || gesture.state == UIGestureRecognizerStateFailed) {

        if (@available(iOS 10.0, *)) {
            UIImpactFeedbackGenerator *feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
            [feedbackGenerator impactOccurred];
        }

        CGFloat angle = self.threeFingersStandardRotation - self.threeFingersTotalRotation;
        [UIView animateWithDuration:0.3 animations:^{
            [self currentPlayerView].layer.transform = CATransform3DRotate([self currentPlayerView].layer.transform, angle, 0, 0, 1.0);
        }];
        self.threeFingersTotalRotation = self.threeFingersStandardRotation;

        // 仅在画面放大时可以拖动至边界，画面缩小或者正常画面下有拖动效果，无法实际拖动
        UIView *mediaSuperView = [self currentPlayerView].superview;
        CGRect mediaViewFrame = [self currentPlayerView].frame;
        if (CGRectGetHeight(mediaViewFrame) <= CGRectGetHeight(mediaSuperView.bounds)) {
            [UIView animateWithDuration:0.3 animations:^{
                [self currentPlayerView].center = [self currentPlayerView].superview.center;//center;
            }];
        } else {
            CGFloat moveX = 0.0, moveY = 0.0;
            if (CGRectGetWidth(mediaViewFrame) <= CGRectGetWidth(mediaSuperView.bounds)) {
                moveX = CGRectGetMidX(mediaSuperView.bounds) - CGRectGetMidX(mediaViewFrame);
            } else {
                if (CGRectGetMinX(mediaViewFrame) > 0) {
                    moveX = -CGRectGetMinX(mediaViewFrame);
                } else if (CGRectGetMaxX(mediaViewFrame) < mediaSuperView.bounds.size.width) {
                    moveX = CGRectGetWidth(mediaSuperView.bounds) - CGRectGetMaxX(mediaViewFrame);
                }
            }
            if (CGRectGetMinY(mediaViewFrame) > 0) {
                moveY = -CGRectGetMinY(mediaViewFrame);
            } else if (CGRectGetMaxY(mediaViewFrame) < mediaSuperView.bounds.size.height) {
                moveY = CGRectGetHeight(mediaSuperView.bounds) - CGRectGetMaxY(mediaViewFrame);
            }
            [UIView animateWithDuration:0.3 animations:^{
                [self currentPlayerView].center = [self currentPlayerView].superview.center;//center;
            }];
        }

        // 放大缩小倍数最大为5
        CGFloat maxLenght = CGRectGetWidth(mediaViewFrame) > CGRectGetHeight(mediaViewFrame) ? CGRectGetWidth(mediaViewFrame) : CGRectGetHeight(mediaViewFrame);
        CGFloat scale = 1.0;
        if (maxLenght > 5 * CGRectGetWidth(mediaSuperView.bounds)) {
            scale = 5 * CGRectGetWidth(mediaSuperView.bounds) / maxLenght;
        } else if (maxLenght * 5 < CGRectGetWidth(mediaSuperView.bounds)) {
            scale = CGRectGetWidth(mediaSuperView.bounds) / (maxLenght * 5);
        }
        if (scale != 1.0) {
            [UIView animateWithDuration:0.3 animations:^{
                [self currentPlayerView].layer.transform = CATransform3DScale([self currentPlayerView].layer.transform, scale, scale, 1.0);
            }];
        }
    }
}

/// a.b.c三个点的中心点
/// @param points <#points description#>
- (CGPoint)triangleCentroid:(NSArray *)points {
    if (points.count != 3) {
        return CGPointMake(MAXFLOAT, MAXFLOAT);
    }
    
    CGPoint a = [[points objectAtIndex:0] CGPointValue];
    CGPoint b = [[points objectAtIndex:1] CGPointValue];
    CGPoint c = [[points objectAtIndex:2] CGPointValue];
    return CGPointMake((a.x + b.x + c.x) / 3, (a.y + b.y + c.y) / 3);
}

/// a.b.c三个点到中心的间距的平均值
/// @param points <#points description#>
- (CGFloat)triangleCentroidRadius:(NSArray *)points {
    if (points.count != 3) {
        return MAXFLOAT;
    }
    
    CGPoint a = [[points objectAtIndex:0] CGPointValue];
    CGPoint b = [[points objectAtIndex:1] CGPointValue];
    CGPoint c = [[points objectAtIndex:2] CGPointValue];
    
    CGPoint centroid = [self triangleCentroid:points];
    CGFloat distance1 = [self pointsDistanceFrom:centroid to:a];
    CGFloat distance2 = [self pointsDistanceFrom:centroid to:b];
    CGFloat distance3 = [self pointsDistanceFrom:centroid to:c];
    
    return (distance1 + distance2 + distance3) / 3;
}

/// 点a和点b的间距
/// @param a <#a description#>
/// @param b <#b description#>
- (CGFloat)pointsDistanceFrom:(CGPoint)a to:(CGPoint)b {
    // sqrtf(x) : 取x的平方根
    // powf(x,y) : 取x的y幂.
    return sqrtf(powf((b.x - a.x), 2) + powf((b.y - a.y), 2));
}

@end
