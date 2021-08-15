# ``XcodeProj``

Access and edit the contents of `xcodeproj` files.

## Overview

XcodeProj will give you the tools you need to read and update `xcodeproj` files.
This can be useful for instance to lint your `xcodeproj`s during a CI workflow.

## CoreData

- Important: A big part of the model of ``XcodeProj`` is a Core Data model. Which means it
can only be accessed and modified using the dedicated `perform*` methods from
`NSManagedObjectContext`.

## Topics

### Main Objects

- ``XcodeProj/XcodeProj``
- ``PBXProj``
- ``XCConfig``

### Config and Errors

- ``XcodeProjConfig``
- ``XcodeProjError``

### Parsed Build Settings

Build settings are complex in an Xcode project because they are multi-leveled.
These structs give access to all the levels of configuration (including the
`xcconfig` files) in a project. Use ``CombinedBuildSettings`` to create them.

- ``BuildSettingKey``
- ``BuildSetting``
- ``BuildSettings``
- ``CombinedBuildSettings``

### PBXProj Model – Abstract Classes

The `pbxproj` model is a Core Data model.

All elements in the model inherit from ``PBXObject``. Some elements in the model
are abstract and only their subclasses can be instantiated. Here is the list of
all the abstract classes in the PBXProj model.

@Comment {
	Note: The objects created in the CoreData model with code autogeneration set to
	class (as opposed to category or none) might require a clean rebuild before
	being seen by DocC.
}

- ``PBXObject``
- ``PBXBuildPhase``
- ``PBXFileElement``
- ``PBXTarget``

### PBXProj Model – PBXProject

The root element of a `pbxproj` file. Can be accessed from a ``PBXProj``
instance.

- ``PBXProject``

### PBXProj Model – File Elements

These classes all inherit from ``PBXFileElement`` and represent the different 
kind of entries one can find in Xcode’s project navigator.

- ``PBXFileReference``
- ``PBXGroup``
- ``PBXReferenceProxy``
- ``PBXVariantGroup``
- ``XCVersionGroup``

### PBXProj Model – Targets

These classes all inherit from ``PBXTarget`` and represent the different
kind of targets a pbxproj can contain.

- ``PBXAggregateTarget``
- ``PBXLegacyTarget``
- ``PBXNativeTarget``

### PBXProj Model – Target Dependency

- ``PBXTargetDependency``

### PBXProj Model – Build Phases

These classes all inherit from ``PBXBuildPhase`` and represent the different 
kind of build phase Xcode knows.

- ``PBXAppleScriptBuildPhase``
- ``PBXCopyFilesBuildPhase``
- ``PBXFrameworksBuildPhase``
- ``PBXHeadersBuildPhase``
- ``PBXResourcesBuildPhase``
- ``PBXShellScriptBuildPhase``
- ``PBXSourcesBuildPhase``

### PBXProj Model – Build

- ``PBXBuildFile``
- ``PBXBuildRule``

### PBXProj Model – Build Configurations

The objects related to the project’s and the target’s build configuration. 

``PBXProject`` (the root object of a `pbxproj`) and ``PBXTarget`` both contain a
reference to a “configuration list” (an ``XCConfigurationList``), which in turn
has a to-many reference to ``XCBuildConfiguration`` objects.

The ``XCConfigurationList`` is mostly useless and could almost be replaced by a
simple to-many relationship directly to ``XCBuildConfiguration``, however the
``XCConfigurationList`` contains the default configuration name and whether the
default configuration is visible.

- ``XCConfigurationList``
- ``XCBuildConfiguration``

### PBXProj Model – SPM Support

These classes add support for SPM in an Xcode project.

- ``XCRemoteSwiftPackageReference``
- ``XCSwiftPackageProductDependency``

### PBXProj Model – Container

- ``PBXContainerItemProxy``

### PBXProj Model – Other

The only object in the Core Data model not inheriting from ``PBXObject``.

- ``ProjectReference``
