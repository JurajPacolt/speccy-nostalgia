"""A broad nib pen - the tool the blackletter alphabet of the logo is drawn with.

Blackletter is not drawn, it is written: a wide nib is held at a fixed angle and
dragged along the paper, and the shape of the nib does all the work. A stroke
pulled downwards leaves a heavy stem with a slanted head and foot - the diamond
ends of the gothic letters - and the same stroke pulled along the angle of the
nib leaves a hairline. So the alphabet here is a list of paths, not a list of
pixels, and this pen turns them into ink.
"""

from __future__ import annotations

import math
from typing import Callable, Iterable, List, Sequence, Tuple

Point = Tuple[float, float]
Plot = Callable[[int, int], None]


def line(plot: Plot, x0: float, y0: float, x1: float, y1: float) -> None:
    """The pixels of a straight line, ends included."""
    x0, y0 = int(round(x0)), int(round(y0))
    x1, y1 = int(round(x1)), int(round(y1))
    dx = abs(x1 - x0)
    dy = -abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    error = dx + dy
    while True:
        plot(x0, y0)
        if x0 == x1 and y0 == y1:
            return
        twice = 2 * error
        if twice >= dy:
            error += dy
            x0 += sx
        if twice <= dx:
            error += dx
            y0 += sy


def bezier(p0: Point, p1: Point, p2: Point, steps: int = 24) -> List[Point]:
    """A quadratic curve as a list of points, for the round parts of a letter."""
    out = []
    for step in range(steps + 1):
        t = step / float(steps)
        u = 1.0 - t
        out.append(
            (
                u * u * p0[0] + 2 * u * t * p1[0] + t * t * p2[0],
                u * u * p0[1] + 2 * u * t * p1[1] + t * t * p2[1],
            )
        )
    return out


def walk(points: Sequence[Point], step: float = 0.2) -> Iterable[Point]:
    """Every point along a path, close enough that the nib leaves no gap."""
    if not points:
        return
    yield points[0]
    for index in range(1, len(points)):
        x0, y0 = points[index - 1]
        x1, y1 = points[index]
        length = math.hypot(x1 - x0, y1 - y0)
        count = max(1, int(math.ceil(length / step)))
        for part in range(1, count + 1):
            t = part / float(count)
            yield (x0 + (x1 - x0) * t, y0 + (y1 - y0) * t)


class Pen:
    """A nib of a given width, held at a fixed angle to the paper."""

    def __init__(self, width: float = 6.0, angle: float = -30.0) -> None:
        self.width = width
        self.angle = math.radians(angle)

    def nib(self, x: float, y: float) -> Tuple[Point, Point]:
        half = (self.width - 1.0) / 2.0
        dx = half * math.cos(self.angle)
        dy = half * math.sin(self.angle)
        return ((x - dx, y - dy), (x + dx, y + dy))

    def stamp(self, plot: Plot, x: float, y: float) -> None:
        (x0, y0), (x1, y1) = self.nib(x, y)
        line(plot, x0, y0, x1, y1)

    def stroke(self, plot: Plot, points: Sequence[Point], step: float = 0.2) -> None:
        """Pull the nib along a path."""
        for x, y in walk(points, step):
            self.stamp(plot, x, y)

    def dot(self, plot: Plot, x: float, y: float) -> None:
        """A single touch of the nib - the diamond of the gothic letters."""
        self.stamp(plot, x, y)


class Brush:
    """A round brush, for the pictures - it is as thick in every direction.

    The pen is right for letters, where the direction of the stroke has to
    change its weight, but a branch of a tree has to keep the same thickness
    wherever it turns, so it is painted with this instead.
    """

    def __init__(self, size: float = 2.0) -> None:
        self.radius = size / 2.0

    def stamp(self, plot: Plot, x: float, y: float) -> None:
        radius = self.radius
        for py in range(int(math.floor(y - radius)), int(math.ceil(y + radius)) + 1):
            for px in range(int(math.floor(x - radius)), int(math.ceil(x + radius)) + 1):
                if (px + 0.5 - x) ** 2 + (py + 0.5 - y) ** 2 <= radius * radius:
                    plot(px, py)

    def stroke(self, plot: Plot, points: Sequence[Point], step: float = 0.25) -> None:
        for x, y in walk(points, step):
            self.stamp(plot, x, y)


class Sheet:
    """A small sheet of paper the pen writes one letter on."""

    def __init__(self, width: int, height: int) -> None:
        self.width = width
        self.height = height
        self.pixels = [bytearray(width) for _ in range(height)]

    def plot(self, x: int, y: int) -> None:
        if 0 <= x < self.width and 0 <= y < self.height:
            self.pixels[y][x] = 1

    def art(self) -> str:
        """The letter as ASCII art, the form the rest of the tools read."""
        return "\n".join(
            "".join("#" if value else "." for value in row) for row in self.pixels
        )

    def used_columns(self) -> Tuple[int, int]:
        used = [
            x
            for x in range(self.width)
            if any(self.pixels[y][x] for y in range(self.height))
        ]
        if not used:
            return (0, 0)
        return (used[0], used[-1])
