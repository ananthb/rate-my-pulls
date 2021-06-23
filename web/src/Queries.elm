{- Copyright 2020, Ananth Bhaskararaman

   This file is part of Rate My Pulls.

   Foobar is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   Foobar is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with Foobar.  If not, see <https://www.gnu.org/licenses/>.
-}

module Queries exposing
    ( RemoteSearchResult
    , RemoteUserInfo
    , Repo
    , checkAuth
    , fetchUserInfo
    , searchRepos
    )

import GitHub.Enum.SearchType as SearchType
import GitHub.Object exposing (SearchResultItemEdge)
import GitHub.Object.PageInfo as PageInfo
import GitHub.Object.Repository as Repository
import GitHub.Object.SearchResultItemConnection as SearchResultItemConnection
import GitHub.Object.SearchResultItemEdge as SearchResultItemEdge
import GitHub.Object.StargazerConnection as StargazerConnection
import GitHub.Object.User as User
import GitHub.Query as Query
import GitHub.Scalar
import GitHub.Union
import GitHub.Union.SearchResultItem as SearchResultItem
import Graphql.Http
import Graphql.OptionalArgument as OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet, with)
import Http
import RemoteData exposing (RemoteData)


apiUrl =
    "/api"


{-| `GraphqlData` is a convenient type alias for using RemoteData
with Graphql.
-}
type alias QueryData a =
    RemoteData (Graphql.Http.Error a) a


checkAuth : (Result Http.Error () -> msg) -> Cmd msg
checkAuth checked =
    Http.request
        { method = "HEAD"
        , headers = []
        , url = apiUrl
        , body = Http.emptyBody
        , expect = Http.expectWhatever checked
        , timeout = Just 5000
        , tracker = Nothing
        }


type alias RemoteUserInfo =
    QueryData UserInfo


type alias UserInfo =
    { login : String
    , name : Maybe String
    }


fetchUserInfo : (RemoteUserInfo -> msg) -> Cmd msg
fetchUserInfo fetched =
    let
        viewerSelection : SelectionSet UserInfo GitHub.Object.User
        viewerSelection =
            SelectionSet.succeed UserInfo
                |> with User.login
                |> with User.name
    in
    Query.viewer viewerSelection
        |> Graphql.Http.queryRequest apiUrl
        |> Graphql.Http.send (RemoteData.fromResult >> fetched)


type alias SearchResult =
    Paginator (List Repo) String


type alias RemoteSearchResult =
    QueryData SearchResult


type alias Paginator dataType cursorType =
    { data : dataType
    , paginationData : PaginationData cursorType
    }


searchRepos : String -> Maybe String -> Maybe String -> (RemoteSearchResult -> msg) -> Cmd msg
searchRepos term startCursor endCursor searched =
    let
        searchSelection : SelectionSet SearchResult GitHub.Object.SearchResultItemConnection
        searchSelection =
            SelectionSet.succeed Paginator
                |> with searchResultFieldEdges
                |> with (SearchResultItemConnection.pageInfo searchPageInfoSelection)
    in
    Query.search
        (\optionals ->
            { optionals
                | last = Present 5
                , before = OptionalArgument.fromMaybe startCursor
                , after = OptionalArgument.fromMaybe endCursor
            }
        )
        { query = term
        , type_ = SearchType.Repository
        }
        searchSelection
        |> Graphql.Http.queryRequest apiUrl
        |> Graphql.Http.send (RemoteData.fromResult >> searched)


type alias PaginationData cursorType =
    { startCursor : Maybe cursorType
    , endCursor : Maybe cursorType
    , hasPreviousPage : Bool
    , hasNextPage : Bool
    }


searchPageInfoSelection : SelectionSet (PaginationData String) GitHub.Object.PageInfo
searchPageInfoSelection =
    SelectionSet.succeed PaginationData
        |> with PageInfo.startCursor
        |> with PageInfo.endCursor
        |> with PageInfo.hasPreviousPage
        |> with PageInfo.hasNextPage


searchResultFieldEdges : SelectionSet (List Repo) GitHub.Object.SearchResultItemConnection
searchResultFieldEdges =
    SearchResultItemConnection.edges
        (SearchResultItemEdge.node searchResultSelection
            |> SelectionSet.nonNullOrFail
        )
        |> SelectionSet.nonNullOrFail
        |> SelectionSet.nonNullElementsOrFail
        |> SelectionSet.nonNullElementsOrFail


searchResultSelection : SelectionSet (Maybe Repo) GitHub.Union.SearchResultItem
searchResultSelection =
    let
        defaults =
            SearchResultItem.maybeFragments
    in
    SearchResultItem.fragments
        { defaults | onRepository = repositorySelection |> SelectionSet.map Just }


type alias Repo =
    { name : String
    , description : Maybe String
    , createdAt : GitHub.Scalar.DateTime
    , updatedAt : GitHub.Scalar.DateTime
    , stargazers : Int
    }


repositorySelection : SelectionSet Repo GitHub.Object.Repository
repositorySelection =
    SelectionSet.succeed Repo
        |> with Repository.nameWithOwner
        |> with Repository.description
        |> with Repository.createdAt
        |> with Repository.updatedAt
        |> with (Repository.stargazers identity StargazerConnection.totalCount)
