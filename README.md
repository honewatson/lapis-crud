# Lapis Crud

Create basic crud functionality fast.

Creates the following routes for a model called Content.

* POST /api/content.json ( create )
* PUT /api/content.json ( update )
* GET /api/content.json?page=2 ( get paginated list )
* GET /api/content/:id.json ( get by id )
* DELETE /api/content/:id.json ( delete by id )
* POST /api/content/search.json

```moonscript
 
import loggedin_user, admin_user from require "applications.user"

import CrudApplication, assert_user, ModelPlus from require "crud"

class Content extends ModelPlus

admin_user = {"Admin", "Superuser"}
loggedin_user = {"Read", "Admin", "Superuser"}


class extends CrudApplication
 
  assert_user_post: assert_user admin_user
  assert_user_put: assert_user admin_user
  assert_user_delete: assert_user admin_user
  assert_user_search: assert_user loggedin_user
  assert_user_get: assert_user loggedin_user
  model: Content
  per_page: 10
  props: {
    id: "int",
    title: "string",
    content: "string"
  }
  validation_post: {
    { "title", exists: true }
  }
  validation_put: {
    { "id", exists: true }
    { "title", exists: true }
  }
  search: {
    "title",
    "content"
  }

```

