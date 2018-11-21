# Niceland

Download (old/buggy) builds from: https://tassup.itch.io/niceland

This is a procedural world generator that is ment to be used as a base for an open world game. Made with Godot 3.0 alpha 2.

The idea is that if someone wants to make an open world game with infinite landscape to explore, they can just grab this project from GitHub and start making their own game over it. The sources are released with MIT-licence, and anyone can use them however they want. No need to give me credit, but if someone uses Niceland for something, I would love to see it.

Placeholder 3D-assets came from Procjam website: http://www.procjam.com/art/khalkeus.html
They were made by Khalkeus.

Terrain base image is composed from NASA's heightmap images of planet Earth. Niceland doesn't use this image as a normal heightmap, but instead mixes and juggles it around to create endless variations of mountains, lakes and stuff. Usually terrain systems use either a heightmap image, fractal or a noise algorithm to create the ground, but Niceland kinda blends all those things together.

Grab the sources and have a nice day!

Update: Complete rewrite, no more random crashes, use Open Simplex noise everywhere instead of heightmaps.
