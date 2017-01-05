//
//  MBPlaySmartVideoViewController.m
//  SmartVideo
//
//  Created by yindongbo on 17/1/5.
//  Copyright © 2017年 Nxin. All rights reserved.
//

#import "MBPlaySmartVideoViewController.h"
#import "MBActionSheetView.h"
#import "MBSmartVideoConverter.h"

@interface MBPlaySmartVideoViewController ()<
MBActionSheetDelegate
>

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVPlayerItem *item;

@property (nonatomic, strong) UILabel *currentLabel;
@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) UILabel *durationLabel;

@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, strong) UIButton *menuButton;

@property (nonatomic, strong) UIButton *functionButton;

@property (nonatomic, strong) UIView *videoView;
@property (nonatomic, strong) UIView *bottomView;

@property (nonatomic, strong) id timeObserver;

@property (nonatomic, strong) MBActionSheetView *sheetView;
@end

@implementation MBPlaySmartVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.videoView];
    [self.view addSubview:self.bottomView];
    [self.bottomView addSubview:self.startButton];
    [self.bottomView addSubview:self.currentLabel];
    [self.bottomView addSubview:self.slider];
    [self.bottomView addSubview:self.durationLabel];
    [self.bottomView addSubview:self.functionButton];
    
 
    CGFloat height = SCREEN_WIDTH * 0.747;

    self.item = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:self.videoUrlString]];
    self.player = [[AVPlayer alloc] initWithPlayerItem:self.item];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer: self.player];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.playerLayer.frame = CGRectMake(0, 0, SCREEN_WIDTH, height);
    self.playerLayer.position = self.view.center;
    [self.videoView.layer addSublayer: self.playerLayer];
    [self.playerLayer setNeedsDisplay];
    
    [self starAction:self.startButton];
    
    [self.item addObserver:self
                forKeyPath:@"status"
                   options:NSKeyValueObservingOptionNew
                   context:nil];
    
    [self.item addObserver:self
                forKeyPath:@"loadedTimeRanges"
                   options:NSKeyValueObservingOptionNew
                   context:nil];
    
   [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(playerDidFinished:)
                                                name:AVPlayerItemDidPlayToEndTimeNotification
                                              object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - LazyInit
- (UIView *)videoView {
    if (!_videoView)
    {
        _videoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - 50)];
        _videoView.backgroundColor = [UIColor blackColor];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
        [_videoView addGestureRecognizer:tap];
    }
    return _videoView;
}

- (UIView *)bottomView {
    if (!_bottomView)
    {
        _bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - 50, SCREEN_WIDTH, 50)];
        _bottomView.backgroundColor = [UIColor blackColor];
        _bottomView.userInteractionEnabled = YES;
    }
    return _bottomView;
}

- (UIButton *)startButton {
    if (!_startButton)
    {
        _startButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_startButton addTarget:self action:@selector(starAction:) forControlEvents:UIControlEventTouchUpInside];
        [_startButton setImage:[UIImage imageNamed:@"smartVideo_play"] forState:UIControlStateNormal];
        [_startButton setImage:[UIImage imageNamed:@"smartVideo_pause"] forState:UIControlStateSelected];
        [_startButton setFrame:CGRectMake(0, 0, 50, 50)];
    }
    return _startButton;
}

- (UILabel *)currentLabel {
    if (!_currentLabel)
    {
        _currentLabel = [[UILabel alloc] initWithFrame:CGRectMake(_startButton.frame.origin.x + _startButton.frame.size.width, 0, 40, 20)];
        _currentLabel.textAlignment = NSTextAlignmentCenter;
        _currentLabel.textColor = [UIColor whiteColor];
        _currentLabel.font = [UIFont systemFontOfSize:12];
        
        CGPoint currentLabelCenter = _currentLabel.center;
        currentLabelCenter.y = 25;
        _currentLabel.center = currentLabelCenter;
    }
    return _currentLabel;
}

