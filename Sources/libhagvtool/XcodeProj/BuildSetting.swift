import Foundation



/**
Represent a build setting, w/ its paramter.

For example, for the following config: “`MY_CONFIG[sdk=*][arch=*] = $(CFG)_2`”,
the `BuildSetting` would be:
```
   key = "MY_CONFIG"
   value = "$(CFG)_2"
   parameters = [("sdk", "*"), ("arch", "*")]
```

- Important:
No validation is done on the parameters, nor the key, nor anything. */
public struct BuildSetting {
	
	public var key: String
	public var value: Any
	
	public var parameters: [(key: String, value: String)]
	
}
