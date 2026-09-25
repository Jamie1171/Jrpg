"""Search/download Sketchfab from Actions; credentials never leave the runner."""
import json, os, re, sys, urllib.request, urllib.parse
from pathlib import Path

OUT=Path('sketchfab-output')
class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None

def api(path, token):
    req=urllib.request.Request('https://api.sketchfab.com/v3/'+path,
        headers={'Authorization':'Token '+token,'User-Agent':'Jrpg-asset-import/1.0'})
    with urllib.request.build_opener(NoRedirect()).open(req,timeout=45) as r:
        return json.load(r)

def details(m):
    return {'uid':m['uid'],'name':m.get('name'),'url':m.get('viewerUrl'),
        'creator':m.get('user',{}).get('displayName'),
        'creator_url':m.get('user',{}).get('profileUrl'),
        'license':m.get('license'),'face_count':m.get('faceCount'),
        'vertex_count':m.get('vertexCount'),'downloadable':m.get('isDownloadable')}

def main():
    token=os.environ.get('SKETCHFAB_API_TOKEN','').strip()
    if not token:raise RuntimeError('Missing SKETCHFAB_API_TOKEN repository secret')
    api('me',token) # Validate without printing or saving account information.
    print('Sketchfab authentication successful.')
    OUT.mkdir(exist_ok=True)
    uid=os.environ.get('MODEL_UID','').strip()
    if not uid and os.environ.get('GITHUB_EVENT_NAME')=='push':
        request=Path('integrations/sketchfab/request.json')
        if request.exists():uid=json.loads(request.read_text()).get('model_uid','')
    if uid:
        if not re.fullmatch(r'[0-9a-fA-F]{32}',uid):raise RuntimeError('Model UID must be 32 hexadecimal characters')
        m=api('models/'+uid,token)
        if not m.get('isDownloadable'):raise RuntimeError('Model is not downloadable')
        # Deliberately narrow default: commercial-friendly CC0 / CC BY only.
        slug=(m.get('license') or {}).get('slug','')
        if slug not in ('cc0','by'):raise RuntimeError('Licence needs separate review; automatic import accepts CC0 or CC BY only')
        info=api('models/'+uid+'/download',token)
        item=info.get('glb') or info.get('gltf')
        if not item:raise RuntimeError('No GLB or glTF download supplied')
        url=item['url']
        if urllib.parse.urlparse(url).scheme!='https':raise RuntimeError('Download must use HTTPS')
        # Signed asset URL is used only here, never printed or saved in metadata.
        limit=45*1024*1024
        if item.get('size',0)>limit:raise RuntimeError('Asset exceeds 45 MB limit')
        dest=OUT/('model.glb' if info.get('glb') else 'model.zip')
        try:
            with urllib.request.urlopen(url,timeout=90) as r,dest.open('wb') as f:
                total=0
                while data:=r.read(1024*1024):
                    total+=len(data)
                    if total>limit:raise RuntimeError('Asset exceeds 45 MB limit')
                    f.write(data)
        except Exception:
            dest.unlink(missing_ok=True)
            raise RuntimeError('Asset download failed; no URL or credentials logged') from None
        (OUT/'attribution.json').write_text(json.dumps(details(m),indent=2))
        print('Downloaded model:',uid,'bytes:',total)
    else:
        query=os.environ.get('SEARCH_QUERY','stylized rock').strip()[:160]
        params=urllib.parse.urlencode({'type':'models','q':query,'downloadable':'true','count':12})
        result=api('search?'+params,token)
        models=[details(m) for m in result.get('results',[])]
        (OUT/'search.json').write_text(json.dumps(models,indent=2))
        print('Downloadable candidates:',len(models))
        for m in models:
            print(json.dumps({'uid':m['uid'],'name':m['name'],'url':m['url'],
                'license':(m['license'] or {}).get('slug'),'faces':m['face_count']}))
    summary=os.environ.get('GITHUB_STEP_SUMMARY')
    if summary:
        with open(summary,'a') as f:f.write('Sketchfab authentication passed. Results are in the **sketchfab-assets** workflow artifact.\n')

if __name__=='__main__':
    try:main()
    except Exception as e:
        # Do not print exception strings from networking: they may contain signed URLs.
        print('Sketchfab task failed:',type(e).__name__)
        if isinstance(e,RuntimeError):print(str(e))
        sys.exit(1)
