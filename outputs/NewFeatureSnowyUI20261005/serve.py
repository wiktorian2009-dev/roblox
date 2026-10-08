import functools,json,os,pathlib
from http.server import ThreadingHTTPServer,SimpleHTTPRequestHandler
root=pathlib.Path(__file__).resolve().parent
handler=functools.partial(SimpleHTTPRequestHandler,directory=str(root))
server=ThreadingHTTPServer(("127.0.0.1",0),handler)
(root/"server.json").write_text(json.dumps({"port":server.server_port,"pid":os.getpid(),"root":str(root)}),encoding="utf-8")
server.serve_forever()

