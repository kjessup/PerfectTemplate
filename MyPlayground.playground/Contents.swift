//: Playground - noun: a place where people can play

import Darwin

let path = "~kjessup/"

func resolveTilde(inPath: String) -> String {
	if inPath[inPath.startIndex] == "~" {
		var wexp = wordexp_t()
		wordexp(inPath, &wexp, 0)
		if let resolved = wexp.we_wordv[0], pth = String(validatingUTF8: resolved) {
			return pth
		}
	}
	return inPath
}

resolveTilde(inPath: path)
