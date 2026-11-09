"""Crop a Studio viewport capture to the centred 16:9 UI canvas: crop_capture.py <capture.jpg> <out.png>"""
import sys
from PIL import Image
im = Image.open(sys.argv[1]).convert("RGB")
w, h = im.size
cw = round(h * 16 / 9)
x = (w - cw) // 2
im.crop((x, 0, x + cw, h)).save(sys.argv[2])
print(sys.argv[2], cw, h)
