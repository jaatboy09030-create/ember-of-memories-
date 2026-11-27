"""Generate + process the Blink demo voice-over (ElevenLabs eleven_v3), one file per caption line.
File name = blink/<bvn|bvm>_<sha1(caption)[:12]>.ogg  (bvn = narrator, Voice bus; bvm = a character in a memory, Memory bus)
The game finds the file from the caption text itself (BlinkCaption.say), so the scene needs no edits.
Usage: python tools/blink_voice_over.py <work dir with blink_lines.json> assets/audio
(blink_lines.json = [[beat, field, text], ...] extracted from scenes/prototypes/blink_demo.tscn; the
ElevenLabs key is read from your local Claude config, never stored here. Raw takes are cached in <work>/blink_raw.)
"""
import json, os, sys, hashlib, subprocess, urllib.request, concurrent.futures as cf

SCR, AUDIO = sys.argv[1], sys.argv[2]
OUT = os.path.join(AUDIO, "blink"); os.makedirs(OUT, exist_ok=True)
RAW = os.path.join(SCR, "blink_raw"); os.makedirs(RAW, exist_ok=True)
KEY = json.load(open(os.path.expanduser("~/.claude.json"), encoding="utf-8"))["mcpServers"]["elevenlabs"]["env"]["ELEVENLABS_API_KEY"]
VOICE = {"narrator": "Dgd9MUMSyPeTgbbDIZ0t", "mum": "eYO9Ven76ACQ8Me4zQK4", "dad": "pCL8Ua4MoAGISUaDmw69"}
TEMPO = {"narrator": 0.92, "mum": 0.95, "dad": 0.97}

lines = json.load(open(os.path.join(SCR, "blink_lines.json"), encoding="utf-8"))

BEAT_TONE = {
    "RoadBeat": "quietly, tired, reflective", "GateBeat": "quietly, uneasy", "PorchBeat": "quietly, uneasy",
    "LivingBeat": "warm, nostalgic, a faint smile", "KidBeat": "warm, nostalgic", "KitchenBeat": "warm, nostalgic, a faint smile",
    "GrandmaGoneBeat": "soft, sad", "LetterBeat": "quiet, hopeful, then worried",
    "DoorBeat": "tense, hushed", "TornBeat": "bitter, flat", "LeavingBeat": "tense, holding it together",
    "GoodbyeBeat": "quiet, guilty", "LaneBeat": "cold, flat, determined",
    "PostcardsBeat": "quiet, heavy", "WintersBeat": "quiet, heavy", "KitchenNowBeat": "quiet, realising, heavy",
    "TapedBeat": "quiet, choked up", "TruthBeat": "hushed, bracing himself", "LaneNightBeat": "hushed, shaken",
    "PhotoBeat": "soft, broken", "FireplaceBeat": "soft, broken, gentle", "HeadlightsBeat": "hushed, afraid, hopeful",
}
# index -> (speaker, direction, spoken text override)
CAST = {
    20: ("dad", "gently, quietly, from the stairs", None),
    35: ("dad", "low, worried, muffled, doing sums", None),
    36: ("mum", "whispering urgently", None),
    40: ("mum", "raised voice, pleading", None),
    41: ("dad", "angry, raised voice", None),
    42: ("mum", "hissing, urgent", None),
    43: ("dad", "shouting, furious", "If he wants to go, then go—"),
    53: ("mum", "quietly, tearful but steady", None),
    54: ("mum", "softly, voice breaking", None),
    55: ("mum", "pleading, crying", None),
    66: ("mum", "gentle, tired, writing a postcard", "Set your place at tea again. Your dad sat with it. He doesn't say much these days."),
    67: ("mum", "gentle, a sad little laugh", "Your dad won't let me touch the porch light. Says you'll want it on."),
    68: ("mum", "tired, fond", "Electric's gone up. He still won't let me touch the switch."),
    69: ("mum", "quiet, carefully cheerful", "They asked again if I want his coat taken down. I said he'll want it there when he comes in."),
    70: ("mum", "quiet, lonely", "Two cups in the morning. He lets his go cold. He always did."),
    71: ("mum", "trying to sound fine, worried underneath", "In for some tests. Back Thursday. I've told your dad to keep the fire in."),
    82: ("dad", "shouting, frustrated", None),
    83: ("dad", "shouting", None),
    84: ("dad", "voice dropping, tender but firm", None),
    85: ("mum", "softening, relieved", None),
    86: ("dad", "quiet, warm, a smile in his voice", None),
    99: ("narrator", "softly, writing a letter", None),
    100: ("narrator", "softly, writing a letter, trying to sound fine", None),
    101: ("narrator", "softly, stopping mid-sentence", None),
    113: ("mum", "cautious, frightened, calling out", None),
    114: ("mum", "a small gasp, stunned", None),
    115: ("mum", "crying, overwhelmed with love", None),
    116: ("mum", "whispering through tears, relieved", None),
}
SPECIAL = {
    92: "barely a whisper, devastated", 117: "warm, tearful, relieved", 118: "warm, tearful, gentle",
    119: "quiet, regretful", 120: "quiet, regretful", 121: "quiet, resolved", 87: "quiet, devastated",
}
SKIP = {15, 21, 103}  # already voiced in the scene (v_scarf, v_artist, v_letter)
SHOUT = ("shouting", "crying", "furious", "pleading", "gasp", "hissing")


