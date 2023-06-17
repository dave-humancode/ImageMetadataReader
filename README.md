#  ImageMetadataReader

This archive contains a project that builds an iOS/Mac Catalyst app that
demonstrates how to read xattrs when a user drops a file onto a target.

## Dropped files

Files dropped from Finder (macOS) or the Files app (iOS) are eligible to be
opened-in-place. When they are opened that way, the client can also read the
extended attributes associated with that file. In this example, the Finder
Comments field is read and shown below the image. You can edit these comments
by pressing ⌘I with the file selected in Finder, and entering the comments in
the inspector window.

## Pasted files

On MacOS, files copied from Finder are stored as URLs on the clipboard. When
the file is pasted into the app, Mac Catalyst bridges the clipboard and makes
the file available as though it were dropped onto the view. The method
`paste(itemProviders:)` is the common funnel that processes the file both via
Drop and Paste.

On iOS, files are copied immediately and stored in the clipboard cache. Sadly,
the original file is not accessible when it’s pasted on that platform.

## Miscellaneous

The app has other features, such as providing the ability to copy the contents
of the image using context menus, drags, and the toolbar Share button.

