import json,pathlib,urllib.request,concurrent.futures,hashlib
r=pathlib.Path(__file__).resolve().parents[1] / 'assets/data'
a=[json.loads((r/f'{n}.json').read_text()) for n in range(1,115)]
assert sum(len(s['ayat']) for s in a)==6236
for s in a:
 assert [v['nomorAyat'] for v in s['ayat']]==list(range(1,s['jumlahAyat']+1))
 assert all(v['teksArab'] and v['teksIndonesia'] and len(v['audio'])==6 for v in s['ayat'])
urls=[v for n in (1,55,114) for v in a[n-1]['ayat'][0]['audio'].values()]
def verify(url):
 req=urllib.request.Request(url,headers={'Range':'bytes=0-1023'})
 with urllib.request.urlopen(req,timeout=30) as f:
  b=f.read(1024);assert len(b)>100;assert 'audio' in f.headers.get('Content-Type','')
 return url
with concurrent.futures.ThreadPoolExecutor(max_workers=6) as ex:results=list(ex.map(verify,urls))
report={'quran_source':'https://equran.id/api/v2/surat','juz_source':'https://api.alquran.cloud/v1/meta','prayer_source':'https://api.myquran.com/v2/sholat','downloaded_on':'2026-11-01','surahs':114,'verses':6236,'reciters':6,'audio_samples_verified':results,'sha256':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in r.glob('*.json') if p.name != 'provenance.json'}}
(r/'provenance.json').write_text(json.dumps(report,indent=2))
print('Validated 114 surahs, 6236 verses, 6 audio mappings per verse, 18 real audio HTTP samples')
