{- Copyright 2022, Ananth <rate-my-pulls@kedi.dev>

   This file is part of Rate My Pulls.

   Rate My Pulls is free software: you can redistribute it and/or modify
   it under the terms of the GNU Affero General Public License as
   published by the Free Software Foundation, version 3 of the License.

   Rate My Pulls is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
   GNU Affero General Public License for more details.

   You should have received a copy of the GNU Affero General Public
   License along with Rate My Pulls.  If not, see
   <https://www.gnu.org/licenses/>.
-}


module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html exposing (Html, a, div, section, text)
import Html.Attributes exposing (class, for, href, id, type_)
import Html.Events exposing (onClick, onInput)
import Http
import Url
import Url.Parser as Parser exposing ((</>), (<?>), parse)



-- MAIN


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }



-- MODEL


type alias Model =
    { page : Page
    , key : Nav.Key
    }


type Page
    = Rate
    | ServerError
    | NotFound



-- INIT


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    ( Model (nextPage url) key
    , Cmd.none
    )


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            ( { model | page = nextPage url }
            , Cmd.none
            )


nextPage : Url.Url -> Page
nextPage url =
    let
        route =
            Parser.oneOf
                [ Parser.map Rate Parser.top
                ]
    in
    parse route url |> Maybe.withDefault NotFound



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Browser.Document Msg
view model =
    let
        footer =
            Html.span []
                [ a [ href "https://git.sr.ht/~ananth/rate-my-pulls" ]
                    [ text "Rate My Pulls Source Code" ]
                , text "Hosted on "
                , a [ href "https://sr.ht" ] [ text "SourceHut!" ]
                ]
    in
    { title = "Rate My Pulls"
    , body =
        [ viewHeader
        , viewPage model.page
        , footer
        ]
    }


viewPage : Page -> Html Msg
viewPage p =
    case p of
        Rate ->
            viewRate

        ServerError ->
            text "Server Error"

        NotFound ->
            text "Not Found"


viewHeader : Html Msg
viewHeader =
    Html.header
        [ id "site-header" ]
        [ Html.h2 [] [ text "Rate My Pulls" ]
        , section
            [ id "user-info" ]
            [ Html.i [ class "nes-octocat animate" ] []
            , div [ class "nes-balloon from-left" ] [ text "Hello!" ]
            ]
        , Html.nav
            [ id "site-nav" ]
            [ a
                [ class "nes-btn is-success"
                , type_ "button"
                , href "/"
                ]
                [ text "Hot" ]
            , a
                [ class "nes-btn is-primary"
                , type_ "button"
                , href "/discover"
                ]
                [ text "Discover" ]
            ]
        ]


viewRate : Html Msg
viewRate =
    Html.main_
        [ class "nes-container with-title" ]
        [ Html.h3
            [ class "title" ]
            [ text "Hot pulls in your area!" ]
        ]