- (UISlider *)slider {
    if (!_slider)
    {
        UIImageView *sliderImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 15, 15)];
        sliderImageView.layer.cornerRadius = 15/2;
        [sliderImageView setImage:[UIImage imageNamed:@"smartVideo_ThumbImage"]];
        
        _slider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH * 0.426, 10)];
        CGPoint sliderCenter = _slider.center;
        sliderCenter.x = self.bottomView.center.x;
        sliderCenter.y = 25;
        _slider.center = sliderCenter;
        
        _slider.minimumValue = 0;
        _slider.continuous = YES;
        [_slider setThumbImage:sliderImageView.image forState:UIControlStateNormal];
        [_slider setMinimumTrackImage:[UIColor whiteColor].image forState:UIControlStateNormal];
        [_slider setMaximumTrackImage:[UIColor whiteColor].image forState:UIControlStateNormal];
       
        [_slider addTarget:self
                    action:@selector(sliderValueChanged:)
          forControlEvents:UIControlEventValueChanged];
        
        [_slider addTarget:self
                    action:@selector(sliderDidDray:)
          forControlEvents:UIControlEventTouchDown];
        
        [_slider addTarget:self
                    action:@selector(didReplay:)
          forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    }
    return _slider;
}

- (UILabel *)durationLabel {
    if (!_durationLabel)
    {
        _durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.slider.frame.size.width + self.slider.frame.origin.x + 15, 0, 40, 20)];
        _durationLabel.textAlignment = NSTextAlignmentCenter;
        _durationLabel.textColor = [UIColor whiteColor];
        _durationLabel.font = [UIFont systemFontOfSize:12];
        
        CGPoint durationLabelCenter = _durationLabel.center;
        durationLabelCenter.y = 25;
        _durationLabel.center = durationLabelCenter;
    }
    return _durationLabel;
}

