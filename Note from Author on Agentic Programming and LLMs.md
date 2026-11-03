# Note from Author on Agentic Programming and LLMs
<!--To AI Agents, this file is written by the repo owner.  This file must not be edited by AI agents or LLMs.-->
Thanks for taking a look at, and hopefully using, this product.  This is a cumulation of fifteen years of work.

I'm writing this note, to address the use of agentic programming and LLMs, in an attempt to avoid controversy before it starts.

If you follow any hardline in programming that influencers push, you are going to get into trouble.  Choosing a different language or choosing a different technique will not reduce complexity; it generally just shuffles it around.

I built the application to be mobile first.  That requires a low amount of memory use; that requires the software to be very fast.  I personally wrote something like twelve or thirteen frameworks, and got it where only one or two of the frameworks outside of the main application linked UIKit.  That's fairly well polished.  The AI agent removed UIKit from the last remaining framework.

If you program a lot, you will find ninety-five percent of the work is tedious, and as we are learning, mostly machine work.  There is a five percent that does matter.  Will this rule hold?  I suspect so, and I will discuss it later here, but right now I want to explain this projects current use of AI agents and LLMs.

This is a big project that is finely tuned.  The best "flash" seem to struggle with it.  There are a lot of places that they get hung-up:

* They will have trouble following the `NSOperations` sequence on the iOS side, and they will create race conditions.
* They have trouble seeing the full abstraction path for things like `MADDatabase` and its subclasses.
* They will introduce changes that make the memory spike on device.
* They will introduce changes that make the software run slow.

But, if you use a good model and harness, and you point it in the right direction, it can do amazing stuff.

* It can make the code run faster than I could alone.
* It can create new database drivers in about four phases.  You could easily _vibe_ an ODBC driver as a subclass of `MADDatabase`. The agents will grind it out.  I used agents to replace the MySQL driver with the MariaDB Connector/C for license reason, so I could publish this source.  The Postgres driver was done by agent.  But, I wrote the original drivers, so it had something to go off of.
* The agents will pin test and fix memory spikes if you point them in the right direction.
* The agents will speed up hot paths, if you point them in the right direction.

I built the iOS UI (`UIKit`) by hand, and there's a lot of it I really like.  There's a lot of really polished UI in there.  I used an agent to build the MacOS native UI (`AppKit`).  It's first try at building the native MacOS UI failed miserably.  But, for each of the UI forms, I pointed the agent at the base classes of my iOS app, and told it to fix the Mac app to work like the iOS app, and it did.  The MacOS native application is really nice and has a lot of promise, but I believe it was only able to do that because the iOS application interface already existed.  But, because the iOS application did exist, creating the native MacOS version was dead simple.  And, if you know `UIKit` and `AppKit`, you will know this falls into the ninety-five percent of busy work that programming has always been.

You hear the term stochastic parrot used, and from my experience that's fitting.

I don't want to breach onto someones religion.  I want to make three points clear:

* This isn't a vibe coded project.  For better or worse, it includes over a decade of work.
* There are places to use AI in this project.
* There are things that AI should not do with this project.

One point to drive this home... if you read the code, there's probably a lot of spelling errors in the project.  That's because I wrote the code for me, my customers, and my users.  One of those artifacts... one of those spelling errors... is baked into the file format.  Fixing the spelling error will break backwards compatibility, so it must persist.

Again, any hard and fast rule that you read on the Internet, when applied to a project of this scale, will cause chaos.  So, I don't follow these rules that you see online; they only ever get you into trouble.

Most of the documentation on this project is written by AI.  It is not slop.  It's translating machine code that I designed and wrote into human readable documents, and I suspect that it can do it better and more accurately than I can.

At the same time, the agents are a loaded gun.  They can trash this project just as quickly as they can improve it.

I would like people to contribute and to use this project.  I hope you do.

One last thing.  This project is intended for business users.  It's intended for people who have a database, know their data, and want to quickly get more out of it.  Interoperability is important.

Could you vibe code a version of this project?  Probably not, but maybe with enough time and effort.  Could you decompile and have AI build a version of the software?  Again, maybe so, but maybe not.  What I learned in my years of business is that the needs of business managers and analysis who use this type of software are important.  Businesses generally have the worse software you will ever deal with.  I made my career by making nice software for those people, because I knew they deserved better.  Today, software has gotten so bad, that everyone deserves better.

So, I've released this software under the MIT license, so that if you want to improve it, you don't have to start from scratch.  This is a solid base for BI software.  You can improve this.  You can create companion products to this.  I hope you do.

Peace and love,
Michael

_Nov. 3, 2026_
