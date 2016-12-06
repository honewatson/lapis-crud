lapis = require "lapis"
import json_params, capture_errors_json, respond_to, yield_error from require "lapis.application"
import assert_valid from require "lapis.validate"
import slugify, to_json, from_json from require "lapis.util"
import Model from require "lapis.db.model"

class ModelPlus extends Model
  @findAll: (...) =>
    first = select 1, ...
    error "#{@table_name!} trying to find with no conditions" if first == nil

    cond = if "table" == type first
      @db.encode_clause (...)
    else
      @db.encode_clause @encode_key(...)

    table_name = @db.escape_identifier @table_name!

    @load_all @db.select "* from #{table_name} where #{cond}"
    

success = () ->
  { message: "Success!" }

not_found = (name) ->
  { message: "#{name} not found!" }

assert_user = (group) -> (user) ->
  assert_valid user, {
    { "group", one_of: group }
  }

assert_user_crud = (user, group) ->
  assert_valid user, {
    { "group", equals: group }
  }

props_builder = (params, props, update=false) ->
  final = nil
  if update
    for k, v in pairs props
      if params[k]
        update[k] = params[k]
    final = update
  else
    final = { k, params[k] for k, v in pairs props when params[k] }
  if props.slug and params[props.slug]
    final.slug = slugify params[props.slug] 
  final

class CrudApplication extends lapis.Application
  group: "admin"
  current_user: group: "read"
  __inherited: (cls) =>
   
    base = cls.__base
    Mod = cls.__base.model
    mod = Mod.__name
    name = mod\lower!
    cls.__base["/#{name}.json"] = respond_to {
      
      POST: capture_errors_json json_params =>
        if base.assert_user_post 
          base.assert_user_post @current_user
        else
          assert_user_crud @current_user, base.group
        if base.validation_post
          assert_valid  @params, base.validation_post
        props = props_builder @params, base.props
        if base.before_post
          props = base.before_post props
        create_mod = ->
          Mod\create props
        ok, nmod = pcall create_mod
        --json: @params
        if type(nmod) == 'string' and string.find(nmod, "duplicate key")
          nmod = {errors: {"#{mod} '#{@params.name}' already exists!"}}
        elseif base.after_post
          base.after_post nmod
        json: nmod

      PUT: capture_errors_json json_params =>
        if base.assert_user_put
          base.assert_user_put @current_user
        else 
          assert_user_crud @current_user, base.group
        if base.validation_put
          assert_valid @params, base.validation_put
        nmod = Mod\find @params.id
        if nmod
          nmod = props_builder @params, base.props, nmod
          if base.before_put
            nmod = base.before_put nmod
          nmod\update [k for k, v in pairs nmod when k != 'id' and base.props[k] ]
          if base.after_put
            nmod = base.after_put nmod
        --json: @params
        else
          nmod = {errors: {"No #{mod} found with id #{@params.id}"}}
        json: nmod
        
      GET: capture_errors_json json_params =>
        if base.assert_user_get_list
          base.assert_user_get_list @current_user
        else 
          assert_user_crud @current_user, base.group
        paginated = Mod\paginated "", per_page: base.per_page or 10
        total_items = paginated\total_items!
        if total_items
          query_string = @req.params_get
          query_string.page = query_string.page or 1
          assert_valid query_string {
            { "page", is_integer: true }
          } 
          result = { count: total_items }
          result.result = paginated\get_page query_string.page
          result = nmod
          unless nmod
            result =  not_found mod
          elseif base.after_get
            result = base.after_get result
          json: result
        else
          json: { count: total_items, results: {}}
    }

    cls.__base["/#{name}/search.json"] = respond_to {
        POST: capture_errors_json json_params =>
          if base.assert_user_search
            base.assert_user_search @current_user
          else 
            assert_user_crud @current_user, base.group
          if base.validation_search
            assert_valid @params, base.validation_search
          local query
          query = { k, @params[k] for k in *base.search when @params[k]}
          if base.before_search
            query = base.before_search query
          nmod = Mod\findAll query
          unless nmod
            nmod = not_found mod
          elseif base.after_search
            nmod  = base.after_search nmod
          json: nmod
    }

    cls.__base["/#{name}/:id.json"] = respond_to {
        GET: capture_errors_json json_params =>
          if base.assert_user_get
            base.assert_user_get @current_user
          else 
            assert_user_crud @current_user, base.group
          nmod = Mod\find @params.id
          result = nmod
          unless nmod
            result =  not_found mod
          elseif base.after_get
            result = base.after_get result
          json: result
        DELETE: capture_errors_json json_params =>
          if base.assert_user_delete
            base.assert_user_delete @current_user
          else 
            assert_user_crud @current_user, base.group
          nmod = Mod\find @params.id
          result = success!
          if nmod
            nmod\delete!
          unless nmod
            result =  not_found mod
          elseif base.after_delete
            result = base.after_delete result
          json: result
    }



{ :CrudApplication, :assert_user, :ModelPlus }
