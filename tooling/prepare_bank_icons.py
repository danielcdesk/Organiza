"""Normalize user-supplied bank icons into square Flutter assets."""

from pathlib import Path
from PIL import Image
import sys


SOURCE_NAMES = {
    "bradesco": "unnamed.png",
    "santander": "unnamed (1).png",
    "nubank": "images.jpg",
    "caixa": "images (1).jpg",
    "banco-do-brasil": "BB-logo1_(cropped).jpg",
    "inter": "3afb1b054f7646acabdcd1e953f77c7d_thumb1.jpg",
    "itau": "2023_Itaú_Unibanco_Logo.png",
}


def normalize(source: Path, output: Path) -> None:
    image = Image.open(source).convert("RGB")
    edge = max(image.size)
    canvas = Image.new("RGB", (edge, edge), image.getpixel((0, 0)))
    canvas.paste(image, ((edge - image.width) // 2, (edge - image.height) // 2))
    canvas.thumbnail((256, 256), Image.Resampling.LANCZOS)
    canvas.save(output, "PNG", optimize=True)


def main() -> None:
    source_dir = Path(sys.argv[1])
    output_dir = Path(sys.argv[2])
    output_dir.mkdir(parents=True, exist_ok=True)
    for slug, filename in SOURCE_NAMES.items():
        normalize(source_dir / filename, output_dir / f"{slug}.png")


if __name__ == "__main__":
    main()
