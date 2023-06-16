//
//  URL+xattr.swift
//  ImageMetadataReader
//
//  Created by Dave Rahardja on 6/16/23.
//

import Foundation

extension URL {
    /// Retrieve a named xattr
    func extendedAttribute(name: String) throws -> Data? {
        let data: Data? = try withUnsafeFileSystemRepresentation { path in
            var retval: Data? = nil
            // Get size of attribute
            let length = getxattr(path, name, nil, 0, 0, 0)
            if (length > 0) {
                // Create buffer
                var buffer = Data(count: length)
                let result = buffer.withUnsafeMutableBytes { bytes in
                    return getxattr(path, name, bytes, length, 0, 0)
                }
                if result == -1 {
                    throw POSIXError(POSIXError.Code(rawValue: errno)!)
                }
                retval = buffer
            }
            return retval
        }
        return data
    }

    func extendedAttributeObject<T: Decodable>(name: String) -> T? {
        var retval: T? = nil
        do {
            if let data = try extendedAttribute(name: name) {
                retval = try PropertyListDecoder().decode(T.self, from: data)
            }
        } catch {}
        return retval
    }
}

