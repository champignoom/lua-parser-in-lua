local module = {}

local function optstring(s, v)
	if type(s)=='string' then
		return s
	else
		return v
	end
end

local function luaY_parser()
	-- lparser.c:luaY_parser
	--[[
	LClosure *luaY_parser (lua_State *L, ZIO *z, Mbuffer *buff,
			       Dyndata *dyd, const char *name, int firstchar) {
		LexState lexstate;
		FuncState funcstate;
		LClosure *cl = luaF_newLclosure(L, 1);  /* create main closure */
		setclLvalue2s(L, L->top, cl);  /* anchor it (to avoid being collected) */
		luaD_inctop(L);
		lexstate.h = luaH_new(L);  /* create table for scanner */
		sethvalue2s(L, L->top, lexstate.h);  /* anchor it */
		luaD_inctop(L);
		funcstate.f = cl->p = luaF_newproto(L);
		luaC_objbarrier(L, cl, cl->p);
		funcstate.f->source = luaS_new(L, name);  /* create and anchor TString */
		luaC_objbarrier(L, funcstate.f, funcstate.f->source);
		lexstate.buff = buff;
		lexstate.dyd = dyd;
		dyd->actvar.n = dyd->gt.n = dyd->label.n = 0;
		luaX_setinput(L, &lexstate, z, funcstate.f->source, firstchar);
		mainfunc(&lexstate, &funcstate);
		lua_assert(!funcstate.prev && funcstate.nups == 1 && !lexstate.fs);
		/* all scopes should be correctly finished */
		lua_assert(dyd->actvar.n == 0 && dyd->gt.n == 0 && dyd->label.n == 0);
		L->top--;  /* remove scanner's table */
		return cl;  /* closure is on the stack, too */
	}
	--]]
	error("Not Implemented")
end

local function f_parser()
	-- ldo.c:f_parser
	--[[
	static void f_parser (lua_State *L, void *ud) {
	  LClosure *cl;
	  struct SParser *p = cast(struct SParser *, ud);
	  int c = zgetc(p->z);  /* read first character */
	  if (c == LUA_SIGNATURE[0]) {
	    checkmode(L, p->mode, "binary");
	    cl = luaU_undump(L, p->z, p->name);
	  }
	  else {
	    checkmode(L, p->mode, "text");
	    cl = luaY_parser(L, p->z, &p->buff, &p->dyd, p->name, c);
	  }
	  lua_assert(cl->nupvalues == cl->p->sizeupvalues);
	  luaF_initupvals(L, cl);
	}
	--]]
	error("Not Implemented")
end

local function luaD_protectedparser()
	-- ldo.c:luaD_protectedparser
	--[[
	int luaD_protectedparser (lua_State *L, ZIO *z, const char *name,
						const char *mode) {
	  struct SParser p;
	  int status;
	  incnny(L);  /* cannot yield during parsing */
	  p.z = z; p.name = name; p.mode = mode;
	  p.dyd.actvar.arr = NULL; p.dyd.actvar.size = 0;
	  p.dyd.gt.arr = NULL; p.dyd.gt.size = 0;
	  p.dyd.label.arr = NULL; p.dyd.label.size = 0;
	  luaZ_initbuffer(L, &p.buff);
	  status = luaD_pcall(L, f_parser, &p, savestack(L, L->top), L->errfunc);
	  luaZ_freebuffer(L, &p.buff);
	  luaM_freearray(L, p.dyd.actvar.arr, p.dyd.actvar.size);
	  luaM_freearray(L, p.dyd.gt.arr, p.dyd.gt.size);
	  luaM_freearray(L, p.dyd.label.arr, p.dyd.label.size);
	  decnny(L);
	  return status;
	}
	--]]
	error("Not Implemented")
end

local function lua_load(s, chunkname, mode)
	-- lapi.c:lua_load
	--[[
	LUA_API int lua_load (lua_State *L, lua_Reader reader, void *data,
			      const char *chunkname, const char *mode) {
	  ZIO z;
	  int status;
	  lua_lock(L);
	  if (!chunkname) chunkname = "?";
	  luaZ_init(L, &z, reader, data);
	  status = luaD_protectedparser(L, &z, chunkname, mode);
	  if (status == LUA_OK) {  /* no errors? */
	    LClosure *f = clLvalue(s2v(L->top - 1));  /* get newly created function */
	    if (f->nupvalues >= 1) {  /* does it have an upvalue? */
	      /* get global table from registry */
	      Table *reg = hvalue(&G(L)->l_registry);
	      const TValue *gt = luaH_getint(reg, LUA_RIDX_GLOBALS);
	      /* set global table as 1st upvalue of 'f' (may be LUA_ENV) */
	      setobj(L, f->upvals[0]->v, gt);
	      luaC_barrier(L, f->upvals[0], gt);
	    }
	  }
	  lua_unlock(L);
	  return status;
	}
	--]]
	assert(type(chunkname)=='string')
	error("Not Implemented")
end

-- https://www.lua.org/manual/5.4/manual.html#pdf-load
function module.load(...)
	error("Not Implemented")
	--[[ corresponding C code
	static int luaB_load (lua_State *L) {
	  int status;
	  size_t l;
	  const char *s = lua_tolstring(L, 1, &l);
	  const char *mode = luaL_optstring(L, 3, "bt");
	  int env = (!lua_isnone(L, 4) ? 4 : 0);  /* 'env' index or 0 if no 'env' */
	  if (s != NULL) {  /* loading a string? */
	    const char *chunkname = luaL_optstring(L, 2, s);
	    status = luaL_loadbufferx(L, s, l, chunkname, mode);
	  }
	  else {  /* loading from a reader function */
	    const char *chunkname = luaL_optstring(L, 2, "=(load)");
	    luaL_checktype(L, 1, LUA_TFUNCTION);
	    lua_settop(L, RESERVEDSLOT);  /* create reserved slot */
	    status = lua_load(L, generic_reader, NULL, chunkname, mode);
	  }
	  return load_aux(L, status, env);
	}
	--]]
	local chunk, chunkname, mode, env = ...
	mode = optstring(mode, "bt")

	local status
	if type(chunk)=='string' then
		chunkname = optstring(chunkname, s)
		status = luaL_loadbufferx(s, chunkname, mode) -- FIXME
	else
		chunkname = optstring(chunkname, "=(load)")
		assert(type(s) == 'function')
		status = lua_load(generic_reader, nil, chunkname, mode) -- FIXME
	end
	lua_aux --FIXME
end


return module
