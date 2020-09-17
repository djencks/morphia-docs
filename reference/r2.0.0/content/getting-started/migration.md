+++
date = "2015-03-17T15:36:56Z"
title = "Migrating to 2.0"
[menu.main]
  parent = "Getting Started"
  identifier = "Migrating to 2.0"
  weight = 3
  pre = "<i class='fa'></i>"
+++

These are the major goals of the 2.0 release:
1.  Modernization of the implementation
1.  Clean up and modernization of the API
1.  Attempt to make the API more self-consistent.

This release aims to make the API smaller, lighter, and more fluent.  The pre-2.0 deprecations are being removed and new deprecations 
added to further improve the API and the developer experience.  As such there are a few things to note when upgrading.  This document 
will attempt to document these items as development progresses.  Any early adopters finding missing or unclear items please file a bug.

* **Defaults Changes**

  Default mapping options have been changed for a more modern, configurable feel.  In 1.6, the standard builder for `MapperOptions` was
   [deprecated](https://morphia.dev/1.6.0/javadoc/dev/morphia/mapping/MapperOptions.html#builder()) in favor of the 
   [legacy](https://morphia.dev/1.6.0/javadoc/dev/morphia/mapping/MapperOptions.html#legacy()) method instead.  If you made this change
    nothing should be different when upgrading.  However, if you did not or if you never explicitly configured your `Mapper` then you
     will run in to some migration issues.
  * The default discriminator is now `_t` rather than `className` with a value that is the simple name of the class name.  This is 
  configurable using [MapperOptions.Builder.html#discriminatorKey()](https://morphia.dev/2.0.0/javadoc/dev/morphia/mapping/MapperOptions.Builder.html#discriminatorKey(java.lang.String))
  and [MapperOptions.Builder.html#discriminator()](https://morphia.dev/2.0.0/javadoc/dev/morphia/mapping/MapperOptions.Builder.html#discriminator(dev.morphia.mapping.DiscriminatorFunction)).
  The latter allows you pass in an existing [discriminator function](https://morphia.dev/2.0.0/javadoc/dev/morphia/mapping/DiscriminatorFunction.html) 
  or to supply your own custom function.
  * Collection mapping now defaults to the camel case form of the class's simple name. 
  * `@Entity` now defaults to using discriminator values when saving documents.
* `@Embedded` is now only allowed on the embedded type and not fields using an embedded type.  If you wish to map a specific name to a
 field  rather than using the field name, use `@Property` on that field.
* Morphia's geojson objects have been deprecated.  Any use via the API will be transparently converted to the driver's native types but 
applications should be updated to use those types directly.  Any use of those types as fields on entities will break as there will be no 
codecs defined for those types.

*  Many methods on `Datastore` are being deprecated in favor of more fluent APIs with `Query` as the root entry point.  In most cases, 
much of your code can remain as it is but with a slight rearrangement it can take advantage of the fluent API.  e.g., when performing an 
update operation, this code:

```java
getDs().update(
    getDs().find(SomeEntity.class).field("name").equal("Robert"),
    getAds().createUpdateOperations(SomeEntity.class)
        .removeAll("nicknames", "Shorty"));
```

becomes this:

```java
getDs().find(SomeEntity.class)
    .filter(eq("name", "Robert")
    .update(pullAll("nicknames", "Shorty"))
    .execute();
```
Update operators are defined on [UpdateOperators]({{< apiref "dev/morphia/query/experimental/updates/UpdateOperators" >}}) and generally
 match the "dollar name" as used by the server.  e.g. `UpdateOperators.inc()` is used for the `$inc` operation.

* `Query#find()` is being replaced by `iterator()`.  This is because `Query` now implements the `Iterable` interface and can now be use
 directly in enhanced for loops without the need to call an extra method to get an `Iterator`.  However, should any options need to be
  passed in for executing the query, there is an overload on `iterator()` that takes a `FindOptions` parameter.  If you would rather pull
   all results in to a `List`, there is a `toList()` defined on the `Iterable` returned by `iterator()`.
* Some of the old `update()` methods made certain assumptions with `multi` update being the default.  In keeping with the change of the 
server defaulting to single document updates, Morphia defaults to single document updates as well unless explicitly set to update 
multiple documents.  See the [`update()`](https://docs.mongodb.com/manual/reference/method/db.collection.update/) documentation for details.
* Iterable parameters have been changed to List.  Lists are easier to work with and `List.of()` makes creating them from arrays, e.g., 
trivial
* Lifecycle events on nested types are only called when instances of those embedded types are being persisted.
* Keys are no longer allowed as fields.  Use [`@Reference`]({{< apiref "dev/morphia/annotations/Reference" >}}) or 
[`MorphiaReference`]({{< apiref "dev/morphia/mapping/experimental/MorphiaReference" >}}) instead.
* Polymorphic queries across collections are not currently supported.  That is, if you have entities A and B each mapped to separate
 collections, a query against type A will not automatically look in the collection mapped for B to find your entities. 
* The default option when calling `modify()` is to return the before state of the entity.  This is a change to the default behavior of
 the old, deprecated methods which was to return the new state.  This brings Morphia's behavior inline with the server's.
* Geo queries have been migrated to use the driver defined geospatial types.  All of the Morphia geo types and methods have been deprecated.