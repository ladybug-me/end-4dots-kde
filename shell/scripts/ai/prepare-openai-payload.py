#!/usr/bin/env python3
import sys
import json
import os
import subprocess
import base64
import urllib.parse
import io
from PIL import Image

MAX_DIMENSION = 4096

def convert_svg_to_png(svg_path):
    os.makedirs("/tmp/quickshell/ai", exist_ok=True)
    png_path = f"/tmp/quickshell/ai/converted_{os.path.basename(svg_path)}.png"
    try:
        subprocess.run(
            ["rsvg-convert", "-a", "-w", "2048", svg_path, "-o", png_path],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        return png_path
    except Exception:
        pass

    try:
        subprocess.run(
            ["magick", svg_path, png_path],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        return png_path
    except Exception:
        pass

    return svg_path

def get_mime_and_b64(raw_filepath):
    filepath = urllib.parse.unquote(raw_filepath)
    if filepath.startswith("file://"):
        filepath = filepath[7:]
    filepath = os.path.expanduser(filepath)

    if not os.path.isfile(filepath):
        return None, None

    try:
        mime = subprocess.check_output(
            ["file", "-b", "--mime-type", filepath],
            stderr=subprocess.DEVNULL
        ).decode().strip()
    except Exception:
        mime = "image/png"

    if mime == "image/svg+xml" or filepath.lower().endswith(".svg"):
        conv = convert_svg_to_png(filepath)
        if conv and os.path.isfile(conv):
            filepath = conv
            mime = "image/png"

    try:
        with Image.open(filepath) as im:
            width, height = im.size
            # Only resize if exceeding 4096px
            if max(width, height) > MAX_DIMENSION:
                im.thumbnail((MAX_DIMENSION, MAX_DIMENSION), Image.Resampling.LANCZOS)
                buf = io.BytesIO()
                im.save(buf, format="PNG")
                b64 = base64.b64encode(buf.getvalue()).decode("ascii")
                return "image/png", b64

        # Read original file directly at full quality if <= 4096px
        with open(filepath, "rb") as f:
            b64 = base64.b64encode(f.read()).decode("ascii")
        return mime, b64
    except Exception:
        try:
            with open(filepath, "rb") as f:
                b64 = base64.b64encode(f.read()).decode("ascii")
            return mime, b64
        except Exception:
            return None, None

def process_node(node):
    if isinstance(node, dict):
        if node.get("type") == "image_url" and isinstance(node.get("image_url"), dict):
            url_val = node["image_url"].get("url", "")
            if isinstance(url_val, str) and url_val.startswith("__LOCAL_IMAGE_FILE__:"):
                raw_path = url_val[len("__LOCAL_IMAGE_FILE__:"):]
                mime, b64 = get_mime_and_b64(raw_path)
                if mime and b64:
                    return {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:{mime};base64,{b64}"
                        }
                    }
                else:
                    return None
        new_dict = {}
        for k, v in node.items():
            processed_v = process_node(v)
            if processed_v is not None:
                new_dict[k] = processed_v
        return new_dict
    elif isinstance(node, list):
        new_list = []
        for item in node:
            processed_item = process_node(item)
            if processed_item is not None:
                new_list.append(processed_item)
        return new_list
    return node

def main():
    if len(sys.argv) < 3:
        sys.exit(1)

    input_path = sys.argv[1]
    output_path = sys.argv[2]

    try:
        with open(input_path, "r", encoding="utf-8") as f:
            data = json.load(f)

        processed = process_node(data)

        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(processed, f, ensure_ascii=False)
    except Exception as e:
        print(f"Error preparing payload: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
