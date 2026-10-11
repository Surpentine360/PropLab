"""Compile all sources and test the actual pure model/session code with the Luau CLI."""
from pathlib import Path
import argparse
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--luau-dir', type=Path, default=ROOT / '.tools' / 'luau')
args = parser.parse_args()
suffix = '.exe' if __import__('os').name == 'nt' else ''
compiler = args.luau_dir / ('luau-compile' + suffix)
runtime = args.luau_dir / ('luau' + suffix)
files = sorted((ROOT / 'src').rglob('*.luau'))
for file in files:
    subprocess.run([str(compiler), str(file)], stdout=subprocess.DEVNULL, check=True)
print(f'PASS: {len(files)} Luau source files compile', flush=True)

def read(path):
    return (ROOT / path).read_text(encoding='utf-8')

config = read('src/shared/Config.luau')
model = read('src/shared/Model.luau').replace('local Config = require(script.Parent.Config)', '')
session = '\n'.join(line for line in read('src/server/Session.luau').splitlines()
                    if not line.startswith(('local Shared =', 'local Config =', 'local Model =')))
source = (f'local Config = (function()\n{config}\nend)()\n'
          f'local Model = (function()\n{model}\nend)()\n'
          f'local Session = (function()\n{session}\nend)()\n'
          + read('tests/session.spec.luau'))
with tempfile.TemporaryDirectory(prefix='proplab-tests-') as directory:
    harness = Path(directory) / 'tests.luau'
    harness.write_text(source, encoding='utf-8')
    subprocess.run([str(runtime), str(harness)], check=True)
