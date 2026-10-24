class_name BricoBrowserStore
extends RefCounted
# Synchronous, per-origin local persistence for small JSON saves. No account/server.
static func read(key: String) -> Dictionary:
	if not OS.has_feature("web"): return {}
	var text = JavaScriptBridge.eval("(()=>{try{return window.localStorage.getItem("+JSON.stringify(key)+")}catch(e){return null}})()", true)
	if not text is String: return {}
	var parser := JSON.new()
	if parser.parse(text) != OK or not parser.data is Dictionary: return {}
	return parser.data
static func write(key: String, data: Dictionary) -> bool:
	var raw := JSON.stringify(data)
	var script := "(()=>{try{const k="+JSON.stringify(key)+",v="+JSON.stringify(raw)+";const old=window.localStorage.getItem(k);if(old!==null)window.localStorage.setItem(k+'.bak',old);window.localStorage.setItem(k,v);return window.localStorage.getItem(k)===v ? 'ok' : 'failed'}catch(e){console.error('Brico local save: '+e.name);return 'failed'}})()"
	return JavaScriptBridge.eval(script, true) == "ok"
static func erase(key: String):
	JavaScriptBridge.eval("(()=>{try{window.localStorage.removeItem("+JSON.stringify(key)+");window.localStorage.removeItem("+JSON.stringify(key+".bak")+")}catch(e){}})()", true)
static func keys(prefix: String) -> Array:
	var raw = JavaScriptBridge.eval("(()=>{try{return JSON.stringify(Object.keys(window.localStorage).filter(k=>k.startsWith("+JSON.stringify(prefix)+")))}catch(e){return '[]'}})()", true)
	var parser := JSON.new()
	if raw is String and parser.parse(raw) == OK and parser.data is Array: return parser.data
	return []
