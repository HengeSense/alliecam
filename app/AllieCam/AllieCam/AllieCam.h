//
//  AllieCam.h
//  AllieCam
//
//  Created by Mark Blackwell on 11/12/12.
//  Copyright (c) 2012 Mark Blackwell. All rights reserved.
//


#ifdef DEBUG
#define DLog( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define DLog( s, ... )
#endif

