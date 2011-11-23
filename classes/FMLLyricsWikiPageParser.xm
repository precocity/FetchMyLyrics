/*******************************************************************************
 * FMLLyricsWikiPageParser.xm
 * FetchMyLyrics
 *
 * NOTE: This class is HIGHLY error prone.
 *
 * Copyright (C) 2011 by Le Son.
 * Licensed under the MIT License, bundled with the source or available here:
 *     https://raw.github.com/precocity/FetchMyLyrics/master/LICENSE
 ******************************************************************************/

#import "FMLLyricsWikiPageParser.h"
#import "FMLCommon.h"

@implementation FMLLyricsWikiPageParser

@synthesize URLToPage = _URLToPage, lyrics = _lyrics, done = _done;

- (id)init
{
    if ((self = [super init]))
    {
        _URLToPage = nil;
        _scraperWebView = nil;
        _dummyWindow = nil;
        _done = YES;
        _lyrics = nil;
    }

    return self;
}

- (void)dealloc
{
    if (_scraperWebView)
    {
        _scraperWebView.delegate = nil;
        [_scraperWebView removeFromSuperview];
        [_scraperWebView release];
    }
    if (_dummyWindow)
        [_dummyWindow release];
    if (_lyrics)
        [_lyrics release];

    self.URLToPage = nil;

    [super dealloc];
}

- (void)beginParsing
{
    if (!self.URLToPage)
        return;

    NSData *data = [NSData dataWithContentsOfURL:self.URLToPage];
    if (data)
    {
        NSString *pageHTML = [[[NSString alloc] initWithData:data
                                                    encoding:NSUTF8StringEncoding] autorelease];

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            _dummyWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

            _scraperWebView = [[UIWebView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
            [_dummyWindow addSubview:_scraperWebView];
            _scraperWebView.delegate = self;
            [_scraperWebView loadHTMLString:pageHTML
                                    baseURL:self.URLToPage];
        }];

        _done = NO;
    }
    else
        _done = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // We are extracting the lyrics through JavaScript
    // Not the best idea (locks up the UI, slow, use lots of resource, etc.)
    // but we have no other choice (that is, until someone comes up with sometihng like BeautifulSoup for Python,
    // but for Objective-C). I might work on something like that in the future, but for now...

    // Note: This class _will_ break if LyricsWiki changes its layout.
    //       I'll add a few more sources to fetch lyrics from in the future.

    // Check if the lyrics page exist.
    // In most cases, it should (we are using its API, after all).
    NSString *fourOhFour = [webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName('body')[0].innerText.search('This page needs content. You can help by adding a sentence or a photo!')"];
    if (![fourOhFour isEqualToString:@"-1"])
    {
        _done = YES;
        return;
    }

    // The lyrics resides inside a <div class='lyricbox'>
    // First child is always a ringtone ad; get rid of this
    [webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('lyricbox')[0].removeChild(document.getElementsByClassName('lyricbox')[0].firstChild)"];

    // Last childs are also useless ads and empty divs
    // Lucky for us, right below the lyrics is a comment block
    // so we are looping till we hit the comment block.
    // But we can't let the loop run forever (or the UI will lock up forever), so we set a limit of 100 iterations
    NSString *lastChild;
    int iteration;
    for (iteration = 0; iteration < 100; iteration++)
    {
        lastChild = [webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('lyricbox')[0].lastChild.nodeType"];
        [webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('lyricbox')[0].removeChild(document.getElementsByClassName('lyricbox')[0].lastChild)"];
        // NOTE: if Element is a comment block, Element.nodeType = 8
        if ([lastChild isEqualToString:@"8"])
            break;
    }

    if (iteration == 100)
    {
        // The loop ran for too long; something must have gone wrong.
        _done = YES;
        return;
    }

    // Fetch lyrics (last Javascript, I swear!)
    NSString *lyrics = [webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('lyricbox')[0].innerText"];
    if ([lyrics rangeOfString:@"Unfortunately, we are not licensed to display the full lyrics for this song at the moment"].location != NSNotFound)
        lyrics = @"";
        // NOTE: Empty string denotes "didn't find anything, don't bother trying again next time"
        //       Why? LyricsWiki hasn't been able to obtain license for all songs.
        //       I don't really like the idea of showing a short excerpt.
        // Also: Fuck you music industry. I have said this before (in FMLLyricsOperation.xm) but whatever.

    _lyrics = [lyrics copy];
    _done = YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    _lyrics = nil;
    _done = YES;
}

@end
