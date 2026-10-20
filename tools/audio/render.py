# DEV ONLY. Mixes the game's sound recipes (exported by tools/audio/Export.server.lua) from Roblox's own sound
# files into WAVs you can listen to, and measures every stack. Run through tools/audio/render.sh, which runs it with
# Blender (its `aud` module decodes Roblox's .mp3 / .ogg files; numpy does the mixing):
#   blender -b --factory-startup --python tools/audio/render.py -- <export.log> <out dir> [<roblox sounds dir>]
# An approximation of what Roblox plays (same files, regions, PlaybackSpeed, Volume, delays, fades); the
# EqualizerSoundEffect and ReverbSoundEffect are simple stand-ins. Also renders BEFORE versions of the kick and
# a few Kick Sack punches (the recipes this rework replaced), and measures both: length, peak, sub-bass share.
import sys, os, json, glob, wave
import numpy as np
import aud

RATE = 44100
args = sys.argv[sys.argv.index("--") + 1:]
log_path, out_dir = args[0], args[1]
sounds_dir = args[2] if len(args) > 2 else None
if not sounds_dir:
    found = sorted(glob.glob(os.path.join(os.environ.get("LOCALAPPDATA", ""), "Roblox", "Versions", "*", "content", "sounds")))
    sounds_dir = found[-1] if found else None
assert sounds_dir and os.path.isdir(sounds_dir), "Roblox sounds folder not found"
os.makedirs(out_dir, exist_ok=True)

text = open(log_path, encoding="utf-8", errors="replace").read()
chunks = [line.split("AUDIOJSON ", 1)[1] for line in text.splitlines() if line.startswith("AUDIOJSON ")]
bank = json.loads("".join(chunks))
SOURCES = bank["sources"]

_cache = {}
def decode(file_name):
    if file_name not in _cache:
        snd = aud.Sound(os.path.join(sounds_dir, file_name)).resample(RATE, False)
        data = np.asarray(snd.data(), dtype=np.float64)
        _cache[file_name] = data.mean(axis=1) if data.ndim == 2 else data
    return _cache[file_name]

def source_audio(src):
    raw = decode(src["id"].replace("rbxasset://sounds/", ""))
    region = src.get("region")
    if region:
        raw = raw[int(region[0] * RATE):int(region[1] * RATE)]
    return raw

def speed(x, factor):  # PlaybackSpeed: faster = higher + shorter (a resample)
    n = max(1, int(len(x) / factor))
    return np.interp(np.arange(n) * factor, np.arange(len(x)), x)

def eq(x, gains):  # 3-band EqualizerSoundEffect stand-in: low < 400 Hz < mid < 4 kHz < high
    if not gains:
        return x
    spec = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / RATE)
    low, mid, high = (10 ** (g / 20) for g in gains)
    g = np.where(f < 400, low, np.where(f < 4000, mid, high))
    return np.fft.irfft(spec * g, len(x))

def reverb(x):  # ReverbSoundEffect stand-in: decaying noise tail, -6 dB wet
    tail = np.random.default_rng(1).standard_normal(int(1.6 * RATE)) * np.exp(-np.linspace(0, 6, int(1.6 * RATE)))
    wet = np.convolve(x, tail / np.sqrt(np.sum(tail ** 2)))[: len(x) + len(tail)]
    out = np.zeros(len(wet))
    out[: len(x)] += x
    return out + wet * 10 ** (-6 / 20)

def render_layer(layer, gain_mode=True):
    src = SOURCES.get(layer["src"])
    if src is None:
        return np.zeros(1)
    x = source_audio(src)
    if src.get("loop"):
        x = np.tile(x, 2)[: int(RATE * 1.5 * layer["pitch"])] if len(x) else x
    x = speed(x, layer["pitch"])
    x = eq(x, layer.get("eq"))
    vol = (src["gain"] if gain_mode else 1) * layer["volume"]
    env = np.ones(len(x))
    fade = layer.get("fade")
    if fade:
        n_in = max(1, int(fade[0] * RATE))
        env[:n_in] = np.linspace(0, 1, min(n_in, len(env)))[: len(env[:n_in])]
    length = layer.get("length")
    if length:
        end = min(len(x), int(length * RATE))
        out_s = fade[1] if fade else 0.06
        n_out = max(1, int(out_s * RATE))
        start = max(0, end - n_out)
        env[start:end] *= np.linspace(1, 0, end - start)
        env[end:] = 0
    x = x * env * min(vol, 10)
    if layer.get("reverb"):
        x = reverb(x)
    return x

def mix(layers, gain_mode=True, master=0.5):
    parts = []
    for layer in layers:
        x = render_layer(layer, gain_mode)
        parts.append((int((layer.get("delay") or 0) * RATE), x))
    n = max([o + len(x) for o, x in parts] + [1]) + int(0.05 * RATE)
    out = np.zeros(n)
    for o, x in parts:
        out[o:o + len(x)] += x
    return out * master

