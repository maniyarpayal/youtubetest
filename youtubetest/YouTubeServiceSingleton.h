/*
 * Copyright (c) 2019 JiyanoVision.TV / Coopérative Enfant Nature
 */

// Basis library.
#import <Foundation/Foundation.h>

// GTLRYouTubeService class pre-declaration (~import).
@class GTLRYouTubeService;

/** Shared GTLRYouTubeService instance. */
static GTLRYouTubeService *sharedInstance;

/**
 * YouTubeService Singleton class.
 *
 * Initialize and furnish a shared GTLRYouTubeService instance.
 */
@interface YouTubeServiceSingleton : NSObject

/**
 * Furnish the shared GTLRYouTubeService instance.
 * Initialize it if necessary.
 *
 * @return the instance.
 */
+ (GTLRYouTubeService *)sharedInstance;

@end