//
//  YSVideoPlayerViewController.m
//  VideoViewer
//
//  Created by Barbara Rodeker on 1/27/14.
//
//  Created by Barbara Rodeker on 1/27/14.
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance
//  with the License.  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.
//

#import "YSVideoPlayerViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "YSTableViewFrameCell.h"
#import "YSFramesTableView.h"

@interface YSVideoPlayerViewController ()

@property (nonatomic, strong) MPMoviePlayerController *moviePlayer;
@property (nonatomic, strong) NSMutableArray *frames;
@property (nonatomic, assign) NSInteger lastIndex;

@property (nonatomic, weak) IBOutlet YSFramesTableView *framesTable;


@end

@implementation YSVideoPlayerViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.moviePlayer = [[MPMoviePlayerController alloc] init];
    self.moviePlayer.view.frame = self.view.frame;
    
    [self.framesTable registerNib:[UINib nibWithNibName:@"YSTableViewFrameCell" bundle:nil] forCellReuseIdentifier:@"Cell"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(thumbnailsLoaded:) name:MPMoviePlayerThumbnailImageRequestDidFinishNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playBackLoadStateChange:) name:MPMoviePlayerLoadStateDidChangeNotification object:nil];

}

- (void)thumbnailsLoaded:(NSNotification *)notification {
    if (!notification.userInfo[MPMoviePlayerThumbnailErrorKey]) {
        NSInteger index = [notification.userInfo[MPMoviePlayerThumbnailTimeKey] integerValue];
        [self.frames insertObject:notification.userInfo[MPMoviePlayerThumbnailImageKey] atIndex:index];
        if (index >= (NSInteger)self.moviePlayer.duration)
            [self.framesTable reloadData];
    }
}

- (void)playBackLoadStateChange:(NSNotification *)notification {
    if (self.moviePlayer.loadState != MPMovieLoadStateUnknown) {
        self.frames = [NSMutableArray arrayWithCapacity:(NSInteger)self.moviePlayer.duration+1];
        NSMutableArray *times = [NSMutableArray array];
        for (NSInteger frameNumber = 0; frameNumber < self.moviePlayer.duration; frameNumber++) {
            [times addObject:[NSNumber numberWithFloat:(CGFloat)frameNumber]];
        }
        [self.moviePlayer requestThumbnailImagesAtTimes:times timeOption:MPMovieTimeOptionNearestKeyFrame];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)videoSelectPressed:(id)sender {
    [self.frames removeAllObjects];
    UIImagePickerController *videoPickerVC = [[UIImagePickerController alloc] init];
    videoPickerVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    videoPickerVC.mediaTypes = @[(NSString *)kUTTypeMovie];
    videoPickerVC.delegate = self;
    videoPickerVC.allowsEditing = NO;
    
    [self presentViewController:videoPickerVC animated:YES completion:nil];
}

#pragma mark UIImagePickerControllerDelegate


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    
    if (CFStringCompare ((CFStringRef) mediaType, kUTTypeMovie, 0)
        == kCFCompareEqualTo) {
        
        NSURL *moviePath = info[UIImagePickerControllerMediaURL];
        self.moviePlayer.contentURL = moviePath;
        [self.view addSubview:self.moviePlayer.view];
        [self.view sendSubviewToBack:self.moviePlayer.view];
        [self.moviePlayer prepareToPlay];
        [self.moviePlayer play];
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.frames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YSTableViewFrameCell *cell = (YSTableViewFrameCell *)[self.framesTable dequeueReusableCellWithIdentifier:@"Cell"];
    cell.frameImage.image = self.frames[indexPath.row];
    self.lastIndex = indexPath.row;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.moviePlayer pause];
    [self.moviePlayer setCurrentPlaybackTime:indexPath.row];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.moviePlayer pause];
    [self.moviePlayer setCurrentPlaybackTime:self.lastIndex];
}

@end