def measure(x):
    peak = float(np.max(np.abs(x))) + 1e-12
    env = np.abs(x)
    audible = np.where(env > peak * 10 ** (-40 / 20))[0]
    length = (audible[-1] - audible[0]) / RATE if len(audible) else 0
    spec = np.abs(np.fft.rfft(x)) ** 2
    f = np.fft.rfftfreq(len(x), 1 / RATE)
    sub = float(spec[f < 120].sum() / (spec.sum() + 1e-12))
    return {"seconds": round(length, 2), "peak_db": round(20 * np.log10(peak), 1), "sub_bass": round(sub, 2)}

def write(path, x):
    peak = np.max(np.abs(x)) if len(x) else 0
    if peak > 0.99:
        x = x / peak * 0.99  # (only a few spectacular stacks reach this)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes((np.clip(x, -1, 1) * 32767).astype(np.int16).tobytes())

report = []
for stack in bank["stacks"]:
    x = mix(stack["layers"])
    folder = os.path.join(out_dir, stack["group"])
    os.makedirs(folder, exist_ok=True)
    write(os.path.join(folder, stack["name"] + ".wav"), x)
    report.append({"name": stack["name"], "group": stack["group"], "tier": stack["tier"], **measure(x)})

# BEFORE: the recipes this rework replaced (old VFX/Egg kick sound and old VFX/SackSfx punches; no gain levelling)
OLD = {"boom": "impact_explosion_03.mp3", "thud": "action_jump_land.mp3", "whoosh": "action_jump.mp3",
       "tick": "volume_slider.ogg", "step": "action_footsteps_plastic.mp3", "wind": "action_falling.ogg"}
for k, v in OLD.items():
    SOURCES["old_" + k] = {"id": "rbxasset://sounds/" + v, "gain": 1}
def old(src, pitch, volume, delay=0):
    return {"src": "old_" + src, "pitch": pitch, "volume": volume, "delay": delay}
def old_impact(step, theme):
    return [old("thud", 0.95 - step * 0.06, 0.55 + step * 0.03)] + (
        [old("boom", 2.8 - step * 0.25, 0.16 + step * 0.03)] if step >= 2 else []) + theme
BEFORE = {
    "kick": [old("boom", 1.35, 0.32), old("whoosh", 0.7, 0.45), old("thud", 0.8, 0.6)],
    "sack01_impact": old_impact(1, [old("step", 0.7, 0.4)]),
    "sack06_impact": old_impact(2, [old("boom", 3.4, 0.18)]),
    "sack14_impact": old_impact(4, [old("boom", 4.5, 0.22), old("tick", 4, 0.25)]),
    "sack20_impact": old_impact(6, [old("boom", 0.8, 0.45), old("tick", 1.6, 0.3), old("tick", 2, 0.28, 0.05), old("tick", 2.4, 0.26, 0.1)]),
}
AFTER_OF = {"kick": "KickGood", "sack01_impact": "sack01_BurlapSack_impact", "sack06_impact": "sack06_IronPlate_impact",
            "sack14_impact": "sack14_ThunderCell_impact", "sack20_impact": "sack20_RainbowGod_impact"}
stacks_by_name = {s["name"]: s for s in bank["stacks"]}
compare = []
folder = os.path.join(out_dir, "before_after")
os.makedirs(folder, exist_ok=True)
gap = np.zeros(int(0.7 * RATE))
for key, layers in BEFORE.items():
    b = mix(layers, gain_mode=False)
    a = mix(stacks_by_name[AFTER_OF[key]]["layers"])
    write(os.path.join(folder, key + "_1_before.wav"), b)
    write(os.path.join(folder, key + "_2_after.wav"), a)
    write(os.path.join(folder, key + "_before_then_after.wav"), np.concatenate([b, gap, a]))
    compare.append({"sound": key, "before": measure(b), "after": measure(a)})

# the 10 scenarios back to back (0.8 s apart) for one quick listen
scen = [s for s in bank["stacks"] if s["group"] == "scenarios"]
seq = []
for s in sorted(scen, key=lambda s: s["name"]):
    seq += [mix(s["layers"]), np.zeros(int(0.8 * RATE))]
write(os.path.join(out_dir, "scenarios_1_to_10.wav"), np.concatenate(seq))

json.dump({"stacks": report, "before_after": compare}, open(os.path.join(out_dir, "report.json"), "w"), indent=1)
print("RENDERED", len(report), "stacks,", len(compare), "before/after pairs")
for c in compare:
    print("COMPARE", c["sound"], "before", c["before"], "after", c["after"])
for r in report:
    if r["group"] == "scenarios":
        print("SCENARIO", r["name"], "tier", r["tier"], r["seconds"], "s, peak", r["peak_db"], "dB, sub-bass", r["sub_bass"])