def job(i):
    beat, field, text = lines[i]
    if i in SKIP:
        return None
    if i in CAST:
        who, tone, spoken = CAST[i]
    else:
        who, tone, spoken = "narrator", SPECIAL.get(i, BEAT_TONE.get(beat, "quiet, reflective")), None
        if field in ("closed_eyes_lines", "closed_eyes_caption", "closed_lines_done_caption") and i not in SPECIAL:
            tone = "close, intimate, almost a whisper, " + tone
    spoken = spoken or text
    prefix = "bvn" if who == "narrator" else "bvm"
    name = "%s_%s" % (prefix, hashlib.sha1(text.encode("utf-8")).hexdigest()[:12])
    raw = os.path.join(RAW, name + ".mp3")
    if not os.path.exists(raw):
        body = {"text": "[%s] %s" % (tone, spoken), "model_id": "eleven_v3",
                "voice_settings": {"stability": 0.0 if any(w in tone for w in SHOUT) else 0.5, "similarity_boost": 0.75}}
        r = urllib.request.Request("https://api.elevenlabs.io/v1/text-to-speech/%s?output_format=mp3_44100_128" % VOICE[who],
                                   data=json.dumps(body).encode(), headers={"xi-api-key": KEY, "Content-Type": "application/json"}, method="POST")
        with urllib.request.urlopen(r, timeout=120) as resp:
            open(raw, "wb").write(resp.read())
    return (i, who, name, raw)


def process(i, who, name, raw):
    dst = os.path.join(OUT, name + ".ogg")
    warm = "atempo=%s,highpass=f=70,bass=g=2.5:f=180,treble=g=-2.5:f=7000,acompressor=threshold=-20dB:ratio=2.5:attack=8:release=180,apad=pad_dur=0.3" % TEMPO[who]
    m = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-i", raw, "-af", warm + ",loudnorm=I=-19:TP=-1.5:LRA=11:print_format=json", "-f", "null", "-"], capture_output=True, text=True).stderr
    j = json.loads(m[m.rindex("{"):m.rindex("}") + 1])
    ln = "loudnorm=I=-19:TP=-1.5:LRA=11:measured_I=%s:measured_TP=%s:measured_LRA=%s:measured_thresh=%s:offset=%s:linear=true" % (
        j["input_i"], j["input_tp"], j["input_lra"], j["input_thresh"], j["target_offset"])
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", raw, "-af", warm + "," + ln + ",afade=t=in:d=0.01", "-ar", "44100", "-ac", "1", "-c:a", "libvorbis", "-q:a", "5", dst], check=True)
    return dst


with cf.ThreadPoolExecutor(4) as ex:
    results = [r for r in ex.map(job, range(len(lines))) if r]
print("generated", len(results))
manifest = {}
for i, who, name, raw in results:
    process(i, who, name, raw)
    manifest[name] = {"speaker": who, "text": lines[i][2], "beat": lines[i][0]}
json.dump(manifest, open(os.path.join(OUT, "_manifest.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)
print("processed", len(manifest), "->", OUT)
