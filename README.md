# Razer Chroma (MacOS)

after buying Razer headphones I was disapointed that I cannot programmatically change color.
But thanks to [Benjamin Dobell](https://github.com/Benjamin-Dobell) and his awsome library [GERazerKit](https://github.com/Benjamin-Dobell/GERazerKit)
I wrote simple console tool that can do it.

## Usage

Program accepts 4 arguments: device id(integer), Red Green Blue (floats) and optional effect type `static` or `breathing`
Example: `./chroma 4 1 0 0.0` sets Headphones to Red. `./chroma 4 0 1 0 static` sets Headphones to Green. `./chroma 4 0 1 0 breathing` sets Headphones to Green with breathing effect.
Device ID is small number (usually less than 15), so you should just try them all or use [monitor](https://github.com/Benjamin-Dobell/GERazerKit/tree/master/Tools)

Btw, do not forget to setup `Razer Synapse`

## Why

I'm using this with [Hammerspoon](http://www.hammerspoon.org) and Pomodoro Technique. When I'm in flow my Headphones are red so my family should not interrupt.

## How to build

Clone repo and just start XCode. Or you can download program from [release](https://github.com/skrypka/razer-chroma-macos/releases/tag/0.2).
