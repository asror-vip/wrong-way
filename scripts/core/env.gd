extends Node

# Env - Wrong Way Central Environment & Configuration Manager
# Parses .env file from project root or falls back to system environment & defaults

var _vars: Dictionary = {}

const DEFAULT_SUPABASE_URL := "https://wcwjobrrwwjfthpflzhg.supabase.co"
const DEFAULT_SUPABASE_ANON_KEY := "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indjd2pvYnJyd3dqZnRocGZsemhnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM0NzIzNTEsImV4cCI6MjEwOTA0ODM1MX0.16SXhNkvVehgIuNhcGH3l9bDS37mkmbGt12h8F2CyoY"

func _init() -> void:
	_load_env_file()

func _load_env_file() -> void:
	var paths := ["res://.env", ".env"]
	for p in paths:
		if FileAccess.file_exists(p):
			var f := FileAccess.open(p, FileAccess.READ)
			if f:
				while not f.eof_reached():
					var line := f.get_line().strip_edges()
					if line.is_empty() or line.begins_with("#"):
						continue
					var eq_idx := line.find("=")
					if eq_idx != -1:
						var k := line.substr(0, eq_idx).strip_edges()
						var v := line.substr(eq_idx + 1).strip_edges()
						if (v.begins_with('"') and v.ends_with('"')) or (v.begins_with("'") and v.ends_with("'")):
							v = v.substr(1, v.length() - 2)
						_vars[k] = v
				f.close()
				break

func get_var(key: String, default_val: String = "") -> String:
	if _vars.has(key) and not str(_vars[key]).is_empty():
		return str(_vars[key])
	var os_val := OS.get_environment(key)
	if not os_val.is_empty():
		return os_val
	return default_val

func get_supabase_url() -> String:
	return get_var("SUPABASE_URL", DEFAULT_SUPABASE_URL)

func get_supabase_anon_key() -> String:
	return get_var("SUPABASE_ANON_KEY", DEFAULT_SUPABASE_ANON_KEY)
