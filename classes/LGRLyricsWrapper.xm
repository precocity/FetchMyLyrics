/*******************************************************************************
 * LGRLyricsWrapper.xm
 * L'Fetcher
 *
 * This program is free software. It comes without any warranty, to
 * the extent permitted by applicable law. You can redistribute it
 * and/or modify it under the terms of the Do What The Fuck You Want
 * To Public License, Version 2, as published by Sam Hocevar. See
 * http://sam.zoy.org/wtfpl/COPYING for more details.
 ******************************************************************************/

#import "LGRLyricsWrapper.h"

#define LGRTitleKey @"LGRTitleKey"
#define LGRArtistKey @"LGRArtistKey"
#define LGRLyricsKey @"LRGLyricsKey"

@implementation LGRLyricsWrapper

@synthesize title = _title, artist = _artist, lyrics = _lyrics;

- (id)init
{
    if ((self = [super init]))
    {
        _title = nil;
        _artist = nil;
        _lyrics = nil;
    }

    return self;
}

+ (id)lyricsWrapper
{
    return [[[self alloc] init] autorelease];
}

- (void)dealloc
{
    self.title = nil;
    self.artist = nil;
    self.lyrics = nil;

    [super dealloc];
}

/*
 * Below are NSCoding protocol methods.
 */
- (id)initWithCoder:(NSCoder *)coder
{
    if ((self = [super init]))
    {
        _title = [[coder decodeObjectForKey:LGRTitleKey] copy];
        _artist = [[coder decodeObjectForKey:LGRArtistKey] copy];
        _lyrics = [[coder decodeObjectForKey:LGRLyricsKey] copy];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_title forKey:LGRTitleKey];
    [coder encodeObject:_artist forKey:LGRArtistKey];
    [coder encodeObject:_lyrics forKey:LGRLyricsKey];
}

@end

