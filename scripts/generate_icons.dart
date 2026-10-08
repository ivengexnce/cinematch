// ignore_for_file: avoid_print, prefer_const_declarations
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

// ─── PNG encoder (stdlib only) ────────────────────────────────────────────────
Uint8List _makeChunk(List<int> name, List<int> data) {
  final buf = BytesBuilder();
  final len = data.length;
  buf.add([len >> 24 & 0xFF, len >> 16 & 0xFF, len >> 8 & 0xFF, len & 0xFF]);
  buf.add(name);
  buf.add(data);
  // CRC over name + data
  int crc = 0xFFFFFFFF;
  for (final b in [...name, ...data]) {
    crc ^= b;
    for (int k = 0; k < 8; k++) {
      if (crc & 1 != 0) {
        crc = (crc >> 1) ^ 0xEDB88320;
      } else {
        crc >>= 1;
      }
    }
  }
  crc = ~crc & 0xFFFFFFFF;
  buf.add([crc >> 24 & 0xFF, crc >> 16 & 0xFF, crc >> 8 & 0xFF, crc & 0xFF]);
  return buf.toBytes();
}

// Simple Adler-32 zlib compress (deflate stored, no compression for simplicity)
Uint8List _zlibCompress(Uint8List data) {
  // Use zlib header + deflate uncompressed blocks
  final out = BytesBuilder();
  // Zlib header: CMF=0x78, FLG makes it divisible by 31
  out.add([0x78, 0x01]);

  // Write in 65535-byte blocks
  int offset = 0;
  while (offset < data.length) {
    final blockLen = min(65535, data.length - offset);
    final isLast = (offset + blockLen) >= data.length;
    // BFINAL + BTYPE=00 (no compression)
    out.add([isLast ? 0x01 : 0x00]);
    // LEN and NLEN (one's complement)
    out.add([blockLen & 0xFF, (blockLen >> 8) & 0xFF]);
    out.add([(~blockLen) & 0xFF, (~blockLen >> 8) & 0xFF]);
    out.add(data.sublist(offset, offset + blockLen));
    offset += blockLen;
  }

  // Adler-32 checksum
  int s1 = 1, s2 = 0;
  for (final b in data) {
    s1 = (s1 + b) % 65521;
    s2 = (s2 + s1) % 65521;
  }
  final adler = (s2 << 16) | s1;
  out.add([adler >> 24 & 0xFF, adler >> 16 & 0xFF, adler >> 8 & 0xFF, adler & 0xFF]);
  return out.toBytes();
}

Uint8List makePng(int w, int h, List<List<List<int>>> pixels) {
  // pixels[y][x] = [R,G,B,A]
  final rawRows = BytesBuilder();
  for (final row in pixels) {
    rawRows.addByte(0); // filter: None
    for (final px in row) {
      rawRows.add(px);
    }
  }
  final compressed = _zlibCompress(rawRows.toBytes());

  final png = BytesBuilder();
  png.add([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]); // PNG signature

  // IHDR
  final ihdr = BytesBuilder();
  void addInt32(int v) => ihdr.add([v >> 24 & 0xFF, v >> 16 & 0xFF, v >> 8 & 0xFF, v & 0xFF]);
  addInt32(w); addInt32(h);
  ihdr.add([8, 6, 0, 0, 0]); // bit depth=8, RGBA, compression=0, filter=0, interlace=0
  png.add(_makeChunk([0x49,0x48,0x44,0x52], ihdr.toBytes())); // IHDR

  png.add(_makeChunk([0x49,0x44,0x41,0x54], compressed)); // IDAT
  png.add(_makeChunk([0x49,0x45,0x4E,0x44], []));          // IEND

  return png.toBytes();
}

// ─── Pixel painter ────────────────────────────────────────────────────────────
const bg        = [11,  11,  15,  255]; // Obsidian
const vermilion = [226, 61,  40,  255]; // #E23D28
const amber     = [255, 179, 0,   255]; // #FFB300
const trans     = [0,   0,   0,   0  ]; // transparent

