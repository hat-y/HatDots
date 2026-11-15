"""Unit tests for common/bin/meet-rec (stdlib only, no real ffmpeg/pactl)."""
import datetime as dt
import importlib.machinery
import importlib.util
import sys
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "meet-rec"
_loader = importlib.machinery.SourceFileLoader("meet_rec", str(SCRIPT))
_spec = importlib.util.spec_from_loader("meet_rec", _loader)
mr = importlib.util.module_from_spec(_spec)
sys.modules["meet_rec"] = mr
_loader.exec_module(mr)

S = mr.Segment


class PureLogic(unittest.TestCase):
    def test_parse_whisper_json(self):
        data = {"transcription": [
            {"text": "  hola   mundo ", "offsets": {"from": 10, "to": 500}},
            {"text": "[BLANK_AUDIO]", "offsets": {"from": 0, "to": 1}},
            {"text": "(risas)", "offsets": {"from": 0, "to": 1}},
            {"text": "   ", "offsets": {"from": 0, "to": 1}},
            {"text": "...", "offsets": {"from": 0, "to": 1}},
        ]}
        self.assertEqual(mr.parse_whisper_json(data, "Yo"), [S(10, 500, "Yo", "hola mundo")])
        self.assertEqual(mr.parse_whisper_json({}, "Yo"), [])

    def test_drop_echo(self):
        mine = [S(0, 1000, "Yo", "Hola, ¿qué tal?"), S(0, 1000, "Yo", "otra cosa distinta"),
                S(5000, 6000, "Yo", "Hola que tal")]
        others = [S(0, 1000, "Otros", "hola que tal")]
        kept = mr.drop_echo(mine, others)
        self.assertEqual([s.text for s in kept], ["otra cosa distinta", "Hola que tal"])

    def test_merge_segments(self):
        segs = [S(5000, 6000, "Yo", "c"), S(0, 1000, "Yo", "a"), S(1500, 2000, "Yo", "b"),
                S(2100, 2500, "Otros", "x")]
        out = mr.merge_segments(segs)
        self.assertEqual(out, [S(0, 2000, "Yo", "a b"), S(2100, 2500, "Otros", "x"),
                               S(5000, 6000, "Yo", "c")])

    def test_fmt(self):
        self.assertEqual(mr.fmt_ts(3_725_000), "01:02:05")
        self.assertEqual(mr.fmt_ts(-5), "00:00:00")
        self.assertEqual(mr.fmt_duration(120), "2 min")
        self.assertEqual(mr.fmt_duration(3900), "1 h 05 min")

    def test_slugify(self):
        self.assertEqual(mr.slugify("Reunión Señor Pérez!"), "reunion-senor-perez")
        self.assertEqual(len(mr.slugify("a" * 100)), 40)

    def test_render_markdown(self):
        md = mr.render_markdown("Daily", dt.datetime(2026, 1, 2, 9, 30), 600,
                                {"Yo": "y.ogg", "Otros": "o.ogg"}, [S(65000, 70000, "Yo", "hola")])
        self.assertIn("date: 2026-01-02", md)
        self.assertIn("# Daily — 2026-01-02 09:30", md)
        self.assertIn("- **Duración:** 10 min", md)
        self.assertIn("**[00:01:05] Yo:** hola", md)
        empty = mr.render_markdown("D", dt.datetime(2026, 1, 2, 9, 30), 0,
                                   {"Yo": "y", "Otros": "o"}, [])
        self.assertIn("_No se detectó habla._", empty)


OUT = Path("/tmp/x.ogg")
TAIL = ["-ac", "1", "-ar", "16000", "-c:a", "libopus", "-b:a", "24k", "/tmp/x.ogg"]
HEAD = ["ffmpeg", "-nostdin", "-loglevel", "error", "-y"]


class PlatformSeam(unittest.TestCase):
    def test_linux_sources_use_pactl(self):
        calls = []

        def pactl(*a):
            calls.append(a)
            return {"get-default-source": "mic_src", "get-default-sink": "sink0"}[a[0]]

        self.assertEqual(mr.capture_sources("linux", {}, pactl=pactl), ("mic_src", "sink0.monitor"))
        self.assertEqual(calls, [("get-default-source",), ("get-default-sink",)])

    def test_linux_ffmpeg_argv(self):
        self.assertEqual(mr.ffmpeg_record_argv("linux", "mic_src", OUT),
                         HEAD + ["-f", "pulse", "-i", "mic_src"] + TAIL)

    def test_darwin_sources_defaults(self):
        self.assertEqual(mr.capture_sources("darwin", {}), (":default", ":BlackHole 2ch"))

    def test_darwin_sources_env(self):
        env = {"MEET_REC_MAC_MIC": "MacBook Pro Microphone", "MEET_REC_MAC_LOOPBACK": "Loop"}
        self.assertEqual(mr.capture_sources("darwin", env),
                         (":MacBook Pro Microphone", ":Loop"))

    def test_darwin_ffmpeg_argv(self):
        self.assertEqual(mr.ffmpeg_record_argv("darwin", ":default", OUT),
                         HEAD + ["-f", "avfoundation", "-i", ":default"] + TAIL)

    def test_unsupported_platform(self):
        for fn in (lambda: mr.capture_sources("win32", {}),
                   lambda: mr.ffmpeg_record_argv("win32", "x", OUT),
                   lambda: mr.notifier_argv("win32", "m")):
            with self.assertRaises(SystemExit) as cm:
                fn()
            self.assertIn("no soportada", str(cm.exception.code))

    def test_notifier_linux(self):
        self.assertEqual(mr.notifier_argv("linux", "hola", "critical"),
                         ["notify-send", "-u", "critical", "-t", "4000", "Meet Rec", "hola"])

    def test_notifier_darwin(self):
        self.assertEqual(mr.notifier_argv("darwin", 'di "hola"'),
                         ["osascript", "-e",
                          'display notification "di \\"hola\\"" with title "Meet Rec"'])

    def test_loopback_present_and_missing(self):
        listing = ("[AVFoundation indev] AVFoundation audio devices:\n"
                   "[AVFoundation indev] [0] BlackHole 2ch\n"
                   "[AVFoundation indev] [1] MacBook Pro Microphone\n")
        self.assertIsNone(mr.check_loopback(listing, ":BlackHole 2ch"))
        msg = mr.check_loopback(listing, ":Otro")
        self.assertIn("brew install --cask blackhole-2ch", msg)
        self.assertIn("Audio MIDI Setup", msg)
        self.assertIn("Multi-Output", msg)

    def test_whisper_hint(self):
        self.assertIn("brew install whisper-cpp", mr.whisper_hint("darwin"))
        self.assertIn("sudo pacman -S whisper-cpp", mr.whisper_hint("linux"))


if __name__ == "__main__":
    unittest.main()
