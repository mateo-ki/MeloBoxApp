import 'package:flutter_test/flutter_test.dart';
import 'package:melobox_app/models/music.dart';

void main() {
  test('MusicTrack.fromApiJson reads songziheng search result fields', () {
    final track = MusicTrack.fromApiJson({
      'title': 'Song A',
      'author': 'Artist A',
      'url': 'https://example.com/song.mp3',
      'pic': 'https://example.com/cover.jpg',
      'lrc': 'https://example.com/song.lrc',
    });

    expect(track.title, 'Song A');
    expect(track.artist, 'Artist A');
    expect(track.url, 'https://example.com/song.mp3');
    expect(track.picUrl, 'https://example.com/cover.jpg');
    expect(track.lrcUrl, 'https://example.com/song.lrc');
  });

  test('parseLrcLines sorts timed lyrics and strips time tags', () {
    final lines = parseLrcLines('''
[00:12.50]Second line
[00:01.00]First line
[bad]Ignored line
''');

    expect(lines.length, 2);
    expect(lines[0].timeMs, 1000);
    expect(lines[0].text, 'First line');
    expect(lines[1].timeMs, 12500);
    expect(lines[1].text, 'Second line');
  });

  test('activeLyricIndex returns latest lyric before current position', () {
    final lines = [
      const MusicLyricLine(timeMs: 1000, text: 'A'),
      const MusicLyricLine(timeMs: 2500, text: 'B'),
      const MusicLyricLine(timeMs: 4000, text: 'C'),
    ];

    expect(activeLyricIndex(lines, Duration(milliseconds: 999)), -1);
    expect(activeLyricIndex(lines, Duration(milliseconds: 2500)), 1);
    expect(activeLyricIndex(lines, Duration(milliseconds: 5000)), 2);
  });
}