void drawCircle(List<List<List<int>>> pix, int cx, int cy, int r, List<int> c) {
  final h = pix.length, w = pix[0].length;
  for (int y = max(0, cy - r); y < min(h, cy + r + 1); y++) {
    for (int x = max(0, cx - r); x < min(w, cx + r + 1); x++) {
      if ((x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r) pix[y][x] = c;
    }
  }
}

void drawRing(List<List<List<int>>> pix, int cx, int cy, int ro, int ri, List<int> c) {
  final h = pix.length, w = pix[0].length;
  for (int y = max(0, cy - ro); y < min(h, cy + ro + 1); y++) {
    for (int x = max(0, cx - ro); x < min(w, cx + ro + 1); x++) {
      final d2 = (x - cx) * (x - cx) + (y - cy) * (y - cy);
      if (d2 >= ri * ri && d2 <= ro * ro) pix[y][x] = c;
    }
  }
}

void roundCorners(List<List<List<int>>> pix, int r) {
  final h = pix.length, w = pix[0].length;
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final nx = (x < w ~/ 2) ? r : w - 1 - r;
      final ny = (y < h ~/ 2) ? r : h - 1 - r;
      if ((x < r || x >= w - r) && (y < r || y >= h - r)) {
        final d2 = (x - nx) * (x - nx) + (y - ny) * (y - ny);
        if (d2 > r * r) pix[y][x] = trans;
      }
    }
  }
}

Uint8List makeIcon(int s) {
  final pix = List.generate(s, (_) => List.generate(s, (_) => [...bg]));

  final cx = s ~/ 2, cy = s ~/ 2;
  final outerR = (s * 0.42).round();
  final ringW  = max(2, s ~/ 20);

  // Outer film-reel ring
  drawRing(pix, cx, cy, outerR, outerR - ringW, vermilion);

  // Sprocket holes
  for (int i = 0; i < 6; i++) {
    final angle = i * pi / 3;
    final hr = (outerR * 0.88).round();
    final hx = cx + (hr * cos(angle)).round();
    final hy = cy + (hr * sin(angle)).round();
    drawCircle(pix, hx, hy, max(1, s ~/ 28), bg);
  }

  // Inner hub ring
  final innerR = (s * 0.18).round();
  drawRing(pix, cx, cy, innerR, innerR - ringW, vermilion);

  // "C" arc in amber
  final letterR = (s * 0.13).round();
  final letterW = max(2, s ~/ 22);
  for (int y = 0; y < s; y++) {
    for (int x = 0; x < s; x++) {
      final dx = x - cx, dy = y - cy;
      final d2 = dx * dx + dy * dy;
      final loR = letterR - letterW, hiR = letterR;
      if (d2 >= loR * loR && d2 <= hiR * hiR) {
        final angleDeg = atan2(dy.toDouble(), dx.toDouble()) * 180 / pi;
        if (angleDeg < -40 || angleDeg > 40) pix[y][x] = [...amber];
      }
    }
  }

  // Amber accent dot
  final dotR = max(1, s ~/ 22);
  final dotX = cx + (outerR * 0.55).round();
  final dotY = cy - (outerR * 0.55).round();
  drawCircle(pix, dotX, dotY, dotR, amber);

  // Round corners
  roundCorners(pix, s ~/ 5);

  return makePng(s, s, pix);
}

void main() {
  final resDir = r'D:\wmaprac\android\app\src\main\res';
  final sizes = {
    'mipmap-mdpi':    48,
    'mipmap-hdpi':    72,
    'mipmap-xhdpi':   96,
    'mipmap-xxhdpi':  144,
    'mipmap-xxxhdpi': 192,
  };

  print('Generating CineMatch launcher icons...');
  for (final entry in sizes.entries) {
    final path = '$resDir\\${entry.key}\\ic_launcher.png';
    final data = makeIcon(entry.value);
    File(path).writeAsBytesSync(data);
    print('  ✓  ${entry.key}/ic_launcher.png  (${entry.value}x${entry.value}, ${data.length} bytes)');
  }

  // Replace the app_logo asset too
  final logoPath = r'D:\wmaprac\assets\images\app_logo.png';
  final logoData = makeIcon(192);
  File(logoPath).writeAsBytesSync(logoData);
  print('  ✓  assets/images/app_logo.png  (192x192, ${logoData.length} bytes)');

  print('\nAll icons generated successfully!');
}
