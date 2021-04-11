import CoreData
import Foundation



public enum XcodeProjError : Error {
	
	case cannotReadFile(URL, Error)
	
	case cannotFindSingleXcodeproj
	
	case unsupportedPBXProj(UnsupportedPBXProjError)
	
	/** `objectID` is `nil` if unknown or not applicable (root, etc.) */
	case pbxProjParseError(PBXProjParseError, objectID: String?)
	case infoPlistParseError(InfoPlistParseError)
	
	/** `objectID` is `nil` if unknown or not applicable (root, etc.) */
	case invalidPBXProjObjectGraph(PBXProjObjectGraphError, objectID: String?)
	
	case internalError(InternalError)
	
	public enum PBXProjParseError : Error {
		
		case plistParseError(Error)
		case deserializedPlistHasInvalidType
		
		case missingProperty(propertyName: String)
		case unexpectedPropertyValueType(propertyName: String, value: Any)
		
		case unknownOrInvalidProjectReference([String: String])
		
		case invalidIntString(propertyName: String, string: String)
		case invalidURLString(propertyName: String, string: String)
		
		case isaNotFoundInModel(String)
		case invalidObjectTypeInDecodedObjects(expectedType: PBXObject.Type)
		case invalidObjectTypeFetchedOrCreated(expectedType: PBXObject.Type)
		case tryingToInstantiateAbstractISA(String, entity: NSEntityDescription)
		
	}
	
	public enum InfoPlistParseError : Error {
		
		case plistParseError(Error)
		case deserializedPlistHasInvalidType
		
	}
	
	public enum PBXProjObjectGraphError : Error {
		
		case missingProperty(propertyName: String)
		case atLeastTwoConfigurationsHaveSameName
		
	}
	
	public enum UnsupportedPBXProjError : Error {
		
		case unknownArchiveVersion(String)
		case unknownObjectVersion(String)
		/** Not sure what a non emtpy “classes” property means in a pbxproj, so we
		throw an error if we get that. */
		case classesPropertyIsNotEmpty([String: Any])
		
		case unknownRootProperties(Set<String>)
		
	}
	
	public enum InternalError : Error {
		
		case modelNotFound
		case cannotLoadModel(Error)
		
		/** Combined settings for a project should have a `nil` target name. */
		case combinedSettingsForProjectWithTargetName
		case combinedSettingsForTargetWithoutTarget
		case combinedSettingsForTargetWithoutTargetName
		
		case managedContextHasNoModel
		case gotMoreThanOneObjectForID(String)
		case unknownObjectTypeDuringSerialization(object: Any)
		case tryingToInstantiateNonPBXObjectEntity(isa: String, entity: NSEntityDescription)
		
	}
	
	#warning("Line below exists just so the project compiles. Must be removed.")
	init(message: String) {
		self = .pbxProjParseError(PBXProjParseError.unexpectedPropertyValueType(propertyName: "", value: ""), objectID: nil)
	}
	
}