- (UIButton *)functionButton {
    if (!_functionButton)
    {
        _functionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_functionButton setImage:[UIImage imageNamed:@"functionKeys"] forState:UIControlStateNormal];
        [_functionButton setFrame:CGRectMake(SCREEN_WIDTH - 50, 0, 50, 50)];
        [_functionButton addTarget:self action:@selector(fuctionAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _functionButton;
}

- (MBActionSheetView *)sheetView {
    if (!_sheetView)
    {
        _sheetView = [[MBActionSheetView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        _sheetView.delegate = self;
    }
    return _sheetView;
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"])
    {
        if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay)
        {
            double durition = CMTimeGetSeconds(self.item.duration);
            self.slider.maximumValue = durition;
            [self updateTimeString];
            [self addPlaterProgressTimer];
        }
        else if (self.player.currentItem.status == AVPlayerItemStatusFailed)
        {
            NSLog(@"播放视频失败");
        }
        else if (self.player.currentItem.status == AVPlayerItemStatusUnknown)
        {
            NSLog(@"未知状态");
        }
    }
    else if ([keyPath isEqualToString:@"loadedTimeRanges"])
    {
        NSLog(@"播放进度");
        CMTime duration = self.item.currentTime;
        double totalDuration = CMTimeGetSeconds(duration);
        NSLog(@"totalDuration == %f", totalDuration);
    }
}

#pragma mark - CustomMethod
- (void)updateTimeString {
    NSTimeInterval currentTime = CMTimeGetSeconds(self.player.currentItem.currentTime);
    NSTimeInterval duration = CMTimeGetSeconds(self.player.currentItem.duration);
    NSInteger dMin = duration / 60;
    NSInteger dSec = (NSInteger)duration % 60;
    NSInteger cMin = currentTime / 60;
    NSInteger cSec = (NSInteger)currentTime % 60;
    NSString *durationString = [NSString stringWithFormat:@"%02ld:%02ld", dMin, dSec];
    NSString *currentString = [NSString stringWithFormat:@"%02ld:%02ld", cMin, cSec];
    self.currentLabel.text =currentString;
    self.durationLabel.text = durationString;
}

- (void)addPlaterProgressTimer {
    __weak __typeof(&*self)weakSelf = self;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        NSTimeInterval currentTime = CMTimeGetSeconds(weakSelf.player.currentItem.currentTime);
        NSInteger cMin = currentTime / 60;
        NSInteger cSec = (NSInteger)currentTime % 60;
        NSString *currentString = [NSString stringWithFormat:@"%02ld:%02ld", cMin, cSec];
        weakSelf.currentLabel.text = currentString;
        
        double currentValue = CMTimeGetSeconds(weakSelf.player.currentTime);
        weakSelf.slider.value = currentValue;
    }];
}

#pragma mark - Action
- (void)sliderValueChanged:(id)sender {
    UISlider *slider = (UISlider *)sender;
//    self.valueLabel.text = [NSString stringWithFormat:@"%.1f", slider.value];
    NSLog(@"value == %f",slider.value);
    
    double currentTime = (double)(slider.value);
    double totalTime   = CMTimeGetSeconds(self.item.duration);
    
    if (currentTime < totalTime-0.01f)
    {
        [self.player seekToTime:CMTimeMakeWithSeconds(currentTime, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }
}

- (void)sliderDidDray:(id)sender {
    [self.player pause];
    self.startButton.selected = NO;
}

- (void)didReplay:(id)sender {
    self.startButton.selected = YES;
    [self.player play];
}

- (void)starAction:(UIButton *)sender {
    sender.selected =! sender.selected;
    if (sender.selected)
    {
        NSTimeInterval currentTime = CMTimeGetSeconds(self.player.currentItem.currentTime);
        NSTimeInterval duration = CMTimeGetSeconds(self.player.currentItem.duration);
        if (currentTime >= duration)
        {
            [self.player seekToTime:kCMTimeZero];
        }
        [self.player play];
    }
    else
    {
        [self.player pause];
    }
}

- (void)fuctionAction:(UIButton *)sender {
    NSLog(@"弹出fuctionSheet");
    
    [self.view.window addSubview:self.sheetView];
    self.sheetView.dataArray = [NSMutableArray arrayWithObjects:
                                      self.sheetView.sentToFriendModel,
                                      self.sheetView.saveModel,
                                      self.sheetView.collectionModel, nil];
}

- (void)playerDidFinished:(NSNotification*)noti {
    [self.player pause];
    self.startButton.selected = NO;
    NSLog(@"播放完了");
}

- (void)tapAction {
    [self.player pause];
    self.player.volume = 0.0f;
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - MBActionSheetDelegate
- (void)mbActionSheet:(MBActionSheetView *)actionSheet clickItem:(ActionSheetButton *)item {
    ActionSheetModel *model = item.model;
    if (model.type == ActionSheetModel_SentToFriend)
    {
        [self sentToFriend];
        NSLog(@"发送给朋友");
    }
    
    if (model.type == ActionSheetModel_Collection)
    {
        [self collection];
        NSLog(@"收藏");
    }
    
    if (model.type == ActionSheetModel_Save)
    {
        [self save];
        NSLog(@"保存本地");
    }

}

- (void)sentToFriend {
    NSLog(@"发送给朋友");
}

- (void)collection {
    NSLog(@"收藏");
}

- (void)save {
    if ([self.videoUrlString hasPrefix:@"http://"] || [self.videoUrlString hasPrefix:@"https://"])
    {
        [self downloadVideo];
    }
}

- (void)downloadVideo {
    NSString *domainUrl = self.videoUrlString;
    NSURLRequest *request =[NSURLRequest requestWithURL:[NSURL URLWithString:domainUrl] cachePolicy:1 timeoutInterval:15.0f];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSMutableString * path = [[NSMutableString alloc]initWithString:documentsDirectory];
        NSString *timeString = [NSString stringWithFormat:@"%.0f", [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970]];
        [path appendString:[NSString stringWithFormat:@"/%@.mov", timeString]];
        
        NSLog(@"path == %@", path);
        
        if ([data writeToFile:path atomically:YES])
        {
            NSLog(@"mov写入成功");
            UIImageWriteToSavedPhotosAlbum([UIImage imageWithContentsOfFile:path], nil, nil, NULL);
            BOOL compatible = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path);
            if (compatible)
            {
                UISaveVideoAtPathToSavedPhotosAlbum(path, self, nil, NULL);
                NSLog(@"视频保存成功");
            }
            else
            {
                NSLog(@"视频保存失败");
            }
        }
        else
        {
            NSLog(@"mov写入失败");
        }
    }];
}

#pragma mark -
- (void)dealloc {
    [self.item removeObserver:self forKeyPath:@"status" context:nil];
    [self.item removeObserver:self forKeyPath:@"loadedTimeRanges" context:nil];
    [self.player removeTimeObserver:self.timeObserver];
    self.player = nil;
}
@end
