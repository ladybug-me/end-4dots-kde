#!/usr/bin/env python3
import codecs
import json
import sys
import urllib.request


def stream_items(url):
    decoder = json.JSONDecoder()
    utf8 = codecs.getincrementaldecoder("utf-8")()
    buffer = ""
    with urllib.request.urlopen(url, timeout=20) as response:
        while True:
            chunk = response.read(8192)
            if not chunk:
                break
            buffer += utf8.decode(chunk)
            pos = 0
            while True:
                while pos < len(buffer) and buffer[pos] in " \t\r\n,[":
                    pos += 1
                if pos >= len(buffer) or buffer[pos] == "]":
                    break
                try:
                    item, end = decoder.raw_decode(buffer, pos)
                except ValueError:
                    break
                yield item
                pos = end
            buffer = buffer[pos:]


for item in stream_items(sys.argv[1]):
    print(json.dumps(item, separators=(",", ":")), flush=True)
