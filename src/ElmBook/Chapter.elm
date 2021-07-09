module ElmBook.Chapter exposing
    ( chapter, renderComponent, renderComponentList, Chapter
    , withComponent, withComponentList, render, renderWithComponentList
    , withComponentOptions
    , withStatefulComponent, withStatefulComponentList, renderStatefulComponent, renderStatefulComponentList
    )

{-| Chapters are what books are made of. They can be library guides, component examples, design tokens showcases, you name it.

Take a look at the ["Chapters"](https://elm-book-in-elm-book.netlify.app/guides/chapters) guide for a few examples.


# Getting started

Lets start by creating a chapter that displays different variants of a Button component:

    module UI.Button exposing (docs, view)

    import ElmBook.Actions exposing (logAction)
    import ElmBook.Chapter exposing (Chapter, chapter, renderComponents)
    import Html exposing (..)
    import Html.Attributes exposing (..)
    import Html.Events exposing (onClick)

    view :
        { label : String
        , disabled : Bool
        , onClick : msg
        }
        -> Html msg
    view props =
        button
            [ class "px-8 py-3 rounded-md bg-indigo-200"
            , disabled props.disabled
            , onClick props.onClick
            ]
            [ text props.label ]

    docs : Chapter x
    docs =
        let
            props =
                { label = "Click me!"
                , disabled = False
                , onClick = logAction "Clicked button!"
                }
        in
        chapter "Buttons"
            |> renderComponents
                [ ( "Default", view props )
                , ( "Disabled", view { props | disabled = True } )
                ]

**Tip:** Since Elm has amazing [dead code elimination](https://elm-lang.org/news/small-assets-without-the-headache#dead-code-elimination) you don't need to worry about splitting your component examples from your source code. They can live side by side making your development experience much better!

@docs chapter, renderComponent, renderComponentList, Chapter


# Markdown and embedded components

You're not limited to creating these "storybook-like" chapters though. Take a look at the functions below and you will understand how to create richer docs based on markdown and embedded components.

@docs withComponent, withComponentList, render, renderWithComponentList


# Customizing Components

Take a look at the `ElmBook.Component` attributes for more details.

@docs withComponentOptions


# Stateful Chapters

Create chapters with interactive components that can read and update the book's shared state. These functions work exactly like their stateless counterparts with the difference that they take the current state as an argument.

Take a look at the ["Stateful Chapters"](https://elm-book-in-elm-book.netlify.app/guides/stateful-chapters) guide for a more throughout explanation.

@docs withStatefulComponent, withStatefulComponentList, renderStatefulComponent, renderStatefulComponentList

-}

import ElmBook.Internal.Chapter exposing (ChapterBuilder(..), ChapterComponent, ChapterComponentView(..), ChapterCustom(..))
import ElmBook.Internal.Component
import ElmBook.Internal.Helpers exposing (applyAttributes, toSlug)
import ElmBook.Internal.Msg exposing (Msg)
import Html exposing (Html)


{-| Defines a Chapter type. The argument is the shared state this chapter depends on. We can leave it blank (`x`) on stateless chapters. Read the ["Stateful Chapters"](https://elm-book-in-elm-book.netlify.app/guides/stateful-chapters) guide to know more.
-}
type alias Chapter state =
    ElmBook.Internal.Chapter.ChapterCustom state (Html (Msg state))


{-| Creates a chapter with some title.
-}
chapter : String -> ChapterBuilder state html
chapter title =
    ChapterBuilder
        { title = title
        , groupTitle = Nothing
        , url = "/" ++ toSlug title
        , body = "# " ++ title ++ "\n"
        , componentOptions = ElmBook.Internal.Component.defaultOverrides
        , componentList = []
        }


{-|

    chapter "Buttons"
        |> withComponentOptions
            [ ElmBook.Component.background "yellow"
            , ElmBook.Component.hiddenLabel True
            ]
        |> renderComponents
            [ ( "Default", view props )
            , ( "Disabled", view { props | disabled = True } )
            ]

By default, your components will appear inside a card with some padding and a label at the top. You can customize all of that with this function and the attributes available on `ElmBook.Component`.

Please note that component options are "inherited". So your components will inherit from the attributes defined by `ElmBook.withComponentOptions` and they can also be overriden on the component level. Take a look at the `ElmBook.Component` module for more details.

-}
withComponentOptions :
    List ElmBook.Internal.Component.Attribute
    -> ChapterBuilder state html
    -> ChapterBuilder state html
withComponentOptions attributes (ChapterBuilder config) =
    ChapterBuilder
        { config
            | componentOptions =
                applyAttributes attributes config.componentOptions
        }


{-| Adds a component to your chapter. You can display it using markdown.

    inputChapter : Chapter x
    inputChapter =
        chapter "Input"
            |> withComponent (input [] [])
            |> render """

    Take a look at this input:

    <component />

    """

-}
withComponent : html -> ChapterBuilder state html -> ChapterBuilder state html
withComponent html (ChapterBuilder builder) =
    ChapterBuilder
        { builder
            | componentList = fromTuple ( "", html ) :: builder.componentList
        }


{-| Adds multiple components to your chapter. You can display them using markdown.

    buttonsChapter : Chapter x
    buttonsChapter =
        chapter "Buttons"
            |> withComponents
                [ ( "Default", button [] [] )
                , ( "Disabled", button [ disabled True ] [] )
                ]
            |> render """

    A button might be enabled:

    <component with-label="Default" />

    Or disabled:

    <component with-label="Disabled"

    """

-}
withComponentList : List ( String, html ) -> ChapterBuilder state html -> ChapterBuilder state html
withComponentList componentList (ChapterBuilder builder) =
    ChapterBuilder
        { builder
            | componentList =
                List.map fromTuple componentList ++ builder.componentList
        }


{-| Used for chapters with a single stateful component.
-}
withStatefulComponent : (state -> html) -> ChapterBuilder state html -> ChapterBuilder state html
withStatefulComponent view_ (ChapterBuilder builder) =
    ChapterBuilder
        { builder
            | componentList =
                { label = ""
                , view = ChapterComponentViewStateful view_
                }
                    :: builder.componentList
        }


{-| Used for chapters with multiple stateful components.
-}
withStatefulComponentList : List ( String, state -> html ) -> ChapterBuilder state html -> ChapterBuilder state html
withStatefulComponentList componentList (ChapterBuilder builder) =
    ChapterBuilder
        { builder
            | componentList =
                List.map fromTupleStateful componentList ++ builder.componentList
        }


{-| Used to create rich chapters with markdown and embedded components. Take a look at how you would list all buttons of the previous examples in one go:

    buttonsChapter : Chapter x
    buttonsChapter =
        chapter "Buttons"
            |> withComponents
                [ ( "Default", button [] [] )
                , ( "Disabled", button [ disabled True ] [] )
                ]
            |> render """

        Look at all these buttons:

        <component-list />

    """

-}
render : String -> ChapterBuilder state html -> ChapterCustom state html
render body (ChapterBuilder builder) =
    Chapter
        { builder | body = builder.body ++ body }


{-| Render a single component with no markdown content.
-}
renderComponent : html -> ChapterBuilder state html -> ChapterCustom state html
renderComponent component (ChapterBuilder builder) =
    Chapter
        { builder
            | body = builder.body ++ "<component-list />"
            , componentList = fromTuple ( "", component ) :: builder.componentList
        }


{-| Render a list of components with no markdown content.
-}
renderComponentList : List ( String, html ) -> ChapterBuilder state html -> ChapterCustom state html
renderComponentList componentList (ChapterBuilder builder) =
    Chapter
        { builder
            | body = builder.body ++ "<component-list />"
            , componentList =
                List.map fromTuple componentList ++ builder.componentList
        }


{-| Render a single stateful component with no markdown content.
-}
renderStatefulComponent : (state -> html) -> ChapterBuilder state html -> ChapterCustom state html
renderStatefulComponent view_ (ChapterBuilder builder) =
    Chapter
        { builder
            | body = builder.body ++ "<component-list />"
            , componentList =
                { label = ""
                , view = ChapterComponentViewStateful view_
                }
                    :: builder.componentList
        }


{-| Render a list of stateful components with no markdown content.
-}
renderStatefulComponentList : List ( String, state -> html ) -> ChapterBuilder state html -> ChapterCustom state html
renderStatefulComponentList componentList (ChapterBuilder builder) =
    Chapter
        { builder
            | body = builder.body ++ "<component-list />"
            , componentList =
                List.map fromTupleStateful componentList ++ builder.componentList
        }


{-| Helper for creating chapters where all of the text content sits on top and all components at the bottom. It's basically an alias for what you just saw on the example above.

    buttonsChapter : Chapter x
    buttonsChapter =
        chapter "Buttons"
            |> withComponents
                [ ( "Default", button [] [] )
                , ( "Disabled", button [ disabled True ] [] )
                ]
            |> renderWithComponentList
                "Look at all these buttons:"

-}
renderWithComponentList : String -> ChapterBuilder state html -> ChapterCustom state html
renderWithComponentList body (ChapterBuilder builder) =
    Chapter
        { builder | body = builder.body ++ body ++ "\n<component-list />" }



-- Helpers


fromTupleStateful : ( String, state -> html ) -> ChapterComponent state html
fromTupleStateful ( label, view_ ) =
    { label = label, view = ChapterComponentViewStateful view_ }


fromTuple : ( String, html ) -> ChapterComponent state html
fromTuple ( label, view_ ) =
    { label = label, view = ChapterComponentViewStateless view_ }
