local lapis = require("lapis")
local json_params, capture_errors_json, respond_to, yield_error
do
  local _obj_0 = require("lapis.application")
  json_params, capture_errors_json, respond_to, yield_error = _obj_0.json_params, _obj_0.capture_errors_json, _obj_0.respond_to, _obj_0.yield_error
end
local assert_valid
assert_valid = require("lapis.validate").assert_valid
local slugify, to_json, from_json
do
  local _obj_0 = require("lapis.util")
  slugify, to_json, from_json = _obj_0.slugify, _obj_0.to_json, _obj_0.from_json
end
local Model
Model = require("lapis.db.model").Model
local ModelPlus
do
  local _class_0
  local _parent_0 = Model
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "ModelPlus",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.findAll = function(self, ...)
    local first = select(1, ...)
    if first == nil then
      error(tostring(self:table_name()) .. " trying to find with no conditions")
    end
    local cond
    if "table" == type(first) then
      cond = self.db.encode_clause((...))
    else
      cond = self.db.encode_clause(self:encode_key(...))
    end
    local table_name = self.db.escape_identifier(self:table_name())
    return self:load_all(self.db.select("* from " .. tostring(table_name) .. " where " .. tostring(cond)))
  end
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  ModelPlus = _class_0
end
local success
success = function()
  return {
    message = "Success!"
  }
end
local not_found
not_found = function(name)
  return {
    message = tostring(name) .. " not found!"
  }
end
local assert_user
assert_user = function(group)
  return function(user)
    return assert_valid(user, {
      {
        "group",
        one_of = group
      }
    })
  end
end
local assert_user_crud
assert_user_crud = function(user, group)
  return assert_valid(user, {
    {
      "group",
      equals = group
    }
  })
end
local props_builder
props_builder = function(params, props, update)
  if update == nil then
    update = false
  end
  local final = nil
  if update then
    for k, v in pairs(props) do
      if params[k] then
        update[k] = params[k]
      end
    end
    final = update
  else
    do
      local _tbl_0 = { }
      for k, v in pairs(props) do
        if params[k] then
          _tbl_0[k] = params[k]
        end
      end
      final = _tbl_0
    end
  end
  if props.slug and params[props.slug] then
    final.slug = slugify(params[props.slug])
  end
  return final
end
local CrudApplication
do
  local _class_0
  local _parent_0 = lapis.Application
  local _base_0 = {
    group = "admin",
    current_user = {
      group = "read"
    },
    __inherited = function(self, cls)
      local base = cls.__base
      local Mod = cls.__base.model
      local mod = Mod.__name
      local name = mod:lower()
      cls.__base["/" .. tostring(name) .. ".json"] = respond_to({
        POST = capture_errors_json(json_params(function(self)
          if base.assert_user_post then
            base.assert_user_post(self.current_user)
          else
            assert_user_crud(self.current_user, base.group)
          end
          if base.validation_post then
            assert_valid(self.params, base.validation_post)
          end
          local props = props_builder(self.params, base.props)
          if base.before_post then
            props = base.before_post(props)
          end
          local create_mod
          create_mod = function()
            return Mod:create(props)
          end
          local ok, nmod = pcall(create_mod)
          if type(nmod) == 'string' and string.find(nmod, "duplicate key") then
            nmod = {
              errors = {
                tostring(mod) .. " '" .. tostring(self.params.name) .. "' already exists!"
              }
            }
          elseif base.after_post then
            base.after_post(nmod)
          end
          return {
            json = nmod
          }
        end)),
        PUT = capture_errors_json(json_params(function(self)
          if base.assert_user_put then
            base.assert_user_put(self.current_user)
          else
            assert_user_crud(self.current_user, base.group)
          end
          if base.validation_put then
            assert_valid(self.params, base.validation_put)
          end
          local nmod = Mod:find(self.params.id)
          if nmod then
            nmod = props_builder(self.params, base.props, nmod)
            if base.before_put then
              nmod = base.before_put(nmod)
            end
            nmod:update((function()
              local _accum_0 = { }
              local _len_0 = 1
              for k, v in pairs(nmod) do
                if k ~= 'id' and base.props[k] then
                  _accum_0[_len_0] = k
                  _len_0 = _len_0 + 1
                end
              end
              return _accum_0
            end)())
            if base.after_put then
              nmod = base.after_put(nmod)
            end
          else
            nmod = {
              errors = {
                "No " .. tostring(mod) .. " found with id " .. tostring(self.params.id)
              }
            }
          end
          return {
            json = nmod
          }
        end)),
        GET = capture_errors_json(json_params(function(self)
          if base.assert_user_get_list then
            base.assert_user_get_list(self.current_user)
          else
            assert_user_crud(self.current_user, base.group)
          end
          local paginated = Mod:paginated("", {
            per_page = base.per_page or 10
          })
          local total_items = paginated:total_items()
          if total_items then
            local query_string = self.req.params_get
            query_string.page = query_string.page or 1
            assert_valid(query_string({
              {
                "page",
                is_integer = true
              }
            }))
            local result = {
              count = total_items
            }
            result.result = paginated:get_page(query_string.page)
            result = nmod
            if not (nmod) then
              result = not_found(mod)
            elseif base.after_get then
              result = base.after_get(result)
            end
            return {
              json = result
            }
          else
            return {
              json = {
                count = total_items,
                results = { }
              }
            }
          end
        end))
      })
      cls.__base["/" .. tostring(name) .. "/search.json"] = respond_to({
        POST = capture_errors_json(json_params(function(self)
          if base.assert_user_search then
            base.assert_user_search(self.current_user)
          else
            assert_user_crud(self.current_user, base.group)
          end
          if base.validation_search then
            assert_valid(self.params, base.validation_search)
          end
          local query
          do
            local _tbl_0 = { }
            local _list_0 = base.search
            for _index_0 = 1, #_list_0 do
              local k = _list_0[_index_0]
              if self.params[k] then
                _tbl_0[k] = self.params[k]
              end
            end
            query = _tbl_0
          end
          if base.before_search then
            query = base.before_search(query)
          end
          local nmod = Mod:findAll(query)
          if not (nmod) then
            nmod = not_found(mod)
          elseif base.after_search then
            nmod = base.after_search(nmod)
          end
          return {
            json = nmod
          }
        end))
      })
      cls.__base["/" .. tostring(name) .. "/:id.json"] = respond_to({
        GET = capture_errors_json(json_params(function(self)
          if base.assert_user_get then
            base.assert_user_get(self.current_user)
          else
            assert_user_crud(self.current_user, base.group)
          end
          local nmod = Mod:find(self.params.id)
          local result = nmod
          if not (nmod) then
            result = not_found(mod)
          elseif base.after_get then
            result = base.after_get(result)
          end
          return {
            json = result
          }
        end)),
        DELETE = capture_errors_json(json_params(function(self)
          if base.assert_user_delete then
            base.assert_user_delete(self.current_user)
          else
            assert_user_crud(self.current_user, base.group)
          end
          local nmod = Mod:find(self.params.id)
          local result = success()
          if nmod then
            nmod:delete()
          end
          if not (nmod) then
            result = not_found(mod)
          elseif base.after_delete then
            result = base.after_delete(result)
          end
          return {
            json = result
          }
        end))
      })
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "CrudApplication",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  CrudApplication = _class_0
end
return {
  CrudApplication = CrudApplication,
  assert_user = assert_user,
  ModelPlus = ModelPlus
}
