# [Categorical algebra](@id categorical_algebra)

## FinSet and FinRel
The following APIs implement FinSet, the category of Finite Sets (actually the skeleton of FinSet). The objects of this category are natural numbers where `n` represents a set with `n` elements. The morphisms are functions between such sets. We use the skeleton of FinSet in order to ensure that all sets are finite and morphisms can be stored using lists of integers. Finite relations are built out of FinSet and can be used to do some relational algebra.

```@autodocs
Modules = [
  CategoricalAlgebra.FinSets,
  CategoricalAlgebra.FinRelations,
  ]
Private = false
```

## Diagrams, Limits, and Colimts

The following modules define diagrams in an arbitrary category and specify limit and colimt cones over said diagrams. Thes constructions enjoy the fullest support for FinSet and are used below to define presheaf categories as C-Sets. The general idea of these functions is that you set up a limit computation by specifying a diagram and asking for a limit or colimit cone, which is returned as a struct containing the apex object and the leg morphisms. This cone structure can be queried using the functions [`apex`](@ref) and [`legs`](@ref). Julia's multiple dispatch feature is heavily used to specialize limit and colimit computations for various diagram shapes like product/coproduct and equalizer/coequalizer. As a consumer of this API, it is highly recommended that you use multiple dispatch to specialize your code on the diagram shape whenever possible.

```@autodocs
Modules = [
  CategoricalAlgebra.FreeDiagrams,
  CategoricalAlgebra.Limits,
  ]
Private = false
```

# Key components of the CSet and ACSet machinery

`FreeSchema` A finite presentation of a category that will be used as the schema of a database in the *algebraic databases* conception of categorical database theory. Functors out of a schema into FinSet are combinatorial structures over the schema. Attributes in a schema allow you to encode numerical (any julia type) into the database. You can find several examples of schemas in `Catlab.Graphs` where they define categorical versions of graph theory.

`CSet/AttributedCSet` is a struct/constructors whose values (tables, indices) are parameterized by a CatDesc/AttrDesc. These are in memory databases over the schema equiped with `ACSetTranformations` as natural transformations that encode relationships between database instances.

`CSetType/AttributedCSetType`provides a function to construct a julia type for ACSet instances, parameterized by CatDesc/AttrDesc. This function constructs the new type at runtime. In order to have the interactive nature of Julia, and to dynamically construct schemas based on runtime values, we need to define new Julia types at runtime. This function converts the schema spec to the corresponding Julia type.

`CatDesc/AttrDesc` the encoding of a schema into a Julia type. These exist because Julia only allows certain kinds of data in the parameter of a dependent type. Thus, we have to serialize a schema into those primitive data types so that we can use them to parameterize the ACSet type over the schema. This is an implementation detail subject to complete overhaul.



```@autodocs
Modules = [
  CategoricalAlgebra.CSets,
  CategoricalAlgebra.StructuredCospans,
]
Private = false
```
