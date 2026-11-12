"""Bundle verified Whisper Tiny int8 assets. Python 3.10+, Windows/Linux/macOS.
No model downloads or HTTP inference are performed by the installed app.
"""
import hashlib
import pathlib
import shutil
import tarfile
import tempfile
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
URL = 'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-whisper-tiny.tar.bz2'
ARCHIVE_SHA256 = 'c46116994e539aa165266d96b325252728429c12535eb9d8b6a2b10f129e66b1'
FILES = {
    'tiny-encoder.int8.onnx': 'd24fb083ae3b1041fc24e97971d60e280c9342201fbb67b0ab428a8b4a51a434',
    'tiny-decoder.int8.onnx': 'd2fece8dd42771f1df975c6c0445770d0c292bf7547c2cae04a6c0cc57540925',
    'tiny-tokens.txt': 'b34b360dbb493e781e479794586d661700670d65564001f23024971d1f2fa126',
}

def digest(path):
    with path.open('rb') as source:
        result = hashlib.sha256()
        for block in iter(lambda: source.read(1024 * 1024), b''):
            result.update(block)
        return result.hexdigest()

def main():
    target = ROOT / 'assets/models/whisper_tiny'
    target.mkdir(parents=True, exist_ok=True)
    if all((target / name).is_file() and digest(target / name) == sha for name, sha in FILES.items()):
        print('Offline model already verified.')
        return
    with tempfile.TemporaryDirectory() as tmp:
        archive = pathlib.Path(tmp) / 'model.tar.bz2'
        with urllib.request.urlopen(URL, timeout=180) as response, archive.open('wb') as output:
            shutil.copyfileobj(response, output)
        if digest(archive) != ARCHIVE_SHA256:
            raise RuntimeError('Model archive checksum mismatch; refusing installation.')
        with tarfile.open(archive, 'r:bz2') as tar:
            for name, sha in FILES.items():
                member = tar.getmember('sherpa-onnx-whisper-tiny/' + name)
                if not member.isfile():
                    raise RuntimeError('Unexpected archive member')
                staged = pathlib.Path(tmp) / name
                with tar.extractfile(member) as source, staged.open('wb') as output:
                    shutil.copyfileobj(source, output)
                if digest(staged) != sha:
                    raise RuntimeError('Model file checksum mismatch: ' + name)
                shutil.copyfile(staged, target / name)
    print('Bundled offline model verified:', sum((target / name).stat().st_size for name in FILES), 'bytes')

if __name__ == '__main__':
    main()
