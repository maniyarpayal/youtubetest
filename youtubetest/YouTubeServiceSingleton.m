/*
 * Copyright (c) 2019 JiyanoVision.TV / Coopérative Enfant Nature
 */

#import <GTLRYouTubeService.h>
#import "YouTubeServiceSingleton.h"

@implementation YouTubeServiceSingleton

+ (GTLRYouTubeService *)sharedInstance {
    if (sharedInstance == nil) {
        sharedInstance = [GTLRYouTubeService init];
    }
    return sharedInstance;
}

@end