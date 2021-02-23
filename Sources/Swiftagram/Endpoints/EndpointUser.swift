//
//  EndpointUser.swift
//  Swiftagram
//
//  Created by Stefano Bertagno on 08/03/2020.
//

import Foundation

import ComposableRequest

public extension Endpoint {
    /// A module-like `enum` holding reference to `users` `Endpoint`s. Requires authentication.
    enum User {
        /// The base endpoint.
        private static let base = Endpoint.version1.users.appendingDefaultHeader()

        /// A list of all profiles blocked by the user.
        public static var blocked: Disposable<Wrapper> {
            .init { secret, session in
                Projectables.Deferred {
                    base.blocked_list
                        .header(secret.header)
                        .project(session)
                        .map(\.data)
                        .wrap()
                }
                .observe(on: session.scheduler)
                .eraseToAnyObservable()
            }
        }

        /// A user matching `identifier`'s info.
        /// 
        /// - parameter identifier: A `String` holding reference to a valid user identifier.
        public static func summary(for identifier: String) -> Disposable<Swiftagram.User.Unit> {
            .init { secret, session in
                Projectables.Deferred {
                    base.path(appending: identifier)
                        .info
                        .header(secret.header)
                        .project(session)
                        .map(\.data)
                        .wrap()
                        .map(Swiftagram.User.Unit.init)
                }
                .observe(on: session.scheduler)
                .eraseToAnyObservable()
            }
        }

        /// All user matching `query`.
        ///
        /// - parameter query: A `String` holding reference to a valid user query.
        public static func all(matching query: String) -> Paginated<Swiftagram.User.Collection, RankedPageReference<String, String>?> {
            .init { secret, session, pages in
                // Persist the rank token.
                let rank = pages.offset?.rank ?? String(Int.random(in: 1_000..<10_000))
                // Prepare the actual pager.
                return Projectables.Pager(pages) { _, next, _ in
                    base.search
                        .header(appending: secret.header)
                        .header(appending: rank, forKey: "rank_token")
                        .query(appending: ["q": query, "max_id": next])
                        .project(session)
                        .map(\.data)
                        .wrap()
                        .map(Swiftagram.User.Collection.init)
                }
                .observe(on: session.scheduler)
                .eraseToAnyObservable()
            }
        }
    }
}
