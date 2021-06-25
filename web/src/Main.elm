{- Copyright 2020, Ananth Bhaskararaman

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
import Queries exposing (RemoteSearchResult, RemoteUserInfo)
import RemoteData exposing (RemoteData(..))
import Result exposing (Result)
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
    , userInfo : RemoteUserInfo
    , searchTerm : Maybe String
    , searchResult : RemoteSearchResult
    }


type Page
    = Hot
    | Discover
    | ServerError
    | NotFound



-- INIT


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    ( Model (nextPage url) key RemoteData.Loading Nothing RemoteData.NotAsked
    , Queries.checkAuth CheckedAuth
    )


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | CheckedAuth (Result Http.Error ())
    | GotUserInfo RemoteUserInfo
    | SearchTermUpdated String
    | Searched SearchPosition
    | GotSearchResult RemoteSearchResult


type SearchPosition
    = Start
    | Forward
    | Backward



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

        CheckedAuth (Ok _) ->
            ( model, Queries.fetchUserInfo GotUserInfo )

        CheckedAuth (Result.Err (Http.BadStatus 401)) ->
            ( model, Nav.load "/auth" )

        CheckedAuth (Result.Err _) ->
            ( { model | page = ServerError }, Cmd.none )

        GotUserInfo info ->
            ( { model | userInfo = info }, Cmd.none )

        SearchTermUpdated term ->
            let
                searchTerm =
                    if term == "" then
                        Nothing

                    else
                        Just term
            in
            ( { model | searchTerm = searchTerm }, Cmd.none )

        Searched position ->
            let
                ( start, end ) =
                    case model.searchResult of
                        Success r ->
                            case position of
                                Start ->
                                    ( Nothing, Nothing )

                                Forward ->
                                    ( Nothing, r.paginationData.endCursor )

                                Backward ->
                                    ( r.paginationData.startCursor, Nothing )

                        _ ->
                            ( Nothing, Nothing )

                searchCmd =
                    case model.searchTerm of
                        Just term ->
                            Queries.searchRepos term start end GotSearchResult

                        Nothing ->
                            Cmd.none
            in
            ( { model | searchResult = Loading }, searchCmd )

        GotSearchResult result ->
            ( { model | searchResult = result }, Cmd.none )


nextPage : Url.Url -> Page
nextPage url =
    let
        route =
            Parser.oneOf
                [ Parser.map Hot Parser.top
                , Parser.map Discover (Parser.s "discover")
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
        page =
            case model.page of
                Hot ->
                    viewHot

                Discover ->
                    viewDiscover model.searchResult

                ServerError ->
                    text "Server Error"

                NotFound ->
                    text "Not Found"

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
        [ viewHeader model.userInfo
        , page
        , footer
        ]
    }


viewHeader : RemoteUserInfo -> Html Msg
viewHeader userInfo =
    let
        info =
            case userInfo of
                NotAsked ->
                    "Do I know you?"

                Loading ->
                    "..."

                Failure _ ->
                    "There was an error getting your info."

                Success i ->
                    "Hi, " ++ i.login ++ "!"
    in
    Html.header
        [ id "site-header" ]
        [ Html.h2 [] [ text "Rate My Pulls" ]
        , section
            [ id "user-info" ]
            [ Html.i [ class "nes-octocat animate" ] []
            , div [ class "nes-balloon from-left" ] [ text info ]
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


viewHot : Html Msg
viewHot =
    Html.main_
        [ class "nes-container with-title" ]
        [ Html.h3
            [ class "title" ]
            [ text "Hot pulls in your area!" ]
        ]


viewDiscover : RemoteSearchResult -> Html Msg
viewDiscover remoteResult =
    let
        repoBadge : Queries.Repo -> Html Msg
        repoBadge repo =
            Html.li [] [ text repo.name ]

        result =
            case remoteResult of
                NotAsked ->
                    text ""

                Loading ->
                    text "loading"

                Failure _ ->
                    text "error"

                Success r ->
                    let
                        prev =
                            if r.paginationData.hasPreviousPage then
                                Html.button
                                    [ class "nes-btn"
                                    , onClick <| Searched Backward
                                    ]
                                    [ text "Previous" ]

                            else
                                text "end"

                        next =
                            if r.paginationData.hasNextPage then
                                Html.button
                                    [ class "nes-btn"
                                    , onClick <| Searched Forward
                                    ]
                                    [ text "Next" ]

                            else
                                text "end"
                    in
                    div []
                        [ Html.ul [ class "nes-list is-disc" ] <| List.map repoBadge r.data
                        , prev
                        , next
                        ]
    in
    section
        [ class "nes-container with-title" ]
        [ Html.h3
            [ class "title" ]
            [ text "Discover repositories" ]
        , div
            [ class "nes-field is-inline" ]
            [ Html.label [ for "search-repos" ] [ text "Search" ]
            , Html.input
                [ class "nes-input"
                , type_ "text"
                , id "search-repos"
                , onInput SearchTermUpdated
                ]
                []
            , Html.button
                [ class "nes-btn is-primary"
                , onClick <| Searched Start
                ]
                [ text "Go" ]
            ]
        , result
        ]
