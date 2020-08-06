//
//  User.swift
//  Swiftagram
//
//  Created by Stefano Bertagno on 31/07/20.
//

import Foundation

import ComposableRequest

/// A `struct` representing a `User`.
public struct User: ResponseMappable, Codable, CustomDebugStringConvertible {
    /// An `enum` representing an access status.
    public enum Access: Int, Hashable, Codable {
        /// Default.
        case `default`
        /// Private.
        case `private`
        /// Verified.
        case verified
    }
    /// A `struct` representing a profile's `Counter`s.
    public struct Counter: Hashable, Codable {
        /// Posts.
        public var posts: Int
        /// Followers.
        public var followers: Int
        /// Following.
        public var following: Int
        /// Posts in which their tagged in.
        public var tags: Int
        /// Clips.
        public var clips: Int
        /// AR effects.
        public var effects: Int
        /// IGTV.
        public var igtv: Int
    }

    /// The underlying `Response`.
    public var response: () throws -> Response

    /// The identifier.
    public var identifier: String! { self["pk"].string() ?? self["pk"].int().flatMap(String.init) }
    /// The username.
    public var username: String! { self["username"].string() }
    /// The name.
    public var name: String? { self["fullName"].string() }
    /// The biography.
    public var biography: String? { self["biography"].string() }
    /// A lower quality avatar.
    public var thumbnail: URL? { self["profilePicUrl"].url() }
    /// An higher quality avatar.
    public var avatar: URL? {
        self["hdProfilePicVersions"]
            .array()?
            .max(by: {
                ($0.width.double() ?? 0) < ($1.width.double() ?? 0)
                    && ($0.height.double() ?? 0) < ($1.height.double() ?? 0)
            })?["url"]
            .url() ?? self["hdProfilePicUrlInfo"]["url"].url()
    }

    /// The current access status.
    public var access: Access? {
        if self["isPrivate"].bool() == nil && self["isVerified"].bool() == nil {
            return nil
        } else if self["isPrivate"].bool() ?? false {
            return .private
        } else if self["isVerified"].bool() ?? false {
            return .verified
        }
        return .default
    }

    /// The counter.
    public var counter: Counter? {
        guard let posts = self["mediaCount"].int(),
              let followers = self["followerCount"].int(),
              let following = self["followingCount"].int() else { return nil }
        return .init(posts: posts,
                     followers: followers,
                     following: following,
                     tags: self["usertagsCount"].int() ?? 0,
                     clips: self["totalClipsCount"].int() ?? 0,
                     effects: self["totalArEffects"].int() ?? 0,
                     igtv: self["totalIgtvVideos"].int() ?? 0)
    }

    /// The friendship status with the logged in user.
    public var friendship: Friendship? {
        (self["friendship"].dictionary() ?? self["friendshipStatus"].dictionary())
            .flatMap { Friendship(response: Response($0)) }
    }

    /// Init.
    /// - parameter response: A valid `Response`.
    public init(response: @autoclosure @escaping () throws -> Response) {
        self.response = response
    }

    /// The debug description.
    public var debugDescription: String {
        ["User(",
         ["identifier": identifier as Any,
          "username": username as Any,
          "name": name as Any,
          "biography": biography as Any,
          "thumbnail": thumbnail as Any,
          "avatar": avatar as Any,
          "access": access as Any,
          "counter": counter as Any,
          "friendship": friendship as Any]
            .mapValues { String(describing: $0 )}
            .map { "\($0): \($1)" }
            .joined(separator: ", "),
         ")"].joined()
    }
}

/// A `struct` representing a `User` single response.
public struct UserUnit: ResponseMappable, CustomDebugStringConvertible {
    /// The underlying `Response`.
    public var response: () throws -> Response

    /// The venues.
    public var user: User! { User(response: self["user"]) }
    /// The status.
    public var status: String! { self["status"].string() }

    /// Init.
    /// - parameter response: A valid `Response`.
    public init(response: @autoclosure @escaping () throws -> Response) {
        self.response = response
    }

    /// The debug description.
    public var debugDescription: String {
        ["UserUnit(",
         ["user": user as Any,
          "status": status as Any]
            .mapValues { String(describing: $0 )}
            .map { "\($0): \($1)" }
            .joined(separator: ", "),
         ")"].joined()
    }
}

/// A `struct` representing a `User` collection.
public struct UserCollection: ResponseMappable, CustomDebugStringConvertible {
    /// The underlying `Response`.
    public var response: () throws -> Response

    /// The users.
    public var users: [User]! { self["users"].array()?.map { User(response: $0) }}
    /// The status.
    public var status: String! { self["status"].string() }

    /// Init.
    /// - parameter response: A valid `Response`.
    public init(response: @autoclosure @escaping () throws -> Response) {
        self.response = response
    }

    /// The debug description.
    public var debugDescription: String {
        ["UserCollection(",
         ["users": users as Any,
          "status": status as Any]
            .mapValues { String(describing: $0 )}
            .map { "\($0): \($1)" }
            .joined(separator: ", "),
         ")"].joined()
    }
}
